#!/bin/bash
set -e

echo ">>> Updating TimescaleDB retention policy..."
read -p "Enter retention threshold in hours [24]: " RETENTION_HOURS
RETENTION_HOURS="${RETENTION_HOURS:-24}"

echo ">>> Applying retention policy after ${RETENTION_HOURS} hours..."

docker exec -i home-assistant-postgres psql \
  -U postgres \
  -d home_assistant <<EOSQL

-- Remove existing retention policy (if any)
DO \$\$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM timescaledb_information.jobs
        WHERE proc_name = 'policy_retention'
          AND hypertable_name = 'environment'
    ) THEN
        PERFORM remove_retention_policy('environment');
    END IF;
END
\$\$;

-- Add retention policy: compress chunks older than ${RETENTION_HOURS} hours
SELECT add_retention_policy(
    'environment',
    INTERVAL '${RETENTION_HOURS} hours'
);

EOSQL

echo ">>> retention policy updated successfully."