#!/bin/bash

# Called by TGS before compiling, with the deployment directory as $1.
# Builds tgui and prepends the TGS define to the dme.

set -e
set -x

original_dir=$PWD
cd "$1"

env TG_BOOTSTRAP_CACHE="$original_dir" CBT_BUILD_MODE="TGS" tools/bootstrap/javascript.sh tools/build/build.ts
