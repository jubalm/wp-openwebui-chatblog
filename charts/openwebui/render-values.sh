#!/bin/bash
set -euo pipefail

# Placeholder for future secret/env injection
cp "$(dirname "$0")/values.template.yaml" "$(dirname "$0")/my-values.yaml"
echo "Rendered my-values.yaml for Open WebUI." 