#!/bin/bash
touch logs/api_server.log
ruby src/processes/api_server.rb &> logs/api_server.log
