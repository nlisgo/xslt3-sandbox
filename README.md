# Modify bioRxiv XML in preparation for Encoda

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
cat test/fixtures/2022.05.30.22275761/2022.05.30.22275761.xml | docker run --rm -i "./session.log:/session.log" epp-biorxiv-xslt /app/scripts/transform.sh --doi 2022.05.30.22275761 --log /session.log
```

## Process a folder of biorXiv XML

The structure of the xml withinthe source folder will be preserved in the destination folder.

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

Run with logs:
```
docker run --rm epp-biorxiv-xslt-test /app/project_tests.sh --log /app/project-tests.log
```
