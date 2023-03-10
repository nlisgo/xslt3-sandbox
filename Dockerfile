FROM openjdk:11

RUN apt-get update && apt-get install -y wget libxml2-utils

RUN wget https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.5/Saxon-HE-10.5.jar \
    && mkdir -p /usr/share/java \
    && mv Saxon-HE-10.5.jar /usr/share/java/saxon.jar

RUN echo "#!/bin/bash\njava -jar /usr/share/java/saxon.jar -s:\$1 -xsl:\$2" > /usr/local/bin/apply-xslt

RUN chmod +x /usr/local/bin/apply-xslt

RUN touch /JATS-archivearticle1.dtd

RUN touch /tmp/JATS-archivearticle1.dtd

ENV DOCKER_EPP_BIORXIV_XSLT=1

WORKDIR /app

COPY scripts /app/scripts

RUN chmod +x -R /app/scripts/*

COPY src /app/src

CMD ["/bin/bash"]
