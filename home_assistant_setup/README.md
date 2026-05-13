# Home Assistant Setup

This folder contains Docker Compose configuration and deployment scripts for Home Assistant application with PostgreSQL/TimescaleDB backend.

## Overview

This setup provides:
- **Home Assistant Application**: Custom home automation and IoT management application
- **PostgreSQL with TimescaleDB**: Time-series database for storing sensor readings and telemetry
- **Docker Compose**: Orchestration of multi-container environment

The application is designed for high-performance monitoring with configurable workloads, write/read intervals, and data retention policies.

## Prerequisites

- Raspberry Pi with Docker and Docker Compose installed (see `../docker_setup/`)
- Internet connection
- Sufficient disk space (at least 50GB recommended for PostgreSQL)
- Git installed for repository cloning

## Folder Structure

```
home_assistant_setup/
├── docker-compose.yml         # Docker Compose configuration
├── .env                        # Environment variables (created during setup)
├── home_assistant/             # Application source code
│   ├── Dockerfile
│   ├── init.sh
│   ├── deploy_app.sh
│   └── (other app files)
└── README.md
```

## Installation & Startup

### Quick Start

For automated setup with interactive configuration:

```bash
cd home_assistant_setup/home_assistant
chmod +x deploy_app.sh
./deploy_app.sh
```

This script will:
- Clone the Home Assistant repository (if needed)
- Prompt for configuration values
- Generate a random PostgreSQL password
- Create `.env` file with your settings
- Build and start all containers

### Manual Setup

If you prefer manual control:

#### Step 1: Create environment file

```bash
cd home_assistant_setup

# Copy the template or create .env
cat <<EOF > .env
POSTGRES_DATABASE=home_assistant
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
WORKLOAD=HIGH
WRITE_INTERVAL=3
READ_INTERVAL=6
TIMESCALE_RETENTION_HOURS=24
TIMESCALE_COMPRESSION_HOURS=6
EOF
```

#### Step 2: Start services

```bash
docker compose up -d
```

#### Step 3: Verify services are running

```bash
docker compose ps
```

## Verification

### Check services

```bash
# View all containers
docker compose ps

# Check logs
docker compose logs -f

# Check specific service
docker compose logs -f app
docker compose logs -f postgres
```

### Access application

```bash
# Home Assistant Web UI (if available)
# http://<pi_ip>:8000

# Health check endpoint
# http://<pi_ip>:8000/health
```

### Test database connection

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U postgres -d home_assistant

# Then in psql:
\dt                    # List tables
SELECT COUNT(*) FROM pg_tables;  # Count tables
\q                     # Exit
```

## Configuration

### Environment Variables

Edit the `.env` file to configure:

| Variable | Default | Description |
|----------|---------|-------------|
| POSTGRES_DATABASE | home_assistant | Database name |
| POSTGRES_USER | postgres | Database user |
| POSTGRES_PASSWORD | changeme | Database password (change this!) |
| WORKLOAD | HIGH | Workload type (HIGH, MEDIUM, LOW) |
| WRITE_INTERVAL | 3 | Write frequency in seconds |
| READ_INTERVAL | 6 | Read frequency in seconds |
| TIMESCALE_RETENTION_HOURS | 24 | Data retention period in hours |
| TIMESCALE_COMPRESSION_HOURS | 6 | When to compress data in hours |

### Changing Configuration

After updating `.env`:

```bash
# Restart services to apply new config
docker compose restart

# Or rebuild if needed
docker compose down
docker compose up -d --build
```

### Data Retention

TimescaleDB automatically:
1. Retains raw data for `TIMESCALE_RETENTION_HOURS` hours
2. Compresses older data after `TIMESCALE_COMPRESSION_HOURS` hours
3. Deletes data beyond retention period

To modify retention:

```bash
# Edit .env
TIMESCALE_RETENTION_HOURS=720  # 30 days instead of 24 hours

# Restart
docker compose restart app
```

## Service Management

### Start/Stop

```bash
# Start services
docker compose up -d

# Stop services (keeps data)
docker compose down

# Stop and remove all data (WARNING: data loss!)
docker compose down -v
```

### Logs

```bash
# All logs, follow mode
docker compose logs -f

# Application logs only
docker compose logs -f app

# Database logs only
docker compose logs -f postgres

# Last 50 lines of app logs
docker compose logs app --tail=50
```

### Restart

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart app
docker compose restart postgres
```

### Update Application

```bash
# Pull latest changes
docker compose pull

# Rebuild and restart
docker compose up -d --build
```

