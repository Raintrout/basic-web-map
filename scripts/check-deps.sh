#!/usr/bin/env bash
# check-deps.sh — verify all required tools are present
set -euo pipefail

ok=true

check() {
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then
    echo "  [ok]  $name"
  else
    echo "  [!!]  $name — NOT FOUND"
    ok=false
  fi
}

echo "Checking dependencies..."

check "python3"      command -v python3
check "geopandas"    python3 -c "import geopandas"
check "fiona"        python3 -c "import fiona"
check "tippecanoe"   command -v tippecanoe
check "curl"         command -v curl

echo ""
if $ok; then
  echo "All dependencies satisfied."
else
  echo "Some dependencies are missing."
  echo ""
  echo "Install Python packages:  pip install -r requirements.txt"
  echo "Install tippecanoe:"
  echo "  macOS:   brew install tippecanoe"
  echo "  Ubuntu:  sudo apt install tippecanoe"
  echo "  Source:  https://github.com/felt/tippecanoe"
  exit 1
fi
