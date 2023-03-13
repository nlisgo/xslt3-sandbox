#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"
DOCUMENTATION_FILE="${PARENT_DIR}/README.md"
DOCUMENTATION_ERROR=false

verify_docs () {
    local xsl_file="${1}"
    local xsl_file_short="src/${xsl_file#*src/}"
    local line_number=$(grep -n "${xsl_file_short}" "${DOCUMENTATION_FILE}" | cut -d ':' -f 1 | head -n1)

    if [[ "${line_number}" -eq "" ]]; then
        DOCUMENTATION_ERROR=true
        echo "${xsl_file_short}: no documentation entry found"
    else
        echo "${xsl_file_short}: documentation entry found on line number ${line_number}"
    fi
}

for xsl_file in $(find "${PARENT_DIR}/src" -type f -name '*.xsl'); do
    verify_docs "${xsl_file}"
done

echo ""

if [[ "${DOCUMENTATION_ERROR}" = true ]]; then
    echo "Error: documentation not found for one or more XSL files in ${DOCUMENTATION_FILE}"
    exit 1
else
    echo "Documentation contains an entry for all xsl files in ${DOCUMENTATION_FILE}"
fi
