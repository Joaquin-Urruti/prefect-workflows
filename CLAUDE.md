# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a production-ready Prefect 3.6.9 workflow orchestration platform running on Docker. The system manages automated data pipelines for agricultural data processing, including field data backups, geospatial analysis, and KMZ generation. All workflows run in containerized environments with full data persistence.

## Architecture

**Docker Compose Stack (5 services):**
- `prefect-server`: REST API and web UI (port 4200)
- `prefect-services`: Background services (scheduler, event processing)
- `prefect-worker`: Executes workflows from the work pool (process-based)
- `postgres`: Metadata storage (PostgreSQL 14)
- `redis`: Message broker for real-time communication

**Work Pool Pattern:**
All workflows deploy to the `local-pool` work pool (type: process). The worker polls this pool and executes tasks locally within the container.

**Deployment Pattern:**
Workflows use `.from_source()` deployment with the entrypoint pattern. All scripts are mounted at `/app/scripts` in the container:

```python
my_flow.from_source(
    source="/app/scripts",
    entrypoint="my_script.py:my_flow",
).deploy(
    name="deployment-name",
    work_pool_name="local-pool",
    cron="0 3 * * *",  # Optional schedule
    parameters={"param1": "value1"},
    tags=["tag1", "tag2"]
)
```

## Development Commands

**Start/Stop Environment:**
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View service status
docker compose ps

# View logs (real-time)
docker compose logs -f prefect-worker
docker compose logs -f prefect-server
```

**Build and Deploy:**
```bash
# Rebuild worker after dependency changes
docker compose build --no-cache prefect-worker

# Restart worker only
docker compose up -d prefect-worker

# Deploy a workflow (run the script that contains .deploy())
docker compose exec prefect-worker python scripts/my_workflow.py
```

**Work Pool Management:**
```bash
# Create work pool (one-time setup)
docker compose exec prefect-server prefect work-pool create local-pool --type process

# List work pools
docker compose exec prefect-server prefect work-pool ls
```

**Monitoring and Debugging:**
```bash
# List all deployments
docker compose exec prefect-server prefect deployment ls

# List recent flow runs
docker compose exec prefect-server prefect flow-run ls --limit 20

# Manually trigger a deployment
docker compose exec prefect-server prefect deployment run "flow-name/deployment-name"

# Access worker shell for debugging
docker compose exec prefect-worker bash

# Check worker Python environment
docker compose exec prefect-worker python -c "import prefect; print(prefect.__version__)"
```

**Testing Workflows Locally:**
```bash
# Run flow function directly (without deployment, for testing)
docker compose exec prefect-worker python -c "from scripts.my_workflow import my_flow; my_flow()"
```

## Directory Structure and Output Handling

**Critical Distinction: test_outputs/ vs outputs/**

The codebase uses two separate output directories with fundamentally different behaviors:

- **`test_outputs/`**: Local directory for development/testing. NO symlinks. Files stay in the project directory.
- **`outputs/`**: Production directory with symlinks to OneDrive. Files are written directly to OneDrive via symbolic links.

**How Workflows Choose:**
All workflows accept a `test` parameter that controls output location:
- `test=True` → writes to `test_outputs/` (local)
- `test=False` → writes to `outputs/` (OneDrive via symlinks)

Example from backup_lotes.py:
```python
if test:
    parent_dir = Path("test_outputs")
else:
    parent_dir = Path("outputs")
```

**Setting up Symlinks (Windows Production Environment):**
1. Run `python setup_symlinks.py` on the development machine to configure mappings
2. The script generates `create_symlinks.ps1`
3. Run the PowerShell script as Administrator on Windows to create symlinks
4. See `SYMLINKS_README.md` for complete instructions

**Why This Matters:**
When modifying workflows that write files, always use the `test` parameter pattern. Never hardcode paths - always use the conditional logic to respect test vs production mode.

## Code Patterns and Conventions

**Prefect Logging:**
Always use `get_run_logger()` for logging within tasks and flows:
```python
from prefect import task, get_run_logger

@task
def my_task():
    logger = get_run_logger()
    logger.info("Message appears in Prefect UI")
    # Never use print() - logs won't show in UI
```

**Task Retry Pattern:**
Critical tasks (API calls, file operations) should have retry logic:
```python
@task(name="Fetch data", retries=3, retry_delay_seconds=30)
def fetch_data():
    # API call or other potentially failing operation
    pass
```

**Module Path Handling:**
Some workflows use custom module imports from `Modules/`. Pattern at the top of scripts:
```python
import sys
from pathlib import Path

module_path = Path("C:/Users/Espartina/Documents").as_posix()
if module_path not in sys.path:
    sys.path.append(module_path)
