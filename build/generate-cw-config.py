#!/usr/bin/env python3

import csv
import json
import argparse

parser = argparse.ArgumentParser(description="Create CoverMore Penguin Application CloudWatch Logs agent config file.")
parser.add_argument('-e', '--environment', type=str, help='The environment to run the script in', default='ire-cm-penguin-dev',
    choices=['ire-cm-penguin-dev','ire-cm-penguin-test2','ire-cm-penguin-test3','ire-cm-penguin-staging','ire-cm-penguin-training','ire-cm-penguin-preprod','ire-cm-penguin-prod'])
parser.add_argument('-f', '--file', help="CloudWatch target csv file to read from.", default="./config/logs.csv")
parser.add_argument('-o', '--output', help="CloudWatch target json config file to output.", default="./src/cw_logs.json")
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

with open(args.file, 'rt', encoding='utf-8-sig') as LogSource:
    reader = csv.reader(LogSource)
    for row in reader:
        cwConfig['logs']['logs_collected']['files']['collect_list'].append({
            "file_path": row[0],
            "log_group_name": "{instance_id}",
            "log_stream_name": 'customer-penguin-{0}-{1}-logs'.format('{PenguinEnvironment}', row[2]),
            "timestamp_format": "%b %d %H:%M:%S"
        })

with open(args.output, 'w') as writeFile:
    json.dump(cwConfig, writeFile)