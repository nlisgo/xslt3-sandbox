#!/bin/bash
set -e

if ! command -v xmllint &> /dev/null; then
    echo "Error: xmllint command not found" >&2
    exit 1
fi

usage() {
    echo "Usage: $0 [-l|--log SESSION_LOG_FILE] SOURCE_DIR DEST_DIR"
    exit 1
}

SOURCE_DIR=""
DEST_DIR=""
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
        if [[ -z "$SOURCE_DIR" ]]; then
            SOURCE_DIR="$1"
        elif [[ -z "$DEST_DIR" ]]; then
            DEST_DIR="$1"
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

FULL_PATH_SOURCE_DIR="$(realpath "${SOURCE_DIR}")"
FULL_PATH_DEST_DIR="$(realpath "${DEST_DIR}")"

function transform_xml() {
    local xml_file="${1}"
    local xml_filename="$(basename ${xml_file})"
    local doi=$(cat ${xml_file} | sed 's/xmlns=".*"//g' | xmllint -xpath 'string(/article/front/article-meta/article-id)' -)
    local doi_suffix="${doi#*10.1101/}"
    local xml_file_source_dir="$(dirname "${xml_file}")"
    local xml_file_dest_dir="${FULL_PATH_DEST_DIR}${xml_file_source_dir#${FULL_PATH_SOURCE_DIR}}"

    mkdir -p "${xml_file_dest_dir}"

    if [[ -n "${SESSION_LOG_FILE}" ]]; then
        local session_log=" --log ${SESSION_LOG_FILE}"
    fi

    cat "${xml_file}" | "${SCRIPT_DIR}/transform.sh" --doi "${doi_suffix}"${session_log:-} > "${xml_file_dest_dir}/${xml_filename}"
}

for xml_file in $(find "${FULL_PATH_SOURCE_DIR}" -type f -name '*.xml'); do
    transform_xml "${xml_file}"
done
