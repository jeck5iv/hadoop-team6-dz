#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

python3 -m pip install --user --upgrade pip
python3 -m pip install --user prefect
"${PREFECT_BIN}" version
