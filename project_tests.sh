#!/bin/bash
set -e

TEST_FILE="$(mktemp)"

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo "Checking fixtures that have all xslt transforms applied"
for xml_file in $SCRIPT_DIR/test/all/*.xml; do
    cat "$SCRIPT_DIR/test/fixtures/$(basename ${xml_file})" | "$SCRIPT_DIR/scripts/transform.sh" > "${TEST_FILE}"

    if diff -w -u "${TEST_FILE}" "${xml_file}"; then
        echo "Output matches expected (${xml_file})"
    else
        echo "Output does not match expected (${xml_file})"
        exit 1
    fi
done

for xsl_file in $SCRIPT_DIR/src/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")

    if [ -d "${SCRIPT_DIR}/test/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_filename%.*}/*.xml; do
            cat "$SCRIPT_DIR/test/fixtures/$(basename ${xml_file})" | "$SCRIPT_DIR/scripts/transform.sh" "${xsl_file}" > "${TEST_FILE}"

            if diff -w -u "${TEST_FILE}" "${xml_file}"; then
                echo "Output matches expected ($(basename ${xml_file}) - ${xsl_filename})"
            else
                echo "Output does not match expected ($(basename ${xml_file}) - ${xsl_filename})"
                exit 1
            fi
        done
    else
        echo "No tests exist for (${xsl_file})"
        exit 1
    fi
done

rm "${TEST_FILE}"
