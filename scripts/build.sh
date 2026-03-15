#!/usr/bin/env bash

echo "Build started at: $(date '+%Y-%m-%d %H:%M:%S')"
start_time=$(date +%s)

sudo -u www-data bash -c 'id; cd /satisfy && /satisfy/bin/satis build --skip-errors --no-ansi --verbose'

end_time=$(date +%s)
echo "Build ended at: $(date '+%Y-%m-%d %H:%M:%S')"
duration=$((end_time - start_time))
echo "Duration: $duration seconds"
