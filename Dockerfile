# ==========================================
# Stage 1: Build stage (con todas las tools)
# ==========================================
FROM ghcr.io/osgeo/gdal:ubuntu-small-3.9.0 AS builder

WORKDIR /app

# Install Python 3.13 and build tools
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    python3-pip \
    gcc \
    g++ \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.13 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.13 1

# Install uv and prefect
RUN python3.13 -m pip install --no-cache-dir uv prefect

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Build virtual environment with all dependencies
RUN uv sync --frozen --no-dev

# ==========================================
# Stage 2: Runtime stage (solo lo necesario)
# ==========================================
FROM ghcr.io/osgeo/gdal:ubuntu-small-3.9.0

WORKDIR /app

# Install ONLY runtime Python 3.13 (no dev tools)
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.13 \
    python3.13-venv \
    && apt-get purge -y software-properties-common \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.13 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.13 1

# Copy only the built virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Activar .venv agregándolo al PATH
ENV PATH="/app/.venv/bin:$PATH"

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

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD python -c "import prefect; print('OK')" || exit 1
