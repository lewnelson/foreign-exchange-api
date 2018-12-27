#!/bin/bash
mkdir -p logs/archive
for path in logs/*.log; do
  [ -e "$path" ] || continue
  filename=$(basename $path)
  archived_file="logs/archive/${filename%.*}_$(date +%F).log"
  if [ ! -e "$archived_file" ]; then
    cp $path $archived_file
  else
    cat $path >> $archived_file
  fi

  echo "" > $path
done
