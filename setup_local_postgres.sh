#!/usr/bin/env bash
set -Eeuo pipefail

DB_NAME="pragma"
DB_SCHEMA="test"
LOCAL_PGHOST="${LOCAL_PGHOST:-/var/run/postgresql}"
LOCAL_PGPORT="${LOCAL_PGPORT:-${PGPORT:-5432}}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "No se encontró '$1'. Instala PostgreSQL para Ubuntu/Debian y vuelve a intentar."
}

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    require_command sudo
    sudo -A "$@"
  fi
}

as_postgres() {
  if (( EUID == 0 )); then
    runuser -u postgres -- "$@"
  else
    require_command sudo
    sudo -A -u postgres "$@"
  fi
}

for command_name in psql pg_isready pg_lsclusters pg_ctlcluster; do
  require_command "$command_name"
done

cluster_info="$(
  pg_lsclusters --no-header |
    awk -v port="$LOCAL_PGPORT" '$3 == port { print $1, $2, $4; exit }'
)"

if [[ -z "$cluster_info" ]]; then
  cluster_count="$(pg_lsclusters --no-header | awk 'NF { count++ } END { print count + 0 }')"
  if (( cluster_count > 0 )); then
    fail "Hay clusters PostgreSQL, pero ninguno usa el puerto $LOCAL_PGPORT. Define LOCAL_PGPORT para usar uno existente."
  fi

  require_command pg_createcluster
  mapfile -t installed_versions < <(
    for binary in /usr/lib/postgresql/*/bin/postgres; do
      [[ -x "$binary" ]] && basename "$(dirname "$(dirname "$binary")")"
    done | sort -V
  )
  ((${#installed_versions[@]} > 0)) || fail "No se encontró una versión instalada de PostgreSQL."
  version="${POSTGRES_VERSION:-${installed_versions[${#installed_versions[@]}-1]}}"
  printf 'Creando el cluster local PostgreSQL %s en el puerto %s...\n' "$version" "$LOCAL_PGPORT"
  as_root pg_createcluster --start --port="$LOCAL_PGPORT" "$version" main
else
  read -r version cluster_name cluster_status <<< "$cluster_info"
  if [[ "$cluster_status" != "online" ]]; then
    printf 'Iniciando el cluster PostgreSQL %s/%s...\n' "$version" "$cluster_name"
    as_root pg_ctlcluster "$version" "$cluster_name" start
  fi
fi

pg_isready -q -h "$LOCAL_PGHOST" -p "$LOCAL_PGPORT" ||
  fail "PostgreSQL no responde en $LOCAL_PGHOST:$LOCAL_PGPORT."

psql_args=(-X -v ON_ERROR_STOP=1 -h "$LOCAL_PGHOST" -p "$LOCAL_PGPORT" -U postgres)
database_exists="$(
  as_postgres psql "${psql_args[@]}" -d postgres -Atqc \
    "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'"
)"

if [[ "$database_exists" != "1" ]]; then
  printf 'Creando la base de datos %s...\n' "$DB_NAME"
  as_postgres psql "${psql_args[@]}" -d postgres -c "CREATE DATABASE $DB_NAME"
else
  printf 'La base de datos %s ya existe; se conservarán sus datos.\n' "$DB_NAME"
fi

as_postgres psql "${psql_args[@]}" -d "$DB_NAME" <<'SQL'
CREATE SCHEMA IF NOT EXISTS test;

CREATE TABLE IF NOT EXISTS test.us_category_id (
    id int4 NOT NULL,
    title text NOT NULL,
    assignable bool NOT NULL,
    CONSTRAINT us_category_id_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS test.us_videos (
    video_id text NULL,
    trending_date date NULL,
    title text NULL,
    channel_title text NULL,
    category_id int4 NULL,
    publish_time timestamp NULL,
    tags text NULL,
    "views" int8 NULL,
    likes int8 NULL,
    dislikes int8 NULL,
    comment_count int8 NULL,
    thumbnail_link text NULL,
    comments_disabled bool NULL,
    ratings_disabled bool NULL,
    video_error_or_removed bool NULL,
    description text NULL
);

CREATE TABLE IF NOT EXISTS test.us_videos_daily (
    video_id text NULL,
    trending_date date NULL,
    title text NULL,
    channel_title text NULL,
    category_id int4 NULL,
    publish_time timestamp NULL,
    tags text NULL,
    "views" int8 NULL,
    likes int8 NULL,
    dislikes int8 NULL,
    comment_count int8 NULL,
    thumbnail_link text NULL,
    comments_disabled bool NULL,
    ratings_disabled bool NULL,
    video_error_or_removed bool NULL,
    description text NULL
);
SQL

app_db_user="${APP_DB_USER:-${PGUSER:-}}"
env_file="$PROJECT_DIR/.env"
if [[ -z "$app_db_user" && -f "$env_file" ]]; then
  app_db_user="$(
    awk -F= '
      /^[[:space:]]*#/ { next }
      {
        key = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        if (key == "PGUSER") {
          value = substr($0, index($0, "=") + 1)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
          print value
          exit
        }
      }
    ' "$env_file"
  )"
  app_db_user="${app_db_user%\"}"
  app_db_user="${app_db_user#\"}"
  app_db_user="${app_db_user%\'}"
  app_db_user="${app_db_user#\'}"
fi

if [[ -n "$app_db_user" && "$app_db_user" != "postgres" ]]; then
  role_exists="$(
    as_postgres psql "${psql_args[@]}" -d postgres -At \
      -v app_user="$app_db_user" \
      -c "SELECT 1 FROM pg_roles WHERE rolname = :'app_user'"
  )"
  if [[ "$role_exists" == "1" ]]; then
    as_postgres psql "${psql_args[@]}" -d "$DB_NAME" \
      -v app_user="$app_db_user" <<'SQL'
GRANT CONNECT ON DATABASE pragma TO :"app_user";
GRANT USAGE ON SCHEMA test TO :"app_user";
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA test TO :"app_user";
SQL
  else
    printf 'Aviso: el rol configurado en PGUSER no existe; no se cambiaron roles ni contraseñas.\n' >&2
  fi
fi

printf 'Listo: servidor local activo; %s.%s contiene las tres tablas solicitadas.\n' \
  "$DB_NAME" "$DB_SCHEMA"