```

This is for Windows production compatibility. When modifying workflows, preserve this pattern.

**Environment Variables:**
Sensitive configuration is in `.env` (gitignored). Use `.env.example` as template. The docker-compose.yml uses fallback defaults:
```yaml
POSTGRES_PASSWORD: ${PREFECT_POSTGRES_PASSWORD:-prefect}
```

## Dependencies

**Python 3.13** is the base runtime. Dependencies are managed with `uv` (fast pip replacement).

**Adding Dependencies:**
1. Add to `pyproject.toml` under `dependencies = [...]`
2. Rebuild worker: `docker compose build --no-cache prefect-worker`
3. Restart: `docker compose up -d prefect-worker`

**Key Dependencies:**
- `prefect>=3.6.9` - Workflow orchestration
- `geopandas>=1.1.2` - Geospatial data processing
- `pandas>=2.3.3` - Data manipulation
- `requests>=2.32.5` - HTTP client
- Custom module: `Modules/databaler_base_portal_api_util.py` - API utilities for fetching agricultural data

## Dockerfile Multi-Stage Build

The Dockerfile uses a multi-stage build with GDAL base image:
- **Stage 1 (builder)**: Installs uv, builds dependencies with `uv sync --frozen --no-dev`
- **Stage 2 (runtime)**: Copies only the built `.venv` from builder, no dev tools

This optimizes image size while including GDAL/geospatial libraries. The virtual environment is activated via `PATH="/app/.venv/bin:$PATH"`.

**When modifying:**
- Add system dependencies in Stage 2 (runtime) if needed for production
- Build tools only go in Stage 1 (builder)

## Scheduling and Cron

**Timezone:** All containers use `TZ=America/Argentina/Buenos_Aires`

**Cron Syntax Examples:**
- `"0 3 * * *"` - Daily at 3:00 AM
- `"*/15 * * * *"` - Every 15 minutes
- `"0 9 * * 1-5"` - Weekdays at 9:00 AM
- `"* * * * *"` - Every minute (testing only)

**Interval-Based Alternative:**
```python
from datetime import timedelta
my_flow.deploy(interval=timedelta(hours=2), ...)
```

## Common Workflows

**backup_lotes.py**: Main production workflow that fetches agricultural field data from Databaler API and saves to multiple output directories (timestamped backups, sustainability folder, cultivos/muestreos directories). Runs daily at 3 AM.

**Modules Directory**: Contains reusable utilities:
- `databaler_base_portal_api_util.py` - API client for fetching field, management zone, marker, and zone data
- `h3_functions.py` - H3 hexagon grid utilities
- `decorators.py` - Custom decorators
- Various geospatial processing utilities

## Web UI Access

**Local:** http://localhost:4200
**Inside containers:** http://prefect-server:4200/api

The UI shows:
- Dashboard with flow run statistics
- Deployments and their schedules
- Flow run history with logs
- Work pool status
- Real-time task execution

## Data Persistence

**Persistent Volumes:**
- `./data/postgres/` - PostgreSQL database files
- `./data/redis/` - Redis snapshots
- `./logs/` - All application logs (server, services, worker)
- `./outputs/` - Production workflow outputs (symlinked to OneDrive on Windows)
- `./test_outputs/` - Test workflow outputs (local only)

**Backup Strategy:**
```bash
# Stop services, create backup, restart
docker compose down
tar -czf backup-$(date +%Y%m%d).tar.gz data/ logs/ outputs/
docker compose up -d
```

## Troubleshooting

**Worker not executing flows:**
- Check worker is running: `docker compose ps prefect-worker`
- Check worker logs: `docker compose logs -f prefect-worker`
- Verify deployment: `docker compose exec prefect-server prefect deployment ls`
- Ensure work pool exists: `docker compose exec prefect-server prefect work-pool ls`

**Import errors in workflows:**
- Check scripts are mounted: `docker compose exec prefect-worker ls /app/scripts`
- Verify dependencies installed: `docker compose exec prefect-worker pip list`
- Check module path configuration at top of script

**Permission errors writing files:**
- Check output directory exists: `mkdir -p outputs test_outputs`
- Fix permissions: `chmod -R 777 outputs test_outputs`

**Database connection issues:**
- Check postgres health: `docker compose ps postgres`
- Verify environment variables: `docker compose exec prefect-server env | grep POSTGRES`
- Check connection string in docker-compose.yml

**Changes to pyproject.toml not taking effect:**
- Must rebuild worker: `docker compose build --no-cache prefect-worker`
- Then restart: `docker compose up -d prefect-worker`

## Security Notes

- `.env` file is gitignored and contains database credentials
- Always copy `.env.example` to `.env` and set strong passwords for production
- Database password default is `prefect` (change in production)
- The system uses environment-based configuration with fallback defaults in docker-compose.yml

## Related Documentation

- `README.md` - Complete user documentation
- `QUICK_START.md` - 5-minute setup guide
- `SYMLINKS_README.md` - Detailed symlink configuration for Windows
- `TUTORIAL_PREFECT_DOCKER.md` - Complete Docker tutorial
- `deploy.md` - Deployment guide
- `prefect-user-guide-en.md` / `prefect-user-guide-sp.md` - Comprehensive user guides
