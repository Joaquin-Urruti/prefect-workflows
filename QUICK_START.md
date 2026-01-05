# Quick Start Guide - Prefect Docker

## Quick Start (5 minutes)

### 1. Start all services

```bash
docker compose up -d --build
```

### 2. Verify everything is working

```bash
# Check service status
docker compose ps

# Open web interface
# http://localhost:4200
```

### 3. Create work pool (first time only)

```bash
docker compose exec prefect-server prefect work-pool create local-pool --type process
```

### 4. Deploy your workflows

```bash
# Deploy backup flow (daily at 3 AM)
docker compose exec prefect-worker python scripts/backup_lotes.py

# Deploy KMZ generation (weekly on Monday)
docker compose exec prefect-worker python scripts/generar_kmz.py

# Deploy test flow (every minute)
docker compose exec prefect-worker python scripts/test.py
```

### 5. Verify deployments

Open http://localhost:4200/deployments and verify:
- **Backup Databaler Lotes/backup-lotes-daily-3am** - Daily at 3:00 AM
- **Generar KMZ/generar-kmz-weekly** - Weekly on Monday at 2:00 AM
- **hello-world/hello-world** - Every minute

### 6. Test manual execution

```bash
# From CLI
docker compose exec prefect-server bash
prefect deployment run 'Backup Databaler Lotes/backup-lotes-daily-3am'

# Or from UI: Deployments → backup-lotes-daily-3am → "Run" → "Quick run"
```

---

## Essential Commands

### Docker Compose

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f
docker compose logs -f prefect-worker

# Restart a service
docker compose restart prefect-worker

# Stop everything
docker compose down

# Rebuild after changes
docker compose up -d --build
```

### Execute Scripts

```bash
# Run a flow directly (without scheduling)
python scripts/backup_lotes.py  # Local execution
docker compose exec prefect-worker python scripts/backup_lotes.py  # In container

# Deploy a flow (create scheduled deployment)
docker compose exec prefect-worker python scripts/backup_lotes.py
```

### Prefect CLI

```bash
# Enter server container
docker compose exec prefect-server bash

# View deployments
prefect deployment ls

# View work pools
prefect work-pool ls

# View recent runs
prefect flow-run ls --limit 10

# Execute deployment manually
prefect deployment run 'Backup Databaler Lotes/backup-lotes-daily-3am'

# Pause/resume schedule
prefect deployment pause 'Backup Databaler Lotes/backup-lotes-daily-3am'
prefect deployment resume 'Backup Databaler Lotes/backup-lotes-daily-3am'

# Delete deployment
prefect deployment delete 'Backup Databaler Lotes/backup-lotes-daily-3am'
```

---

## Project Structure

```
prefect-workflows/
├── docker-compose.yml           # Docker services configuration
├── Dockerfile                   # Worker image
├── scripts/
│   ├── backup_lotes.py         # Backup flow (daily 3 AM)
│   ├── generar_kmz.py          # KMZ generation (weekly Monday 2 AM)
│   ├── test.py                 # Test flow (every minute)
│   └── Modules/                # Shared modules
├── outputs/                     # Generated files
└── logs/                        # Prefect logs
```

---

## Create a New Scheduled Flow

### 1. Create your flow in `scripts/my_flow.py`

```python
from prefect import task, flow
from prefect import get_run_logger

@task
def my_task():
    logger = get_run_logger()
    logger.info("Executing task")
    return "result"

@flow(name="My Flow")
def my_flow(parameter: str = "default"):
    logger = get_run_logger()
    logger.info(f"Starting flow with: {parameter}")
    result = my_task()
    return result

if __name__ == "__main__":
    # Deploy with schedule
    my_flow.from_source(
        source="/app/scripts",
        entrypoint="my_flow.py:my_flow",
    ).deploy(
        name="my-flow-daily",
        work_pool_name="local-pool",
        cron="0 9 * * *",  # Daily at 9:00 AM
        parameters={"parameter": "value"},
        tags=["my-tag"],
    )
```

### 2. Deploy the flow

```bash
docker compose exec prefect-worker python scripts/my_flow.py
```

---

## Schedule Examples (Cron)

```python
# Daily at 3:00 AM
cron="0 3 * * *"

# Every hour
cron="0 * * * *"

# Monday to Friday at 9:00 AM
cron="0 9 * * 1-5"

# Every Monday at 8:00 AM
cron="0 8 * * 1"

# First day of month at midnight
cron="0 0 1 * *"

# Every 15 minutes
cron="*/15 * * * *"

# Every 6 hours
cron="0 */6 * * *"
```

**Cron Format:**
```
┌─── minute (0-59)
│ ┌─── hour (0-23)
│ │ ┌─── day of month (1-31)
│ │ │ ┌─── month (1-12)
│ │ │ │ ┌─── day of week (0-6, Sunday=0)
* * * * *
```

Online generator: https://crontab.guru/

---

## Monitoring

### Web Interface
- **URL**: http://localhost:4200
- View flows, deployments, runs, logs

### System Logs

```bash
# Worker logs
docker compose logs -f prefect-worker

# Server logs
docker compose logs -f prefect-server

# View log files
tail -f logs/worker/prefect.log
tail -f logs/server/prefect.log
```

### Check Status

```bash
docker compose exec prefect-server bash

# Recent runs
prefect flow-run ls --limit 20

# Only failed runs
prefect flow-run ls --state-type FAILED

# Run details
prefect flow-run inspect <flow-run-id>
```

---

## Troubleshooting

### Deployment doesn't execute automatically

```bash
# Verify prefect-services is running
docker compose ps prefect-services

# Restart if needed
docker compose restart prefect-services
```

### Worker not executing flows

```bash
# Check worker logs
docker compose logs -f prefect-worker

# Should show: "Worker started! Polling pool 'local-pool'"

# Verify work pool exists
docker compose exec prefect-server prefect work-pool ls
```

### Import errors

```bash
# Verify modules are in container
docker compose exec prefect-worker ls -la scripts/Modules/

# Restart worker after changes
docker compose restart prefect-worker
```

### Reset everything from scratch

```bash
# Stop and remove everything (caution! you lose data)
docker compose down -v

# Remove data directories
rm -rf data/postgres/* data/redis/*

# Start again
docker compose up -d --build

# Recreate work pool
docker compose exec prefect-server prefect work-pool create local-pool --type process
```

---

## Environment Variables

Create `.env` in project root (optional):

```env
PREFECT_POSTGRES_USER=prefect
PREFECT_POSTGRES_PASSWORD=prefect
PREFECT_POSTGRES_DB=prefect
TZ=America/Argentina/Buenos_Aires
```

---

## Resources

- **Complete tutorial**: [TUTORIAL_PREFECT_DOCKER.md](TUTORIAL_PREFECT_DOCKER.md)
- **Prefect Documentation**: https://docs.prefect.io/
- **Cron Generator**: https://crontab.guru/
- **Local UI**: http://localhost:4200
