#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -xe

cd $SCRIPT_DIR

rm -rf output
rm *.7z
mkdir output