FROM prefecthq/prefect:3-python3.13

WORKDIR /app

# Instalar uv
RUN pip install uv

# Copiar archivos de dependencias primero (mejor cache de Docker)
COPY pyproject.toml uv.lock ./

# Sincronizar dependencias desde el lockfile
RUN uv sync --frozen --no-dev

# Copiar el código fuente
COPY scripts/ ./scripts/