#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -xe

cd $SCRIPT_DIR

mv "`find output -name "*.html"`" output/index.html

cd output

7z a ../camera-scene-capture.7z *