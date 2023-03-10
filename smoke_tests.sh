#!/bin/bash
set -e

ACTUAL_TXT="$(mktemp)"

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Check if Docker image exists
if [[ "$(docker images -q epp-biorxiv-xslt 2> /dev/null)" == "" ]]; then
    # Build Docker image
    docker buildx build -t epp-biorxiv-xslt .
fi

# Apply XSLT transform
docker run --rm -v "${SCRIPT_DIR}/test/smoke:/app" epp-biorxiv-xslt /usr/local/bin/apply-xslt /app/input.xml /app/stylesheet.xsl > "${ACTUAL_TXT}"

# Verify output
if diff -u "${SCRIPT_DIR}/test/smoke/expected.txt" "${ACTUAL_TXT}"; then
    echo "Output matches expected"
else
    echo "Output does not match expected"
    exit 1
fi

rm "${ACTUAL_TXT}"
