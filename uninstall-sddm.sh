#!/usr/bin/env bash
# Cinder Ash 0.01 — MisterKnot
set -euo pipefail
CINDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$CINDER_ROOT/scripts/manage.py" uninstall-sddm "$@"
