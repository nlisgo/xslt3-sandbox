#!/bin/bash

INPUT_FILE="$(mktemp)"
TRANSFORM_FILE="$(mktemp)"
OUTPUT_FILE="$(mktemp)"

function transform_xml() {
    docker run -v "./src:/data" -v "$1:/input.xml" -v "$2:/stylesheet.xsl" my-xslt-container /usr/local/bin/apply-xslt /input.xml /stylesheet.xsl
}

XSL_FILE="$1"

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${PARENT_DIR}"

# Build Docker image
docker build -t my-xslt-container .

# Preserve hexadecimal notation
cat /dev/stdin | sed -E "s/&#x([0-9A-F]{4});/HEX\1NOTATION/g" >"${INPUT_FILE}"

# Apply XSLT transform
if [[ -z "$1" ]]; then
    # Apply XSLT transform to all XSL files in src/all folder
    for xsl_file in $PARENT_DIR/src/*.xsl; do
        transform_xml "${INPUT_FILE}" "${xsl_file}" > "${TRANSFORM_FILE}"
        cat "${TRANSFORM_FILE}" > "${INPUT_FILE}"
    done
else
    transform_xml "${INPUT_FILE}" "${XSL_FILE}" > "${TRANSFORM_FILE}"
fi

# Remove empty lines, restore DOCTYPE and restore hexadecimal notation
cat "${TRANSFORM_FILE}" | sed '/^$/d' | sed "s#<?xml version=\"1.0\" encoding=\"UTF-8\"?>#<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE article PUBLIC \"-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.2d1 20170631//EN\" \"JATS-archivearticle1.dtd\">\n#g" | sed -E "s/HEX([0-9A-F]{4})NOTATION/\&#x\1;/g" >"${OUTPUT_FILE}"

# Append an empty line to the file
echo "" >>"${OUTPUT_FILE}"

cat "${OUTPUT_FILE}"

rm "${INPUT_FILE}"
rm "${TRANSFORM_FILE}"
rm "${OUTPUT_FILE}"
