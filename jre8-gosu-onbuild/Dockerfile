FROM golang:alpine AS waitforit
RUN apk add --no-cache git
RUN go get github.com/ContentWise/waitforit

FROM openjdk:8-jre-alpine

ARG GOREPLAY_VERSION=0.16.1
ARG GOSU_VERSION=1.10

ONBUILD ARG GIT_BRANCH
ONBUILD ARG GIT_BUILD_TIME
ONBUILD ARG GIT_BUILD_VERSION
ONBUILD ARG GIT_COMMIT_ID
ONBUILD ARG GIT_COMMIT_ID_ABBREV
ONBUILD ARG GIT_COMMIT_TIME

ONBUILD ENV GIT_BRANCH=${GIT_BRANCH}
ONBUILD ENV GIT_BUILD_TIME=${GIT_BUILD_TIME}
ONBUILD ENV GIT_BUILD_VERSION=${GIT_BUILD_VERSION}
ONBUILD ENV GIT_COMMIT_ID=${GIT_COMMIT_ID}
ONBUILD ENV GIT_COMMIT_ID_ABBREV=${GIT_COMMIT_ID_ABBREV}
ONBUILD ENV GIT_COMMIT_TIME=${GIT_COMMIT_TIME}

ENV MILLIS_BETWEEN_WAIT_RETRIES=2000
ENV SECONDS_TO_WAIT=86400

ENV ELASTICSEARCH_WAIT_FOR_STATUS=yellow

RUN apk update && apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        openssl && \
    apk add --no-cache \
        build-base \
        libxml2-utils && \
    for server in ha.pool.sks-keyservers.net \
        hkp://p80.pool.sks-keyservers.net:80 \
        keyserver.ubuntu.com \
        hkp://keyserver.ubuntu.com:80 \
        pgp.mit.edu; \
    do \
        gpg --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || echo "Trying new server..."; \
    done && \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    chmod +x /usr/local/bin/gosu && \
    apk del .gosu-deps

RUN apk add --no-cache shadow

COPY run.sh /opt/
RUN wget -q -O - https://github.com/buger/goreplay/releases/download/v${GOREPLAY_VERSION}/gor_${GOREPLAY_VERSION}_x64.tar.gz | tar -xz -C /usr/local/bin
COPY --from=waitforit /go/bin/waitforit /usr/local/bin/waitforit

RUN mkdir -p /opt/cw/imports

ONBUILD ARG JAR_FILE=service.jar
ONBUILD COPY target/${JAR_FILE} /opt/service.jar

CMD ["/opt/run.sh"]
