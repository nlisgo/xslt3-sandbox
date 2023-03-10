# Modify bioRxiv XML in preparation for Encoda
```
docker buildx build -t epp-biorxiv-xslt .
cat test/fixtures/kitchen-sink.xml | docker run --rm -i epp-biorxiv-xslt /app/scripts/transform.sh
cat test/fixtures/2022.05.30.22275761/2022.05.30.22275761.xml | docker run --rm -i epp-biorxiv-xslt /app/scripts/transform.sh
```

# Run tests

## Run smoke tests
```
./smoke_tests.sh
```

## Run projects tests
```
./project_tests.sh
```

## Run projects tests entirely within docker container
```
docker buildx build -t epp-biorxiv-xslt-test -f Dockerfile.test .
docker run --rm epp-biorxiv-xslt-test /app/project_tests.sh
```
