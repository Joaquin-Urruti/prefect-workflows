FROM prefecthq/prefect:3-python3.13

WORKDIR /app

# Instalar uv para gestión de dependencias
RUN pip install --no-cache-dir uv

# Copiar archivos de dependencias primero (mejor cache de Docker)
COPY pyproject.toml uv.lock ./

# Sincronizar dependencias desde el lockfile
RUN uv sync --frozen --no-dev

# Crear directorios necesarios para outputs y logs
RUN mkdir -p /app/outputs /app/scripts /root/.prefect/logs

# Copiar el código fuente
COPY scripts/ ./scripts/

# Asegurar permisos correctos
RUN chmod -R 755 /app/scripts && \
    chmod -R 777 /app/outputs

# Variables de entorno
ENV PYTHONUNBUFFERED=1 \
    PREFECT_LOGGING_LEVEL=INFO

# El comando se define en docker-compose.yml
# pero podemos definir un healthcheck aquí también
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD python -c "import prefect; print('OK')" || exit 1