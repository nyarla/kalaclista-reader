# shoreman
FROM alpine as shoreman

RUN mkdir -p /app/bin
WORKDIR /

ARG GITHUB_SHOREMAN_URL="https://raw.githubusercontent.com/chrismytton/shoreman/master/shoreman.sh"
ARG GITHUB_SHOREMAN_SHA256="a21acce3072bb8594565094e4a9bbafd3b9d7fa04abd7e0c74c19fd479adb817"

RUN apk add --update --no-cache --virtual shoreman curl coreutils \
  \
  && curl -o /app/bin/shoreman "${GITHUB_SHOREMAN_URL}" \
  && test "$(sha256sum /app/bin/shoreman | cut -d ' ' -f 1)" = "${GITHUB_SHOREMAN_SHA256}" \
  && chmod -R +x /app/bin \
  && apk del --purge shoreman

# h2o
FROM alpine:edge as h2o

RUN mkdir -p /app
WORKDIR /

# 2024-02-12
ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=ba710acc948fdb9954e1c93326c8d731bfe31a38

RUN apk add --update --no-cache --virtual h2o-build \
      bison \
      build-base \
      ca-certificates \
      cmake \
      git \
      linux-headers \
      openssl-dev \
      perl \
      ruby \
      ruby-dev \
      ruby-rake \
      zlib-dev \
  \
  && mkdir -p src && cd src \
  \
  && git init \
  && git remote add origin https://github.com/${GITHUB_H2O_OWNER}/${GITHUB_H2O_REPOSITORY}.git \
  && git fetch --depth 1 origin ${GITHUB_H2O_REVISION} \
  && git reset --hard ${GITHUB_H2O_REVISION} \
  && git submodule update --init --recursive \
  \
  && mkdir -p build && cd build \
  && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/app \
    -DWITH_MRUBY=ON \
  && make && make install && chmod -R -w /app \
  \
  && apk del --purge h2o-build \
  && cd / && rm -rf /src /root

# litestream
FROM golang:1.21.3-alpine as litestream

RUN mkdir -p /app/bin
WORKDIR /

ARG GITHUB_LITESTREAM_OWNER=benbjohnson
ARG GITHUB_LITESTREAM_REPOSITORY=litestream
ARG GITHUB_LITESTREAM_REVISION=977d4a5ee45ae546537324a3cfbf926de3bebc97
ARG GITHUB_LITESTREAM_VERSION=v0.3.13

RUN apk add --update --no-cache --virtual litestream-build \
      build-base \
      git \
    \
    && mkdir -p /src && cd /src \
    \
    && git init \
    && git remote add origin https://github.com/${GITHUB_LITESTREAM_OWNER}/${GITHUB_LITESTREAM_REPOSITORY}.git \
    && git fetch --depth 1 origin ${GITHUB_LITESTREAM_REVISION} \
    && git reset --hard ${GITHUB_LITESTREAM_REVISION} \
    \
    && go build \
      -trimpath -v \
      -ldflags "-X 'main.Version=${GITHUB_LITESTREAM_VERSION}' -s -w -extldflags '-static' -buildid=" \
      -tags osusergo,netgo,sqlite_omit_load_extension \
      -o /app/bin/litestream ./cmd/litestream \
    \
    && apk del --purge litestream-build \
    && cd / && rm -rf /src /root

# freshrss
FROM alpine:3.19 as runtime

RUN mkdir -p /data/freshrss /var/lib/freshrss /var/run/freshrss

WORKDIR /

RUN apk add --update --no-cache \
      bash \
      git \
      tzdata \
      php \
      php-cgi \
      php-ctype \
      php-curl \
      php-dom \
      php-fileinfo \
      php-gmp \
      php-iconv \
      php-intl \
      php-json \
      php-mbstring \
      php-opcache \
      php-openssl \
      php-pdo_mysql \
      php-pdo_pgsql \
      php-pdo_sqlite \
      php-phar \
      php-session \
      php-simplexml \
      php-tokenizer \
      php-xml \
      php-xmlreader \
      php-xmlwriter \
      php-zip \
      php-zlib

ARG GITHUB_FRESHRSS_OWNER=FreshRSS
ARG GITHUB_FRESHRSS_REPO=FreshRSS
ARG GITHUB_FRESHRSS_REV=227233b4efab7618de77eef7dbd06abdbe51cf1e
ARG GITHUB_FRESHRSS_VERSION=1.23.1

RUN cd /var/lib/freshrss \
  \
  && git init \
  && git remote add origin https://github.com/${GITHUB_FRESHRSS_OWNER}/${GITHUB_FRESHRSS_REPO}.git \
  && git fetch --depth 1 origin ${GITHUB_FRESHRSS_REV} \
  && git reset --hard ${GITHUB_FRESHRSS_REV} \
  \
  && chown nobody:nobody -R . \
  && chmod 700 -R . \
  && rm -rf .devcontainer .git .github Docker docs tests \
  \
  && chown -R nobody:nobody .

COPY --from=h2o /app /app
COPY --from=shoreman --chmod=0500 /app/bin/shoreman /app/bin/
COPY --from=litestream --chmod=0500 /app/bin/litestream /app/bin/

COPY --chmod=0400 runtime/litestream.json /var/run/freshrss/litestream.conf
COPY --chmod=0400 runtime/Procfile /var/run/freshrss/Procfile
COPY --chmod=0400 runtime/h2o.json /var/run/freshrss/h2o.conf
COPY --chmod=0700 entrypoint.sh /app/bin/entrypoint.sh

COPY --chmod=0400 --chown=nobody:nobody extensions/GReaderRedate/xExtension-GReaderRedate /var/lib/freshrss/extensions/xExtension-GReaderRedate
COPY --chmod=0444 --chown=nobody:nobody extensions/Official/xExtension-CustomCSS /var/lib/freshrss/extensions/xExtension-CustomCSS

WORKDIR /var/run/freshrss
ENTRYPOINT ["/app/bin/entrypoint.sh"]
