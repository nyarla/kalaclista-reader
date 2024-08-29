# litestream
FROM golang:1.23.0-alpine as goreman

RUN mkdir -p /opt/bin
WORKDIR /

ARG GITHUB_GOREMAN_OWNER=mattn
ARG GITHUB_GOREMAN_REPOSITORY=goreman
ARG GITHUB_GOREMAN_REVISION=ebb9736b7c7f7f3425280ab69e1f7989fb34eadc
ARG GITHUB_GOREMAN_VERSION=0.3.15

RUN apk add --update --no-cache --virtual goreman-build \
      build-base \
      git \
    \
    && mkdir -p /src && cd /src \
    \
    && git init \
    && git remote add origin https://github.com/${GITHUB_GOREMAN_OWNER}/${GITHUB_GOREMAN_REPOSITORY}.git \
    && git fetch --depth 1 origin ${GITHUB_GOREMAN_REVISION} \
    && git reset --hard ${GITHUB_GOREMAN_REVISION} \
    \
    && go build \
      -trimpath -v \
      -ldflags "-X 'main.Version=${GITHUB_GOREMAN_VERSION}' -s -w -extldflags '-static' -buildid=" \
      -o /opt/bin/goreman . \
    \
    && apk del --purge goreman-build \
    && cd / && rm -rf /src /root



# litestream
FROM golang:1.23.0-alpine as litestream

RUN mkdir -p /opt/bin
WORKDIR /

ARG GITHUB_LITESTREAM_OWNER=benbjohnson
ARG GITHUB_LITESTREAM_REPOSITORY=litestream
ARG GITHUB_LITESTREAM_REVISION=5be467a478adcffc5b3999b9503cc676c2bf09f1
ARG GITHUB_LITESTREAM_VERSION=git

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
      -o /opt/bin/litestream ./cmd/litestream \
    \
    && apk del --purge litestream-build \
    && cd / && rm -rf /src /root

# h2o
FROM alpine:3.20 as h2o

RUN mkdir -p /opt
WORKDIR /

ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=16b13eee8ad7895b4fe3fcbcabee53bd52782562

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
    -DCMAKE_INSTALL_PREFIX=/opt \
    -DWITH_MRUBY=ON \
  && make && make install && chmod -R -w /opt \
  \
  && apk del --purge h2o-build \
  && cd / && rm -rf /src /root

# freshrss
FROM alpine:3.20 as runtime

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
ARG GITHUB_FRESHRSS_REV=ca28c90f8bf1603594a1489bdeefd2d72e7e18bb
ARG GITHUB_FRESHRSS_VERSION=1.24.2

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

COPY --from=h2o /opt /opt
COPY --from=goreman --chmod=0500 /opt/bin/goreman /opt/bin/
COPY --from=litestream --chmod=0500 /opt/bin/litestream /opt/bin/

COPY --chmod=0400 runtime/litestream.json /var/run/freshrss/litestream.conf
COPY --chmod=0400 runtime/Procfile /var/run/freshrss/Procfile
COPY --chmod=0400 runtime/h2o.json /var/run/freshrss/h2o.conf
COPY --chmod=0700 entrypoint.sh /opt/bin/entrypoint.sh

WORKDIR /var/run/freshrss
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
