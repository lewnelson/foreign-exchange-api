#!/bin/bash
for path in logs/archive/*.log; do
  [ -e "$path" ] || continue
  filename=$(basename $path)
  date=$(sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/' <<< $filename)
  if [ ! -z "$date" ]; then
    start_ts=$(date -j -u -f "%F" "$date" "+%s")
    end_ts=$(date -j -u -f "%F" "$(date +%F)" "+%s")
    diff=$(( $end_ts - $start_ts ))
    if [ $((( $diff > 604800 ))) == 1 ]; then
      rm $path
    fi
  fi
done
