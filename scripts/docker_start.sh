#!/bin/bash
printf '%s\n%s\n' "$(printenv)" "$(cat ./crontab)" > /etc/cron.d/cron-tasks
cron
./scripts/start.sh
