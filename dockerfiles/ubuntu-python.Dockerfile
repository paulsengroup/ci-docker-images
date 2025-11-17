# Copyright (C) 2025 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS='ghcr.io/paulsengroup/ci-docker-images/ubuntu-24.04-cxx-clang-21'
ARG FINAL_OS='ubuntu:24.04'

FROM $BASE_OS AS py-src

ARG PYTHON_TAR_URL='https://www.python.org/ftp/python/3.14.0/Python-3.14.0.tar.xz'
ARG PYTHON_TAR_SHA256='2299dae542d395ce3883aca00d3c910307cd68e0b2f7336098c8e7b7eee9f3e9'

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

RUN apt-get update \
&&  apt-get install -q -y \
    curl \
    tar \
    xz-utils \
&&  rm -rf /var/lib/apt/lists/*

RUN curl -L "$PYTHON_TAR_URL" \
         -o /tmp/python.tar \
&&  echo "$PYTHON_TAR_SHA256  /tmp/python.tar" > /tmp/checksum.sha256 \
&&  sha256sum -c /tmp/checksum.sha256

RUN mkdir /tmp/python-src \
&&  tar -C /tmp/python-src -xf /tmp/python.tar --strip-components=1


FROM $BASE_OS AS builder-base

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

RUN apt-get update \
&&  apt-get install -q -y \
    build-essential \
    curl \
    tar \
    xz-utils \
    libbz2-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    tk-dev \
    uuid-dev \
    zlib1g-dev \
&&  rm -rf /var/lib/apt/lists/*


FROM builder-base AS builder-dbg

COPY --from=py-src /tmp/python-src /tmp/python-src

RUN cd /tmp/python-src \
&&  ./configure --prefix=/opt/python/dbg \
      --disable-test-modules \
      --disable-ipv6 \
      --with-pydebug \
&&  make -j "$(nproc)" \
&&  make install \
&&  make clean


FROM builder-base AS builder-rel

COPY --from=py-src /tmp/python-src /tmp/python-src

RUN cd /tmp/python-src \
&&  ./configure --prefix=/opt/python/rel \
      --disable-test-modules \
      --disable-ipv6 \
&&  make -j "$(nproc)" \
&&  make install \
&&  make clean


FROM builder-base AS builder-dbg-tsan

COPY --from=py-src /tmp/python-src /tmp/python-src

ARG TSAN_OPTIONS=report_bugs=0

RUN cd /tmp/python-src \
&&  ./configure --prefix=/opt/python/dbg-tsan \
      --with-thread-sanitizer \
      --disable-test-modules \
      --disable-ipv6 \
      --with-pydebug \
&&  make -j "$(nproc)" \
&&  make install \
&&  make clean


FROM builder-base AS builder-tsan

COPY --from=py-src /tmp/python-src /tmp/python-src

ARG TSAN_OPTIONS=report_bugs=0

RUN cd /tmp/python-src \
&&  ./configure --prefix=/opt/python/tsan \
      --with-thread-sanitizer \
      --disable-test-modules \
      --disable-ipv6 \
&&  make -j "$(nproc)" \
&&  make install \
&&  make clean


FROM builder-base AS builder-dbg-xsan

COPY --from=py-src /tmp/python-src /tmp/python-src

RUN cd /tmp/python-src \
&&  ./configure --prefix=/opt/python/dbg-xsan \
      --with-address-sanitizer \
      --with-undefined-behavior-sanitizer \
      --disable-test-modules \
      --disable-ipv6 \
      --with-pydebug \
&&  make -j "$(nproc)" \
&&  make install \
&&  make clean


FROM builder-base AS builder-xsan

COPY --from=py-src /tmp/python-src /tmp/python-src

RUN cd /tmp/python-src \
&&  ./configure --prefix=/opt/python/xsan \
      --with-address-sanitizer \
      --with-undefined-behavior-sanitizer \
      --disable-test-modules \
      --disable-ipv6 \
&&  make -j "$(nproc)" \
&&  make install \
&&  make clean


ARG FINAL_OS

FROM ${FINAL_OS} AS final

COPY --from=builder-dbg /opt/python /opt/python
COPY --from=builder-rel /opt/python /opt/python
COPY --from=builder-dbg-tsan /opt/python /opt/python
COPY --from=builder-tsan /opt/python /opt/python
COPY --from=builder-dbg-xsan /opt/python /opt/python
COPY --from=builder-xsan /opt/python /opt/python

RUN /opt/python/dbg/bin/python3*d -c 'import sys, lzma; print(sys.version)'
RUN /opt/python/rel/bin/python3 -c 'import sys, lzma; print(sys.version)'
RUN /opt/python/dbg-tsan/bin/python3*d -c 'import sys, lzma; print(sys.version)'
RUN /opt/python/tsan/bin/python3 -c 'import sys, lzma; print(sys.version)'
RUN /opt/python/dbg-xsan/bin/python3*d -c 'import sys, lzma; print(sys.version)'
RUN /opt/python/xsan/bin/python3 -c 'import sys, lzma; print(sys.version)'

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='python-xsan'
