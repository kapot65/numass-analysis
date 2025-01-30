#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


echo $SCRIPT_DIR

echo "Starting notebook server"
cd $SCRIPT_DIR && \
    julia --project=. start.jl