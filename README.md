# CoverMore AMS Infrastructure
This repository contains the Infrastructure as Code required to stand up various components of the
CoverMore EMEA Penguin platform.

## Pipeline
This repository is built with the intention of running through a basic pipeline to be linted, and 
checked for insecure patterns. The aws `cfn-lint` and `cfn-nag` libraries are used to ensure correct
formatting and patterns, and the `ams-lint` extension is applied to ensure AMS compatibility. Additionally
the `.yaml` templates are converted to `json` for AMS CFN ingest RFCs.

The end of the pipeline(s) will deposit validated JSON CloudFormation templates into the Penguin Application
infrastructure bucket. 

## Configuration
Configuration files required by this IaC repository can be found in the `config/` directory.

### Logging
Penguin's implementation generates a large amount of logs. Currently CloudWatch Logs will be used to ingest
these streams. The `/build/generate-cw-config.py` script reads the `/config/logs.csv` source to generate
a `/src/cw_logs.json` configuration file. This JSON file will be interpolated into the `/src/penguin-dynamic.json`
template `user_data` section to be piped into a configuration file on the host machines for the CloudWatch Unified
Agent and initialized into it.

