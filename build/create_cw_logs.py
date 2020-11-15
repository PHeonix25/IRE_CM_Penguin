#!/usr/bin/env python3

import csv
import json
import argparse

parser = argparse.ArgumentParser(description="Create CoverMore Penguin Application CloudWatch Logs agent config file.")
parser.add_argument('-e', '--environment', type=str, help='The environment to run the script in', default='ire-cm-penguin-dev',
    choices=['ire-cm-penguin-dev','ire-cm-penguin-test2','ire-cm-penguin-test3','ire-cm-penguin-staging','ire-cm-penguin-training','ire-cm-penguin-preprod','ire-cm-penguin-prod'])
args = parser.parse_args()

cwConfig = {
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": []
            }
        }
    }
}

with open('./config/logs.csv', 'rt', encoding='utf-8-sig') as LogSource:
    reader = csv.reader(LogSource)
    for row in reader:
        cwConfig['logs']['logs_collected']['files']['collect_list'].append({
            "file_path": row[0],
            "log_group_name": "{instance_id}",
            "log_stream_name": 'customer-penguin-{0}-{1}-logs'.format(args.environment, row[2]),
            "timestamp_format": "%b %d %H:%M:%S"
        })

with open('./src/cw_logs.json', 'w') as writeFile:
    json.dump(cwConfig, writeFile)