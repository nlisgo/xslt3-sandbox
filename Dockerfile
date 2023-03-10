FROM openjdk:11

RUN apt-get update && apt-get install -y wget vim

RUN wget https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.5/Saxon-HE-10.5.jar \
    && mkdir -p /usr/share/java \
    && mv Saxon-HE-10.5.jar /usr/share/java/saxon.jar

RUN echo "#!/bin/bash\njava -jar /usr/share/java/saxon.jar -s:\$1 -xsl:\$2" > /usr/local/bin/apply-xslt

RUN chmod +x /usr/local/bin/apply-xslt

RUN touch /JATS-archivearticle1.dtd

WORKDIR /app

COPY scripts /app/scripts

COPY src /app/src

EXPOSE 5005

CMD ["/bin/bash"]
