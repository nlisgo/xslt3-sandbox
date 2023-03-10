#!/bin/bash
set -e

TEST_FILE="$(mktemp)"
INPUT_FILE="$(mktemp)"

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

function section_title() {
    echo "${1}"
    printf '%*s\n' "${#1}" | tr ' ' '-'
}

function transform_xml() {
    if [ ! -s "${1}" ]; then
        echo "Error: XML file is empty (${1})" >&2
        exit 1
    fi

    if [ "${2:-}" = "--doi" ]; then
        cat "${1}" | "${SCRIPT_DIR}/scripts/transform.sh" --doi "${3}"
    else
        if [ -n "$2" ] && [ ! -e "$2" ]; then
            echo "Error: XSLT file is empty (${2})" >&2
            exit 1
        fi

        cat "${1}" | "${SCRIPT_DIR}/scripts/transform.sh" "${2:-}"
    fi
}

function expected() {
    if diff -w -u "${1}" "${2}"; then
        echo "Output matches expected (${3})"
        echo ""
    else
        echo "Output does not match expected (${3})"
        exit 1
    fi
}

section_title "Checking fixtures that have all xslt transforms applied (no doi match)"
for xml_file in ${SCRIPT_DIR}/test/all/*.xml; do
    echo "Running test for (${xml_file})"
    transform_xml "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" > "${TEST_FILE}"

    expected "${TEST_FILE}" "${xml_file}" "${xml_file}"
done

section_title "Checking xslt files that apply to all manuscripts"
for xsl_file in ${SCRIPT_DIR}/src/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")

    if [ -d "${SCRIPT_DIR}/test/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_filename%.*}/*.xml; do
            transform_xml "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" "${xsl_file}" > "${TEST_FILE}"

            expected "${TEST_FILE}" "${xml_file}" "$(basename ${xml_file}) - ${xsl_filename}"
        done
    else
        echo "No tests exist for (${xsl_file})"
        exit 1
    fi
done

section_title "Checking fixtures that have all xslt transforms applied (doi match)"
for manuscript_dir in ${SCRIPT_DIR}/src/*/; do
    manuscript_doi=$(basename "${manuscript_dir}")
    for xml_file in ${SCRIPT_DIR}/test/all/${manuscript_doi}/*.xml; do
        echo "Running test for (${xml_file})"
        transform_xml "${SCRIPT_DIR}/test/fixtures/${manuscript_doi}/$(basename ${xml_file})" --doi "${manuscript_doi}" > "${TEST_FILE}"

        expected "${TEST_FILE}" "${xml_file}" "${xml_file}"
    done
done

section_title "Checking xslt files that apply to specific manuscripts"
for xsl_file in ${SCRIPT_DIR}/src/*/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")
    xsl_file_dir=$(basename $(dirname "${xsl_file}"))

    if [ -d "${SCRIPT_DIR}/test/${xsl_file_dir}/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_file_dir}/${xsl_filename%.*}/*.xml; do
            transform_xml "${SCRIPT_DIR}/test/fixtures/${xsl_file_dir}/$(basename ${xml_file})" "${xsl_file}" > "${TEST_FILE}"

            expected "${TEST_FILE}" "${xml_file}" "$(basename ${xml_file}) - ${xsl_file_dir}/${xsl_filename}"
        done
    else
        echo "No tests exist for (${xsl_file})"
        exit 1
    fi
done

rm "${TEST_FILE}"
