#!/bin/bash
set -e

echo ">>> Updating TimescaleDB compression policy..."
read -p "Enter compression threshold in hours [6]: " COMPRESSION_HOURS
COMPRESSION_HOURS="${COMPRESSION_HOURS:-6}"

echo ">>> Applying compression after ${COMPRESSION_HOURS} hours..."

docker exec -i home-assistant-postgres psql \
  -U postgres \
  -d home_assistant <<EOSQL

-- Remove existing compression policy (if any)
DO \$\$
DECLARE
    v_job_id INTEGER;
BEGIN
    SELECT job_id INTO v_job_id
    FROM timescaledb_information.jobs
    WHERE proc_name = 'policy_compression'
      AND hypertable_name = 'environment';

    IF v_job_id IS NOT NULL THEN
        PERFORM remove_job(v_job_id);
    END IF;
END
\$\$;

-- Add compression policy: compress chunks older than ${COMPRESSION_HOURS} hours
SELECT add_compression_policy(
    'environment',
    INTERVAL '${COMPRESSION_HOURS} hours'
);

EOSQL

echo ">>> Compression policy updated successfully."