#!/bin/bash
set -e

usage() {
    echo "Usage: $0 [-l|--log SESSION_LOG_FILE]"
    exit 1
}

TEST_FILE="$(mktemp)"
XSL_FILE=""
DOI=""
SESSION_LOG_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -l | --log)
        SESSION_LOG_FILE="$2"
        shift 2
        ;;
    -h | --help)
        usage
        ;;
    -*)
        echo "Unknown option: $1" >&2
        usage
        ;;
    *)
        if [[ -z "$XSL_FILE" ]]; then
            XSL_FILE="$1"
        else
            echo "Unexpected parameter: $1" >&2
            usage
        fi
        shift
        ;;
    esac
done

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [[ -n "${SESSION_LOG_FILE}" ]]; then
    touch "${SESSION_LOG_FILE}"
    echo -n "" > "${SESSION_LOG_FILE}"
fi

function write_to_log() {
    if [[ -n "${SESSION_LOG_FILE}" ]]; then
        echo "${1}" >> "${SESSION_LOG_FILE}"
    fi
}

function write_to_log_comparison() {
    write_to_log "successful comparison with: ${1#*test/}"
    write_to_log ""
}

function section_title() {
    echo "${1}"
    printf '%*s\n' "${#1}" | tr ' ' '-'
}

function transform_xml() {
    if [ ! -s "${1}" ]; then
        echo "Error: XML file is empty (${1})" >&2
        exit 1
    fi

    if [[ -n "${SESSION_LOG_FILE}" ]]; then
        local debug=" --log ${SCRIPT_DIR}/project-tests.log --log-info ${1#*fixtures/} --log-noprefix"
    fi

    if [ "${2:-}" = "--doi" ]; then
        cat "${1}" | "${SCRIPT_DIR}/scripts/transform.sh" --doi "${3}"${debug:-}
    else
        if [ -n "$2" ] && [ ! -e "$2" ]; then
            echo "Error: XSLT file is empty (${2})" >&2
            exit 1
        fi

        cat "${1}" | "${SCRIPT_DIR}/scripts/transform.sh" "${2:-}"${debug:-}
    fi
}

function expected() {
    local actual_xml="${1}"
    local expected_xml="${2}"
    local source_xml="${3}"
    local description="${4}"
    local debug_actual="${SCRIPT_DIR}/actual-$(date +%Y%m%d-%H%M-%S).xml"

    if diff -w -u "${source_xml}" "${expected_xml}" >/dev/null; then
        echo "Source XML (${source_xml#*test/}) must differ from expected result (${expected_xml#*test/})" >&2
        exit 1
    fi

    if diff -w -u "${actual_xml}" "${expected_xml}" >/dev/null; then
        echo "Output matches expected (${description#*test/})"
        write_to_log_comparison "${expected_xml#*test/}"
        echo ""
    else
        echo "Output does not match expected (${description#*test/})" >&2
        cat "${actual_xml}" > "${debug_actual}"
        echo "The XML that was produced that differs from ${description} is available here: ${debug_actual}"
        exit 1
    fi
}

section_title "Checking fixtures that have all xslt transforms applied (no doi match)"
for xml_file in ${SCRIPT_DIR}/test/all/*.xml; do
    echo "Running test for (${xml_file#*test/})"
    transform_xml "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" > "${TEST_FILE}"

    expected "${TEST_FILE}" "${xml_file}" "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" "${xml_file}"
done

section_title "Checking xslt files that apply to all manuscripts"
for xsl_file in ${SCRIPT_DIR}/src/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")

    if [ -d "${SCRIPT_DIR}/test/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file#*src/})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_filename%.*}/*.xml; do
            transform_xml "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" "${xsl_file}" > "${TEST_FILE}"

            expected "${TEST_FILE}" "${xml_file}" "${SCRIPT_DIR}/test/fixtures/$(basename ${xml_file})" "$(basename ${xml_file}) - ${xsl_filename}"
        done
    else
        echo "No tests exist for (${xsl_file#*test/})" >&2
        exit 1
    fi
done

section_title "Checking fixtures that have all xslt transforms applied (doi match)"
for manuscript_dir in ${SCRIPT_DIR}/src/*/; do
    manuscript_doi=$(basename "${manuscript_dir}")
    if [ -d "${SCRIPT_DIR}/test/all/${manuscript_doi}" ]; then
        for xml_file in ${SCRIPT_DIR}/test/all/${manuscript_doi}/*.xml; do
            echo "Running test for (${xml_file#*test/})"
            transform_xml "${SCRIPT_DIR}/test/fixtures/${manuscript_doi}/$(basename ${xml_file})" --doi "${manuscript_doi}" > "${TEST_FILE}"

            expected "${TEST_FILE}" "${xml_file}" "${SCRIPT_DIR}/test/fixtures/${manuscript_doi}/$(basename ${xml_file})" "${xml_file}"
        done
    else
        echo "Consider adding expected output in ${SCRIPT_DIR}/test/all/${manuscript_doi}"
        echo ""
    fi
done

section_title "Checking xslt files that apply to specific manuscripts"
for xsl_file in ${SCRIPT_DIR}/src/*/*.xsl; do
    xsl_filename=$(basename "${xsl_file}")
    xsl_file_dir=$(basename $(dirname "${xsl_file}"))

    if [ -d "${SCRIPT_DIR}/test/${xsl_file_dir}/${xsl_filename%.*}" ]; then
        echo "Running tests for (${xsl_file#*src/})"
        for xml_file in ${SCRIPT_DIR}/test/${xsl_file_dir}/${xsl_filename%.*}/*.xml; do
            transform_xml "${SCRIPT_DIR}/test/fixtures/${xsl_file_dir}/$(basename ${xml_file})" "${xsl_file}" > "${TEST_FILE}"

            expected "${TEST_FILE}" "${xml_file}" "${SCRIPT_DIR}/test/fixtures/${xsl_file_dir}/$(basename ${xml_file})" "$(basename ${xml_file}) - ${xsl_file_dir}/${xsl_filename}"
        done
    else
        echo "No tests exist for (${xsl_file#*test/})" >&2
        exit 1
    fi
done

rm "${TEST_FILE}"

section_title "Verify ./scripts/process-folder.sh"

PROCESS_FOLDER_TMP=$(mktemp -d)

"${SCRIPT_DIR}/scripts/process-folder.sh" "${SCRIPT_DIR}/test/fixtures" "${PROCESS_FOLDER_TMP}"

rm -rf "${PROCESS_FOLDER_TMP}"

echo "All done!"
