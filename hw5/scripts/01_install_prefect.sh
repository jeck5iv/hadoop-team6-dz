#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

if [ ! -d "${VENV_DIR}" ]; then
  python3 -m venv "${VENV_DIR}"
fi

"${PY_BIN}" -m pip install --upgrade pip
"${PY_BIN}" -m pip install prefect
"${PREFECT_BIN}" version
