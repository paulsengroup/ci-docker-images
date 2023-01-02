# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS base

ARG BASE_OS
ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

ARG COOLER_VERSION='0.8.11'
ARG NUMPY_VERSION='<1.24'

RUN apt-get update -q                             \
&&  apt-get install -q -y --no-install-recommends \
                          gcc                     \
                          python3                 \
                          python3-dev             \
                          python3-pip             \
&&  CC=/usr/bin/gcc                               \
    pip install cython                            \
                "numpy$NUMPY_VERSION"             \
&&  CC=/usr/bin/gcc                               \
    pip install "cooler==$COOLER_VERSION"         \
&&  pip uninstall -y cython                       \
&&  apt-get remove -q -y gcc                      \
                         python3-dev              \
                         python3-pip              \
&&  apt-get autoremove -q -y                      \
&&  rm -rf /var/lib/apt/lists/*

RUN python3 -c 'import cooler'
RUN cooler --version

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='ubuntu-modle-ci'
