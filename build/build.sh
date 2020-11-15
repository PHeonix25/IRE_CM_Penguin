#!/bin/bash

LOG_FILE="./src/cloudwatch_logs.json"

cat  <<EOM >$LOG_FILE
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
EOM

# Convert logs.csv to json clod-watch log config
LOG_SOURCE=./src/logs.csv
OLDIFS=$IFS
IFS=","
[ ! -f $LOG_SOURCE ] && { echo "$LOG_SOURCE file was not found"; exit 99; }
while read path type group
do
    PARSED_PATH=$(echo $path | jq -aR)
    echo "$PARSED_PATH - $type - $group"
#     cat  <<EOM >$LOG_FILE
#                     {
#                         "file_path": "$PARSED_PATH",
#                         "log_group_name": "{instance_id}",
#                         "log_stream_name": "customer-penguin-$group-logs",
#                         "timestamp_format": "%b %d %H:%M:%S"
#                     }
# EOM
done < $LOG_SOURCE

cat  <<EOM >$LOG_FILE
                ]
            }
        }
    }
}
EOM

# First we lint
# cfn-lint -a ./ams_lint -t ../src/*.yaml
