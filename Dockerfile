FROM rclone/rclone:1.52.3 as rclone
FROM docker:19.03.12 as docker

FROM alpine:3.12.0
LABEL maintainer="Felix Haase <felix.haase@feki.de>"

ARG JOBBER_VERSION=1.4.4
ARG DUPLICITY_VERSION=0.8.15
ARG MEGATOOLS_VERSION=1.10.3
ARG INFLUXDB_VERSION=1.8.2

RUN addgroup influxdb && \
        adduser -s /bin/false -G influxdb -S -D influxdb

RUN apk upgrade --update && \
    apk add \
      autoconf \
      automake \
      bash \
      tzdata \
      tini \
      su-exec \
      gzip \
      gettext \
      tar \
      wget \
      curl \
      gmp-dev \
      openssh \
      openssl \
      ca-certificates \
      libffi-dev \
      librsync-dev \
      libevent-dev \
      libevent \
      libressl-dev \
      libressl \
      libtirpc-dev \
      libtool \
      python3-dev \
      gcc \
      glib \
      gnupg \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-cryptography \
      libffi-dev \
      librsync \
      librsync-dev \
      libcurl \
      py3-pip && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir wheel setuptools-scm && \
    pip3 install --no-cache-dir \
      fasteners \
      PyDrive \
      chardet \
      azure-storage-blob \
      boto3 \
      boto \
      paramiko \
      pexpect \
      pycrypto \
      python-keystoneclient \
      python-swiftclient \
      requests \
      requests_oauthlib \
      urllib3 \
      b2sdk \
      dropbox \
      duplicity==${DUPLICITY_VERSION} && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize /var/jobber/0 && \
    # Install tools
    apk add \
      asciidoc \
      automake \
      autoconf \
      build-base \
      curl \
      curl-dev \
      openssl-dev \
      glib-dev \
      libtool \
      make && \
    # Install Jobber
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Install MEGAtools
    curl -fSL "https://megatools.megous.com/builds/megatools-${MEGATOOLS_VERSION}.tar.gz" -o /tmp/megatools.tgz && \
    tar -xzvf /tmp/megatools.tgz -C /tmp && \
    cd /tmp/megatools-${MEGATOOLS_VERSION} && \
    ./configure && \
    make && \
    make install && \
    #installs added by energy-toolbase
    #install influx
    wget https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    tar -C . -xzf influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
        chmod +x influxdb-*/* && \
        cp -a influxdb-*/* /usr/bin/ && \
        rm -rf *.tar.gz* influxdb-*/ && \
    #install trickle
    cd /tmp/ && \
    wget https://github.com/mariusae/trickle/archive/09a1d955c6554eb7e625c99bf96b2d99ec7db3dc.zip && \
    unzip *.zip && \
    cd trickle-* && \
    autoreconf -i && \
    CFLAGS="-I/usr/include/tirpc -ltirpc" ./configure && \
    make install-exec-am install-trickleoverloadDATA && \
    #install redis
    cd /tmp && \
    wget http://download.redis.io/redis-stable.tar.gz && \
    tar xvzf redis-stable.tar.gz && \
    cd redis-stable && \
    make && \
    make install &&\
    # Cleanup
    apk del \
      asciidoc \
      automake \
      autoconf \
      build-base \
      curl \
      curl-dev \
      glib-dev \
      wget \
      libffi-dev \
      librsync-dev \
      libevent-dev \
      libevent \
      libressl-dev \
      libressl \
      libtool \
      python3-dev \
      openssl-dev \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      make && \
    apk add \
        openssl && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

RUN apk add --no-cache curl


COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=docker /usr/local/bin/ /usr/local/bin/

ENV VOLUMERIZE_HOME=/etc/volumerize \
    VOLUMERIZE_CACHE=/volumerize-cache \
    VOLUMERIZE_SCRIPT_DIR=/opt/volumerize \
    PATH=$PATH:/etc/volumerize \
    GOOGLE_DRIVE_SETTINGS=/credentials/cred.file \
    GOOGLE_DRIVE_CREDENTIAL_FILE=/credentials/googledrive.cred \
    GPG_TTY=/dev/console

USER root
WORKDIR /etc/volumerize
VOLUME ["/volumerize-cache"]
COPY imagescripts/ /opt/volumerize/
COPY scripts/ /etc/volumerize/
COPY  database_backup.sh /preexecute/backup/
COPY postexecute/ /postexecute
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]