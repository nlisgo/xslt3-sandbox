#!/bin/bash
set -e

ACTUAL_TXT="$(mktemp)"

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Build Docker image
docker build -t my-xslt-container "${SCRIPT_DIR}"

# Apply XSLT transform
docker run -v "${SCRIPT_DIR}/test/smoke:/data" my-xslt-container /usr/local/bin/apply-xslt /data/input.xml /data/stylesheet.xsl > "${ACTUAL_TXT}"

# Verify output
if diff -u "${SCRIPT_DIR}/test/smoke/expected.txt" "${ACTUAL_TXT}"; then
    echo "Output matches expected"
else
    echo "Output does not match expected"
    exit 1
fi

rm "${ACTUAL_TXT}"
