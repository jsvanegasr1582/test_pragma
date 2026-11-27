from __future__ import annotations

import json
import os
import subprocess
import tempfile
from io import StringIO
from pathlib import Path

import pandas as pd


def _config() -> dict[str, str]:
    """Lee y valida la configuración PostgreSQL del archivo .env."""
    env_file = Path(__file__).resolve().parent.parent / ".env"
    if not env_file.is_file():
        raise FileNotFoundError(f"No se encontró {env_file}")

    config = {}
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
            value = value[1:-1]
        config[key.strip()] = value

    required = ("PGHOST", "PGPORT", "PGDATABASE", "PGSCHEMA", "PGUSER", "PGPASSWORD")
    missing = [key for key in required if not config.get(key)]
    if missing:
        raise ValueError(f"Faltan variables en .env: {', '.join(missing)}")
    return config


def _psql(
    config: dict[str, str],
    *args: str,
    cwd: Path | None = None,
) -> str:
    """Ejecuta psql con la configuración indicada y devuelve su salida."""
    env = os.environ.copy()
    env["PGPASSWORD"] = config["PGPASSWORD"]
    result = subprocess.run(
        [
            "psql", "-X", "-v", "ON_ERROR_STOP=1",
            "-h", config["PGHOST"], "-p", config["PGPORT"],
            "-U", config["PGUSER"], "-d", config["PGDATABASE"],
            *args,
        ],
        env=env,
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout


def _quote(name: str) -> str:
    """Escapa un identificador SQL para usarlo en una consulta."""
    return '"' + name.replace('"', '""') + '"'


def _load_query(query: str | Path) -> str:
    if isinstance(query, Path):
        query = query.read_text(encoding="utf-8")
    elif Path(query).suffix.lower() == ".sql":
        query = Path(query).read_text(encoding="utf-8")

    query = query.strip().removesuffix(";")
    if not query:
        raise ValueError("query no puede estar vacía.")
    return query


def write_to_postgres(table_name: str, dataframe: pd.DataFrame) -> int:
    """Carga las filas del DataFrame en una tabla PostgreSQL existente."""
    config = _config()
    if dataframe.empty:
        return 0

    columns = tuple(dataframe.columns)
    if not columns or any(not isinstance(column, str) for column in columns):
        raise ValueError("El DataFrame debe tener nombres de columna de texto.")

    rows = dataframe.copy()
    for column in columns:
        rows[column] = rows[column].map(
            lambda value: json.dumps(value, ensure_ascii=False)
            if isinstance(value, (dict, list, tuple))
            else value
        )

    table = f"{_quote(config['PGSCHEMA'])}.{_quote(table_name)}"
    column_list = ", ".join(_quote(column) for column in columns)
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        rows.to_csv(temp_path / "data.csv", index=False, na_rep=r"\N")
        copy = (
            f"\\copy {table} ({column_list}) FROM 'data.csv' "
            r"WITH (FORMAT csv, HEADER true, NULL '\N')"
        )
        script = temp_path / "load.sql"
        script.write_text(f"BEGIN;\n{copy}\nCOMMIT;\n", encoding="utf-8")
        _psql(config, "-f", str(script), cwd=temp_path)

    return len(dataframe)


def read_from_postgres(query: str | Path) -> pd.DataFrame:
    """Ejecuta una consulta SQL o el archivo .sql indicado y devuelve un DataFrame."""
    query = _load_query(query)

    config = _config()
    csv_data = _psql(
        config,
        "-q",
        "-c",
        f"COPY ({query}) TO STDOUT WITH (FORMAT CSV, HEADER TRUE)",
    )
    return pd.read_csv(StringIO(csv_data))


def execute_query(query: str | Path) -> None:
    """Ejecuta una consulta SQL o un archivo .sql sin devolver resultados."""
    query = _load_query(query)
    config = _config()
    _psql(config, "-q", "-c", query)
