#!/bin/bash

# Setup Params
CW_CONFIG="./src/cw_logs.json"
LOG_TARGETS="./config/logs.csv"

# Create Penguin CW Logs Agent config file
python3 ./build/generate-cw-config.py -o $CW_CONFIG -f $LOG_TARGETS

# PShell Interpolation
# Sed in cloudwatch unified agent config into PShell Script
# sed Pshell script into Dynamic Template

# Lint
# cfn-lint -a ./ams_lint -t ./src/*.yaml

# Nag
# cfn-nag ./src/*.yaml

# Transform yaml -> json

# Validate Json

# S3 copy to target

