# Modify bioRxiv XML in preparation for Encoda

Prerequisites:

- docker
- libxml2-utils (if running on host)

## XSL files

To apply an xslt transform to all biorXiv XML place it in the `./src` folder.

To apply an xslt transform to a specific manuscript place it in the `./src/[DOI-SUFFIX]` folder.

To apply an xslt transform to a specific version of a manuscript place it in the `./src/[DOI-SUFFIX]` and express in the xslt the query to only apply the changes to that version number.

### Tests for XSL files

Each xsl file must have at least one accompanying test. It is recommended that the `./test/fixtures/kitchen-sink.xml` express at least one example which could be successfully targetted by the global xsl files in `./src/*.xsl`.

You must drop an XML file in test folder for each XSL file in a folder name that corresponds to the filename of the xsl.

For example, an expected result of the `./src/change-label-and-title-elements.xsl` transform can be found in `./test/change-label-and-title-elements`. The filenames of the expected XML are the same as in the `./test/fixtures` folder.

Some examples:

- `./test/change-label-and-title-elements/kitchen-sink.xml` contains the expected XML of `./test/fixtures/kitchen-sink.xml` that has gone through the `./src/change-label-and-title-elements.xsl` transform.

- `./test/all/kitchen-sink.xml` contains the expected XML of `./test/fixtures/kitchen-sink.xml` that has gone through all of the transforms directly in the `./src` folder.

- `./test/2022.05.30.22275761/remove-supplementary-materials/2022.05.30.22275761.xml` contains the expected XML of `./test/fixtures/2022.05.30.22275761/2022.05.30.22275761.xml` that has gone through the `./src/2022.05.30.22275761/remove-supplementary-materials.xsl` transform.

## Build docker image
```
docker buildx build -t epp-biorxiv-xslt .
```

## Apply transform to XML
```
cat test/fixtures/2022.05.30.22275761/2022.05.30.22275761.xml | docker run --rm -i epp-biorxiv-xslt /app/scripts/transform.sh --doi 2022.05.30.22275761
```

Introduce logging:
```
touch session.log
cat test/fixtures/2022.05.30.22275761/2022.05.30.22275761.xml | docker run --rm -i -v "./session.log:/session.log" epp-biorxiv-xslt /app/scripts/transform.sh --doi 2022.05.30.22275761 --log /session.log
```

## Process a folder of biorXiv XML

The structure of the xml within the source folder will be preserved in the destination folder.

```
./scripts/process-folder.sh /path/to/SOURCE_DIR /path/to/DEST_DIR
```

Run with logs:
```
./scripts/process-folder.sh /path/to/SOURCE_DIR /path/to/DEST_DIR --log ./process-folder.log
```

# Run tests

```
./project_tests.sh
```

Run with logs:
```
./project_tests.sh --log ./project-tests.log
```

## Run projects tests entirely within docker container
```
docker buildx build -t epp-biorxiv-xslt .
docker buildx build -t epp-biorxiv-xslt-test -f Dockerfile.test .
docker run --rm epp-biorxiv-xslt-test /app/project_tests.sh
```
