#!/bin/bash

# Setup cronjobs
printf '%s\n%s\n' "$(printenv)" "$(cat ./crontab)" > ./crontab
cp ./crontab /etc/cron.d/cron-tasks
chmod +x /etc/cron.d/cron-tasks
touch /usr/src/app/logs/cron_update_exchange_rates.log
crontab /etc/cron.d/cron-tasks

# Start cron daemon
cron

# Start api server
./scripts/start.sh
