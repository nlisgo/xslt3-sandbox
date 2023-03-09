#!/bin/bash
set -e

TEST_FILE="$(mktemp)"

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo "Checking fixtures that have all xslt transforms applied (no doi match)"
echo "----------------------------------------------------------------------"
for xml_file in ${SCRIPT_DIR}/test/all/*.xml; do
    xml_filename=$(basename "${xml_file}")
    if [ ! -d "${SCRIPT_DIR}/src/${xml_filename%.*}" ]; then
        echo "Running test for (${xml_file})"
        cat "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" | "${SCRIPT_DIR}/scripts/transform.sh" > "${TEST_FILE}"

        if diff -w -u "${TEST_FILE}" "${xml_file}"; then
            echo "Output matches expected (${xml_file})"
            echo ""
        else
            echo "Output does not match expected (${xml_file})"
            exit 1
        fi
    fi
done

echo "Checking xslt files that apply to all manuscripts"
echo "-------------------------------------------------"
for xsl_file in ${SCRIPT_DIR}/src/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")

    if [ -d "${SCRIPT_DIR}/test/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_filename%.*}/*.xml; do
            cat "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" | "${SCRIPT_DIR}/scripts/transform.sh" "${xsl_file}" > "${TEST_FILE}"

            if diff -w -u "${TEST_FILE}" "${xml_file}"; then
                echo "Output matches expected ($(basename ${xml_file}) - ${xsl_filename})"
                echo ""
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

echo "Checking fixtures that have all xslt transforms applied (doi match)"
echo "-------------------------------------------------------------------"
for manuscript_dir in ${SCRIPT_DIR}/src/*/; do
    manuscript_doi=$(basename "${manuscript_dir}")
    for xml_file in ${SCRIPT_DIR}/test/all/${manuscript_doi}*.xml; do
        echo "Running test for (${xml_file})"
        # todo: need to pass the manuscript id to transform.sh so we can apply all of the relevant styles
        cat "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" | "${SCRIPT_DIR}/scripts/transform.sh" --doi "${manuscript_doi}" > "${TEST_FILE}"

        if diff -w -u "${TEST_FILE}" "${xml_file}"; then
            echo "Output matches expected (${xml_file})"
            echo ""
        else
            echo "Output does not match expected (${xml_file})"
            exit 1
        fi
    done
done

echo "Checking xslt files that apply to specific manuscripts"
echo "------------------------------------------------------"
for xsl_file in ${SCRIPT_DIR}/src/*/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")
    xsl_file_dir=$(basename $(dirname "${xsl_file}"))

    if [ -d "${SCRIPT_DIR}/test/${xsl_file_dir}/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file_dir}/${xsl_file})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_file_dir}/${xsl_filename%.*}/*.xml; do
            cat "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" | "${SCRIPT_DIR}/scripts/transform.sh" "${xsl_file}" > "${TEST_FILE}"

            if diff -w -u "${TEST_FILE}" "${xml_file}"; then
                echo "Output matches expected ($(basename ${xml_file}) - ${xsl_file_dir}/${xsl_filename})"
                echo ""
            else
                echo "Output does not match expected ($(basename ${xml_file}) - ${xsl_file_dir}/${xsl_filename})"
                exit 1
            fi
        done
    else
        echo "No tests exist for (${xsl_file})"
        exit 1
    fi
done

rm "${TEST_FILE}"
