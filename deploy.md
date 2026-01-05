---
title: "Prefect Deployment Guide on Docker"
author: "Joaquín Urruti"
date: "2026-01-04"
format:
  typst:
    toc: true
    toc-depth: 3
    mainfont: "Helvetica Neue"
    monofont: "Menlo"
---


# Deployment Guide - Prefect Workflows

This guide will walk you through the step-by-step process of deploying your Prefect infrastructure with Docker.

## Prerequisites

Before starting, make sure you have installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** (optional, for version control)

Verify the versions:

```bash
docker --version
docker compose version
```

## Data Persistence Structure

The configuration is designed to persist all important data on your local file system:

```
prefect-workflows/
├── data/
│   ├── postgres/     # PostgreSQL database (created automatically)
│   └── redis/        # Redis data (created automatically)
├── logs/
│   ├── server/       # Prefect server logs (created automatically)
│   ├── services/     # Prefect services logs (created automatically)
│   └── worker/       # Worker logs (created automatically)
├── outputs/          # Your task outputs (you must create it)
└── scripts/          # Your Python workflows
```

## Step 1: Environment Preparation

### 1.1 Create Required Directories

Create the outputs directory (the others will be created automatically):

```bash
mkdir -p outputs
```

### 1.2 Configure Environment Variables

Copy the environment template and customize it for your deployment:

```bash
# Copy the template file
cp .env.example .env

# Edit the file with your preferred editor
nano .env
```

Update the password in `.env`:

```env
# PostgreSQL Configuration
PREFECT_POSTGRES_USER=prefect
PREFECT_POSTGRES_PASSWORD=your_secure_random_password_here
PREFECT_POSTGRES_DB=prefect

# Timezone
TZ=America/Argentina/Buenos_Aires
```

> 💡 **Tip**: Generate a strong password with: `openssl rand -base64 32`

**Security notes:**
- ✅ The `.env` file is already in `.gitignore` and will NOT be committed
- ✅ The `.env.example` template is safe to commit (contains placeholders only)
- ⚠️ For production, always use strong, unique passwords
- ⚠️ Without a `.env` file, weak default values will be used (development only)

## Step 2: First Installation (Initial Deployment)

### 2.1 Build the Images

Build the worker image that contains your dependencies:

```bash
docker compose build --no-cache prefect-worker
```

This process:
- Downloads the base Prefect image with Python 3.13
- Installs `uv` for dependency management
- Installs all dependencies defined in `pyproject.toml`
- Copies your Python scripts
- Configures directories and permissions

### 2.2 Start the Services

Start all services in the background:

```bash
docker compose up -d
```

### 2.3 Verify Service Status

Verify that all containers are running:

```bash
docker compose ps
```

You should see 5 services:
- `prefect-postgres` (healthy)
- `prefect-redis` (healthy)
- `prefect-server` (healthy)
- `prefect-services` (running)
- `prefect-worker` (running)

### 2.4 Check the Logs

Review the logs to ensure everything started correctly:

```bash
# View logs from all services
docker compose logs

# View logs from a specific service
docker compose logs prefect-server
docker compose logs prefect-worker

# Follow logs in real time
docker compose logs -f prefect-worker
```

## Step 3: Verify UI Access

### 3.1 Access Prefect UI

Open your browser and visit:

```
http://localhost:4200
```

**Important:** Make sure to use the complete URL with the port `:4200`

You should see the Prefect UI dashboard. If you see an error "Can't connect to Server API", the configuration has already been fixed in docker-compose.yml with the `PREFECT_UI_API_URL` environment variable.

## Step 4: Initial Prefect Configuration

### 4.1 Create the Work Pool

The worker needs a work pool to execute tasks. Create it by running:

```bash
docker compose exec prefect-server prefect work-pool create local-pool --type process
```

### 4.2 Verify Work Pool Creation

```bash
docker compose exec prefect-server prefect work-pool ls
```

## Step 5: Deploy Your Workflows

### 5.1 Verify Your Scripts

Make sure your workflows are in the `scripts/` folder:

```bash
ls -la scripts/
```

### 5.2 Deploy a Workflow from the Container

Execute the deployment from inside the worker container:

```bash
docker compose exec prefect-worker python scripts/test.py
```

This command will run the `test.py` script that contains the deployment configuration with:
- Deployment name
- Work pool
- Schedule (cron)
- Tags

### 5.3 Verify the Deployment in the UI

Go to Prefect UI and:
1. Navigate to "Deployments"
2. You should see your "hello-world" deployment
3. Verify the configured schedule

## Step 6: Persistent Data Management

### 6.1 Verify Data Persistence

All this data persists on your local disk:

```bash
# View PostgreSQL data
ls -lh data/postgres/

# View Redis data
ls -lh data/redis/

# View Prefect logs
ls -lh logs/server/
ls -lh logs/worker/

# View your task outputs
ls -lh outputs/
```

### 6.2 Data Backup

