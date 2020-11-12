# CoverMore AMS Infrastructure
This repository contains the Infrastructure as Code required to stand up various components of the
CoverMore EMEA platform.

## Pipeline
This repository is built with the intention of running through a basic pipeline to be linted, and 
checked for insecure patterns. The aws `cfn-lint` and `cfn-nag` libraries are used to ensure correct
formatting and patterns, and the `ams-lint` extension is applied to ensure AMS compatibility. Additionally
the `.yaml` templates are converted to `json` for AMS CFN ingest RFCs.

The end of the pipeline(s) will deposit a

## Applications
The end