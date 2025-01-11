FROM alpine:3.20

ARG BIN="/usr/bin/codjixd"
ARG SCRIPT="https://dub.sh/codjixd"
ARG VERSION="1.0.1"

LABEL maintainer="Ibrahim Megahed <admin@codjix.me>" \
  org.opencontainers.image.title="codjixd" \
  org.opencontainers.image.description="A lightweight and flexible service manager for Linux systems." \
  org.opencontainers.image.authors="Ibrahim Megahed <admin@codjix.me>" \
  org.opencontainers.image.version="${VERSION}"

RUN apk add --no-cache bash procps less && \
  mkdir -p /opt/codjixd/services && \
  wget ${SCRIPT} -O ${BIN} && \
  chmod 777 ${BIN}
