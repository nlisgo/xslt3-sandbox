#!/bin/bash
set -e

INPUT_FILE="$(mktemp)"
TRANSFORM_FILE="$(mktemp)"
OUTPUT_FILE="$(mktemp)"

# Set WITHIN_DOCKER variable to true if DOCKER_EPP_BIORXIV_XSLT is set
if [[ -n "${DOCKER_EPP_BIORXIV_XSLT}" ]]; then
    WITHIN_DOCKER=true
else
    WITHIN_DOCKER=false
fi

usage() {
    echo "Usage: $0 [-d|--doi DOI] [-l|--log SESSION_LOG_FILE] [--log-info SESSION_LOG_FILE_INFO] [--log-noprefix] [XSL_FILE]"
    exit 1
}

XSL_FILE=""
DOI=""
SESSION_LOG_FILE=""
SESSION_LOG_FILE_INFO=""
SESSION_LOG_PREFIX=true

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--doi)
            DOI="$2"
            shift 2
            ;;
        -l|--log)
            SESSION_LOG_FILE="$2"
            shift 2
            ;;
        --log-info)
            SESSION_LOG_FILE_INFO="$2"
            shift 2
            ;;
        --log-noprefix)
            SESSION_LOG_PREFIX=false
            shift
            ;;
        -h|--help)
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
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${PARENT_DIR}"

function write_to_log() {
    if [[ -n "${SESSION_LOG_FILE}" ]]; then
        local log_prefix=""
        local log_info=""

        if [[ "${SESSION_LOG_PREFIX}" = true ]]; then
            log_prefix="$(date +"%Y-%m-%d %H:%M:%S"): "
        fi

        if [[ -n "${SESSION_LOG_FILE_INFO}" ]]; then
            log_info="[info: ${SESSION_LOG_FILE_INFO}] "
        fi

        touch "${SESSION_LOG_FILE}"
        echo "${log_prefix}${log_info}${1}" >> "${SESSION_LOG_FILE}"
    fi
}

function write_to_log_xslt() {
    local change_log="no change applied"
    local doi_set="N/A"

    if ! diff -w -u "${2}" "${3}" >/dev/null; then
        change_log="changed"
    fi

    if [[ -n "${DOI}" ]]; then
        doi_set="${DOI}"
    fi

    write_to_log "(DOI: ${doi_set}) ${1#*src/} ${change_log}"
}

function handle_stdin() {
    local input="$(cat /dev/stdin)"

    if [[ "${input: -1}" != $'\n' ]]; then
        input="${input}"$'\n'
    fi

    echo "${input}"
}

function encode_xmlns_attribute() {
    # Set a flag to determine whether we have seen the first <front> tag
    local seen_front=false
    
    # Read input line by line
    while read -r line; do
        # If we have seen <front>, replace all instances of "xmlns:" with "xmlns-preserve-"
        if $seen_front; then
            echo "$line" | sed 's/xmlns:/xmlns-preserve-/g'
        else
            echo "$line"
        fi
        
        # Check if this line contains <front>
        if echo "$line" | grep -q '<front>'; then
            seen_front=true
        fi
    done
}

function restore_xmlns_attribute() {
    sed 's/xmlns-preserve-/xmlns:/g'
}

function encode_hexadecimal_notation() {
    sed -E "s/&#x([0-9A-F]{2,});/HEX\1NOTATION/gi"
}

function restore_hexadecimal_notation() {
    sed -E "s/HEX([0-9A-F]{2,})NOTATION/\&#x\1;/gi"
}

function restore_doctype() {
    sed "s#<?xml version=\"1.0\" encoding=\"UTF-8\"?>#<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE article PUBLIC \"-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.2d1 20170631//EN\" \"JATS-archivearticle1.dtd\">\n#g"
}

function remove_empty_lines() {
    sed '/^$/d'
}

function transform_xml() {
    local xslt_output=$(mktemp)
    local xslt_file_dir=$(mktemp -d)
    local xslt_file="${xslt_file_dir}/$(basename ${2})"

    cat "${2}" | encode_hexadecimal_notation > "${xslt_file}"

    if [[ "${WITHIN_DOCKER}" == "true" ]]; then
        /usr/local/bin/apply-xslt "${1}" "${xslt_file}" > "${xslt_output}"
    else
        # Check if Docker image exists
        if [[ "$(docker images -q epp-biorxiv-xslt 2> /dev/null)" == "" ]]; then
            # Build Docker image
            docker buildx build -t epp-biorxiv-xslt .
        fi

        docker run --rm -v "${PARENT_DIR}/src:/app" -v "${1}:/input.xml" -v "${xslt_file}:/stylesheet.xsl" epp-biorxiv-xslt /usr/local/bin/apply-xslt /input.xml /stylesheet.xsl > "${xslt_output}"
    fi

    write_to_log_xslt "${2}" "${1}" "${xslt_output}"

    cat "${xslt_output}"

    rm -f "${xslt_output}"
    rm -rf "${xslt_file_dir}"
}

handle_stdin | encode_xmlns_attribute | encode_hexadecimal_notation > "${INPUT_FILE}"

# Apply XSLT transform
if [[ -z "${XSL_FILE}" ]]; then
    # Apply XSLT transform to all XSL files in src/ folder
    for xsl_file in $PARENT_DIR/src/*.xsl; do
        transform_xml "${INPUT_FILE}" "${xsl_file}" > "${TRANSFORM_FILE}"
        cat "${TRANSFORM_FILE}" > "${INPUT_FILE}"
    done
    if [[ -n "${DOI}" ]]; then
        if [[ -d "${PARENT_DIR}/src/${DOI}" ]]; then
            # Apply XSLT transform to all XSL files in src/[DOI]/ folder
            for xsl_file in $PARENT_DIR/src/$DOI/*.xsl; do
                transform_xml "${INPUT_FILE}" "${xsl_file}" > "${TRANSFORM_FILE}"
                cat "${TRANSFORM_FILE}" > "${INPUT_FILE}"
            done
        fi
    fi
else
    transform_xml "${INPUT_FILE}" "${XSL_FILE}" > "${TRANSFORM_FILE}"
fi

# Remove empty lines, restore DOCTYPE and restore hexadecimal notation
cat "${TRANSFORM_FILE}" | remove_empty_lines | restore_doctype | restore_hexadecimal_notation | restore_xmlns_attribute > "${OUTPUT_FILE}"

# Append an empty line to the file
echo "" >> "${OUTPUT_FILE}"

cat "${OUTPUT_FILE}"

rm -f "${INPUT_FILE}"
rm -f "${TRANSFORM_FILE}"
rm -f "${OUTPUT_FILE}"
