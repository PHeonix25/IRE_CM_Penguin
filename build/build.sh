#!/bin/bash

# First we lint
cfn-lint -a ./ams_lint -t ../src/*.yaml
