# Análisis de videos de YouTube en tendencia

Este repositorio analiza los videos que aparecieron en la lista Trending de YouTube en Estados Unidos. Combina los datos tabulares diarios de videos (`USvideos.csv`) con el catálogo de categorías semiestructurado (`US_category_id.json`) para estudiar categorías, vistas, interacciones, fechas de publicación y tiempo hasta aparecer en Trending.

El objetivo es encontrar patrones útiles para orientar hipótesis de contenido y experimentos. El dataset solo incluye videos que llegaron a Trending; por sí solo no permite explicar causalidad, estimar el éxito de cualquier publicación ni calcular el retorno financiero de un patrocinio.

## Contenido del repositorio

- [`notebooks/youtube_trend_analize.ipynb`](notebooks/youtube_trend_analize.ipynb): preparación, análisis exploratorio, clustering y modelos.
- [`queries/`](queries/): consultas SQL para validación, consolidación y análisis de los datos.
- [`utils/kaggle_utils.py`](utils/kaggle_utils.py): descarga de los archivos del dataset mediante KaggleHub.
- [`utils/postgres_utils.py`](utils/postgres_utils.py): lectura y escritura en PostgreSQL mediante `psql`.
- [`setup_local_postgres.sh`](setup_local_postgres.sh): inicio o creación de un clúster local, la base y las tablas requeridas.
- [`env.conf`](env.conf): plantilla con los nombres de las variables de configuración, sin valores.
- [`presentacion_youtube_trending.pdf`](presentacion_youtube_trending.pdf): presentación final.

## Requisitos

- Python 3.10 o superior.
- PostgreSQL local y el cliente de línea de comandos `psql`.
- En Ubuntu/Debian, los utilitarios de administración de clúster PostgreSQL (`pg_lsclusters`, `pg_ctlcluster` y, si no hay un clúster, `pg_createcluster`).
- Acceso a internet para descargar el dataset con KaggleHub.

Instala el entorno de Python desde la raíz del repositorio:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
```

Esto instala las dependencias definidas en `pyproject.toml`, incluidas las bibliotecas de análisis y modelado.

## PostgreSQL local

En Ubuntu/Debian, ejecuta el script desde la raíz:

```bash
./setup_local_postgres.sh
```

El script inicia el clúster existente que escucha en el puerto configurado. Si no hay clústeres instalados pero sí una versión de PostgreSQL, crea uno. Luego crea la base `pragma`, el esquema `test` y las tablas `us_category_id`, `us_videos` y `us_videos_daily` si todavía no existen. Es seguro volverlo a ejecutar: no elimina datos existentes. El script no instala PostgreSQL ni crea roles o contraseñas; puede solicitar permisos de administrador para iniciar o crear el clúster.

Por defecto, el script usa el socket local `/var/run/postgresql` y el puerto `5432`. Si el clúster existente usa otro puerto, indícalo al ejecutarlo, por ejemplo:

```bash
LOCAL_PGPORT=5433 ./setup_local_postgres.sh
```

Si `PGUSER` está definido y el rol ya existe, el script le concede conexión a `pragma`, uso del esquema `test` y permisos de lectura/escritura en las tablas. No cambia contraseñas ni crea el rol si falta.

## Variables de entorno

`utils/postgres_utils.py` lee un archivo `.env` ubicado en la raíz y requiere estas variables:

| Variable | Propósito | Ejemplo |
|---|---|---|
| `PGHOST` | Host o socket al que se conecta el cliente Python. | `localhost` |
| `PGPORT` | Puerto de PostgreSQL. | `5432` |
| `PGDATABASE` | Base de datos. | `pragma` |
| `PGSCHEMA` | Esquema de trabajo. | `test` |
| `PGUSER` | Rol de PostgreSQL ya creado. | `mi_usuario` |
| `PGPASSWORD` | Contraseña de ese rol. | Completar localmente |

`env.conf` solo documenta los nombres y **no** es leído automáticamente por el código. Si aún no tienes `.env`, puedes copiar la plantilla y completar sus valores:

```bash
cp env.conf .env
```

Si `.env` ya existe, edítalo sin sobrescribirlo. No guardes contraseñas reales en `env.conf` ni en archivos versionados; `.env` está excluido por `.gitignore`. El rol indicado en `PGUSER` debe existir y poder autenticarse desde el host y puerto configurados.

El script también acepta `LOCAL_PGHOST`, `LOCAL_PGPORT` y `POSTGRES_VERSION`:

- `LOCAL_PGHOST`: socket local; por defecto `/var/run/postgresql`.
- `LOCAL_PGPORT`: puerto del clúster local; por defecto usa `PGPORT` si está exportado, o `5432`.
- `POSTGRES_VERSION`: versión a usar al crear un clúster nuevo; por defecto elige la versión instalada más reciente.

## Ejecutar el notebook

1. Ejecuta el script de PostgreSQL y completa `.env`.
2. Activa `.venv` y abre el notebook en VS Code, seleccionando `.venv` como kernel. Si usas JupyterLab, inícialo desde la carpeta `notebooks/` para que las rutas relativas del notebook resuelvan correctamente.
3. Ejecuta las celdas en orden. La primera descarga los archivos de EE. UU. desde KaggleHub.
4. En la celda de carga de datos, habilita las dos llamadas `write_to_postgres(...)` comentadas para cargar `us_videos` y `us_category_id` antes de ejecutar las consultas SQL por primera vez.
5. Continúa con las celdas de limpieza y análisis. La celda de consolidación vacía y vuelve a cargar `test.us_videos_daily`; al ejecutarla, se reemplaza el contenido derivado previo de esa tabla.

Para iniciar JupyterLab manualmente (si está instalado):

```bash
cd notebooks
jupyter lab youtube_trend_analize.ipynb
```

## Flujo de análisis

El notebook valida y consolida los registros diarios antes de calcular resúmenes por video, categoría, canal y fecha. Las consultas SQL se encuentran en `queries/`; Python se utiliza para las visualizaciones y los modelos. El clustering describe perfiles exploratorios. El clasificador estima si un video que ya llegó a Trending apareció allí en dos días o menos; no predice vistas o likes ni la probabilidad de entrar a Trending.
