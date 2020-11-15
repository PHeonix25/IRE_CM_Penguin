#!/bin/bash

# Setup Params
CW_CONFIG="./src/cw_logs.json"
LOG_TARGETS="./config/logs.csv"
PENGUIN_ENVIRONMENT='ire-cm-penguin-dev'

# Create Penguin CW Logs Agent config file
python3 ./build/generate-cw-config.py -o $CW_CONFIG -f $LOG_TARGETS -e $PENGUIN_ENVIRONMENT

# Lint
# cfn-lint -a ./ams_lint -t ./src/*.yaml

# Nag
# cfn-nag ./src/*.yaml

# Transform yaml -> json

# Validate Json

# S3 copy to target