## Database Management

### Backup PostgreSQL

```bash
# Create backup
docker compose exec postgres pg_dump -U postgres home_assistant > backup.sql

# Backup with compression
docker compose exec postgres pg_dump -U postgres home_assistant | gzip > backup.sql.gz
```

### Restore from backup

```bash
# Restore from SQL file
docker compose exec -T postgres psql -U postgres home_assistant < backup.sql

# Restore from compressed backup
gunzip < backup.sql.gz | docker compose exec -T postgres psql -U postgres home_assistant
```

### Connect to database CLI

```bash
# Start psql prompt
docker compose exec postgres psql -U postgres -d home_assistant

# Common commands:
\dt                    # List all tables
\du                    # List users/roles
SELECT * FROM table_name LIMIT 10;  # Query data
\l                     # List databases
\q                     # Exit
```

### Check disk usage

```bash
# Postgres data size
docker compose exec postgres du -sh /var/lib/postgresql/data

# Application data size
du -sh home_assistant_setup/
```

## Performance Tuning

### High Write/Read Load

```bash
# Reduce intervals
WRITE_INTERVAL=1
READ_INTERVAL=2

# Increase retention
TIMESCALE_RETENTION_HOURS=168  # 1 week

# Compress sooner
TIMESCALE_COMPRESSION_HOURS=2
```

### Low Resource Environment

```bash
# Increase intervals
WRITE_INTERVAL=5
READ_INTERVAL=10

# Reduce retention
TIMESCALE_RETENTION_HOURS=12

# Compress immediately
TIMESCALE_COMPRESSION_HOURS=1
```

### Monitor Resource Usage

```bash
# Check container stats
docker compose stats

# Check disk usage
df -h

# Check memory/CPU
docker compose exec app top -b -n 1
```

## Troubleshooting

### Application won't start

```bash
# Check logs
docker compose logs app

# Check database connectivity
docker compose logs postgres

# Verify .env file exists and is valid
cat .env
```

### Database connection errors

```bash
# Check PostgreSQL is running
docker compose ps postgres

# Test connection manually
docker compose exec postgres psql -U postgres -c "SELECT 1;"

# Check database exists
docker compose exec postgres psql -U postgres -l
```

### High memory/disk usage

```bash
# Check what's using space
du -sh postgres_data/

# Check TimescaleDB compression is working
docker compose exec postgres psql -U postgres -d home_assistant -c "SELECT * FROM _timescaledb_internal.hypertable;"

# Force compression
docker compose exec postgres psql -U postgres -d home_assistant -c "SELECT compress_chunk(chunk) FROM (SELECT chunk FROM _timescaledb_internal.compressed_chunk_stats WHERE hypertable_name='your_table') AS t(chunk);"
```

### Container crashes after deployment

```bash
# View detailed error
docker compose logs --tail=100 app

# Check resource limits
docker compose stats

# Try with reduced workload
WORKLOAD=MEDIUM docker compose up -d
```

### Slow queries/timeouts

```bash
# Increase retention intervals
WRITE_INTERVAL=5
READ_INTERVAL=10

# Restart application
docker compose restart app

# Monitor performance
docker compose exec postgres psql -U postgres -d home_assistant -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

## Deployment Scripts

### deploy_app.sh

Located in `home_assistant/deploy_app.sh`, this script automates full deployment:

```bash
./home_assistant/deploy_app.sh
```

Features:
- Clones repository if needed
- Interactive configuration prompts
- Generates secure random PostgreSQL password
- Creates `.env` file
- Starts services with Docker Compose
- Displays configuration summary

### init.sh

Located in `home_assistant/init.sh`, this script initializes the application:

```bash
./home_assistant/init.sh
```

Runs during Docker build to set up application database and tables.

## Security Considerations

1. **Change default password**: Update `POSTGRES_PASSWORD` in `.env`
2. **Restrict network access**: Only expose necessary ports
3. **Use strong passwords**: Generate secure random passwords for production
4. **Backup regularly**: Automated daily backups recommended
5. **Monitor logs**: Check for errors and unauthorized access attempts

## Next Steps

1. Configure environment variables in `.env`
2. Start services with `docker compose up -d`
3. Monitor logs with `docker compose logs -f`
4. Access application at `http://<pi_ip>:8000`
5. Configure application settings and integrations

## References

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [TimescaleDB Documentation](https://docs.timescale.com/)
- [Application Repository](https://github.com/anji5h/home_assistant)
