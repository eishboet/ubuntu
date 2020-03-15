FROM amd64/ubuntu:18.04 as build

RUN apt-get update && apt-get install -y wget

ENV GOMPLATE_DOWNLOAD=https://github.com/hairyhenderson/gomplate/releases/download/v3.0.0/gomplate_linux-amd64-slim
ENV GOMPLATE_CHECKSUM=ba6cf854da46f9d9a50d26ec7d4a8a8b24f65ecce54a8a93d23eb0b6e138d8eb

RUN cd /tmp && \
  wget -O gomplate ${GOMPLATE_DOWNLOAD} && \
  echo "${GOMPLATE_CHECKSUM} *gomplate" | sha256sum -c - && \
  chmod +x gomplate

ENV SU_EXEC_DOWNLOAD=https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64
ENV SU_EXEC_CHECKSUM=5b3b03713a888cee84ecbf4582b21ac9fd46c3d935ff2d7ea25dd5055d302d3c

RUN cd /tmp && \
  wget -O su-exec ${SU_EXEC_DOWNLOAD} && \
  echo "${SU_EXEC_CHECKSUM} *su-exec" | sha256sum -c - && \
  chmod +x su-exec

FROM amd64/golang:1.13 as golang

ENV CGO_ENABLED=0
ENV WAIT_FOR_REPO=https://github.com/alioygur/wait-for
ENV WAIT_FOR_COMMIT=a2569b146c861c574e62d416699b78efe66ed883

RUN git clone ${WAIT_FOR_REPO} /go/wait-for && \
  cd /go/wait-for && \
  git checkout ${WAIT_FOR_COMMIT} && \
  go build -v -a -installsuffix cgo -o /tmp/wait-for

FROM amd64/ubuntu:18.04

LABEL maintainer="ownCloud DevOps <devops@owncloud.com>" \
  org.label-schema.name="ownCloud Ubuntu" \
  org.label-schema.vendor="ownCloud GmbH" \
  org.label-schema.schema-version="1.0"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm

RUN apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y \
    ca-certificates \
    bash \
    vim \
    curl \
    wget \
    procps \
    apt-utils \
    apt-transport-https \
    iputils-ping \
    bzip2 \
    unzip \
    cron \
    git-core \
    sshpass \
    tree \
    jq \
    gnupg && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./overlay /
CMD ["bash"]

COPY --from=build /tmp/gomplate /usr/bin/gomplate
COPY --from=build /tmp/su-exec /usr/bin/su-exec
COPY --from=golang /tmp/wait-for /usr/bin/wait-for
