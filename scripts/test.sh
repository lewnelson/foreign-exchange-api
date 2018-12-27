#!/bin/bash
if [ -z "$1" ]; then
  PATTERN="src/*_spec.rb,src/**/*_spec.rb"
else
  PATTERN="$1"
fi

rspec -r ./src/test_bootstrap.rb -P $PATTERN