To backup all your data:

```bash
# Stop services
docker compose down

# Create backup
tar -czf prefect-backup-$(date +%Y%m%d).tar.gz data/ logs/ outputs/

# Restart services
docker compose up -d
```

### 6.3 Restore from Backup

```bash
# Stop services
docker compose down

# Clean current data (CAUTION!)
rm -rf data/ logs/ outputs/

# Extract backup
tar -xzf prefect-backup-YYYYMMDD.tar.gz

# Restart services
docker compose up -d
```

## Step 7: Updates and Maintenance

### 7.1 Update Your Scripts

When you modify your scripts in the `scripts/` folder:

```bash
# Changes are reflected automatically thanks to mounted volumes
# You don't need to rebuild the image

# If you modified dependencies in pyproject.toml, rebuild:
docker compose build prefect-worker
docker compose up -d prefect-worker
```

### 7.2 Update Prefect Version

To update to a new version of Prefect:

```bash
# 1. Edit docker-compose.yml and Dockerfile
#    Change: prefecthq/prefect:3-python3.13
#    To: prefecthq/prefect:X-python3.13 (new version)

# 2. Rebuild images
docker compose build --no-cache

# 3. Stop current services
docker compose down

# 4. Start with new versions
docker compose up -d
```

### 7.3 View Resource Usage

```bash
# View CPU, memory, network usage
docker stats

# View volume disk usage
docker system df -v
```

### 7.4 Clean Old Logs

Docker logs are automatically rotated (maximum 10MB per file, 3 files). For Prefect logs:

```bash
# Clean old logs (older than 30 days)
find logs/ -name "*.log" -mtime +30 -delete
```

## Step 8: Troubleshooting

### 8.1 Services Won't Start

```bash
# View detailed logs
docker compose logs -f

# Verify ports are not in use
netstat -an | grep 4200
netstat -an | grep 5432

# Restart from scratch
docker compose down -v
docker compose up -d
```

### 8.2 Worker Can't Connect to Server

```bash
# Verify connectivity
docker compose exec prefect-worker curl http://prefect-server:4200/api/health

# Verify environment variables
docker compose exec prefect-worker env | grep PREFECT
```

### 8.3 UI Shows "Can't connect to Server API"

If you see this error in the browser:

```bash
# Stop services
docker compose down

# Verify docker-compose.yml has this environment variable in prefect-server:
PREFECT_UI_API_URL: http://localhost:4200/api

# Restart services
docker compose up -d

# Access the UI with the complete URL including port
http://localhost:4200
```

### 8.4 Output Permission Issues

```bash
# Grant full permissions to outputs folder
chmod -R 777 outputs/

# Or from the container
docker compose exec prefect-worker chmod -R 777 /app/outputs
```

### 8.5 PostgreSQL Authentication Error

If you see `password authentication failed for user`:

```bash
# Stop services
docker compose down

# Delete postgres data (YOU WILL LOSE YOUR DATA!)
rm -rf data/postgres/

# Restart (new DB will be created with credentials from .env)
docker compose up -d
```

### 8.6 Corrupted Database

```bash
# Stop services
docker compose down

# Delete postgres data (YOU WILL LOSE YOUR DATA!)
rm -rf data/postgres/

# Restart (new DB will be created)
docker compose up -d
```

## Step 9: Useful Commands

### Container Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart prefect-worker

# View logs in real time
docker compose logs -f prefect-worker

# Execute command in a container
docker compose exec prefect-worker bash
```

### Prefect Management

```bash
# List work pools
docker compose exec prefect-server prefect work-pool ls

# List deployments
docker compose exec prefect-server prefect deployment ls

# View flow status
docker compose exec prefect-server prefect flow-run ls

# Run a flow manually
docker compose exec prefect-worker python scripts/test.py
```

### Cleanup

```bash
# Stop and remove containers, networks (keeps volumes)
docker compose down

# Stop and remove EVERYTHING including volumes (CAUTION!)
docker compose down -v

# Clean unused images
docker image prune -a

# Clean entire Docker system
docker system prune -a --volumes
```

## Deployment Flow Summary

```mermaid
graph TD
    A[Clone Repository] --> B[Create outputs directory]
    B --> C[Configure .env optional]
    C --> D[docker compose build]
    D --> E[docker compose up -d]
    E --> F[Create work pool]
    F --> G[Deploy workflows]
    G --> H[Verify in UI http://localhost:4200]
    H --> I[Monitor logs and outputs]
```

## Next Steps

Once deployment is complete:

1. Read the `README.md` file to learn how to use Prefect
2. Develop your own workflows in the `scripts/` folder
3. Configure notifications and alerts in the Prefect UI
4. Explore blocks and variables in Prefect for advanced configuration

## Support

If you encounter issues:
1. Check the logs: `docker compose logs -f`
2. Review the official documentation: https://docs.prefect.io
3. Check the health checks: `docker compose ps`
