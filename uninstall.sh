#!/bin/bash
set -euo pipefail

echo "Removing vlt..."
sudo rm -f /usr/local/bin/vlt
echo "Done. (Vault, envconsul, and jq were left installed)"
