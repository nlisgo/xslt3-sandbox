#!/bin/bash

INPUT_FILE="$(mktemp)"
TRANSFORM_FILE="$(mktemp)"
OUTPUT_FILE="$(mktemp)"

usage() {
    echo "Usage: $0 [-d|--doi DOI] [XSL_FILE]"
    exit 1
}

XSL_FILE=""
DOI=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--doi)
            DOI="$2"
            shift 2
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

function transform_xml() {
    docker run --rm -v "${PARENT_DIR}/src:/data" -v "$1:/input.xml" -v "$2:/stylesheet.xsl" epp-biorxiv-xslt /usr/local/bin/apply-xslt /input.xml /stylesheet.xsl
}

# Check if Docker image exists
if [[ "$(docker images -q epp-biorxiv-xslt 2> /dev/null)" == "" ]]; then
    # Build Docker image
    docker buildx build -t epp-biorxiv-xslt .
fi

# Preserve hexadecimal notation
cat /dev/stdin | sed -E "s/&#x([0-9A-F]{4});/HEX\1NOTATION/g" > "${INPUT_FILE}"

# Apply XSLT transform
if [[ -z "${XSL_FILE}" ]]; then
    # Apply XSLT transform to all XSL files in src/all folder
    for xsl_file in $PARENT_DIR/src/*.xsl; do
        transform_xml "${INPUT_FILE}" "${xsl_file}" > "${TRANSFORM_FILE}"
        cat "${TRANSFORM_FILE}" > "${INPUT_FILE}"
    done
    if [[ -n "${DOI}" ]]; then
        # Apply XSLT transform to all XSL files in src/all folder
        for xsl_file in $PARENT_DIR/src/$DOI/*.xsl; do
            transform_xml "${INPUT_FILE}" "${xsl_file}" > "${TRANSFORM_FILE}"
            cat "${TRANSFORM_FILE}" > "${INPUT_FILE}"
        done
    fi
else
    transform_xml "${INPUT_FILE}" "${XSL_FILE}" > "${TRANSFORM_FILE}"
fi

# Remove empty lines, restore DOCTYPE and restore hexadecimal notation
cat "${TRANSFORM_FILE}" | sed '/^$/d' | sed "s#<?xml version=\"1.0\" encoding=\"UTF-8\"?>#<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE article PUBLIC \"-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.2d1 20170631//EN\" \"JATS-archivearticle1.dtd\">\n#g" | sed -E "s/HEX([0-9A-F]{4})NOTATION/\&#x\1;/g" > "${OUTPUT_FILE}"

# Append an empty line to the file
echo "" >> "${OUTPUT_FILE}"

cat "${OUTPUT_FILE}"

rm "${INPUT_FILE}"
rm "${TRANSFORM_FILE}"
rm "${OUTPUT_FILE}"
