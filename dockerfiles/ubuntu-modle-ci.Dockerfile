# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS base

ARG BASE_OS
ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

ARG COOLER_VERSION
ARG PYBIGWIG_VERSION
ARG COOLER_VERSION="${COOLER_VERSION:-0.9.1}"
ARG PYBIGWIG_VERSION="${PYBIGWIG_VERSION:-0.3.22}"

RUN apt-get update -q                             \
&&  apt-get install -q -y --no-install-recommends \
                          gcc                     \
                          python3-distutils       \
&&  /opt/venv/bin/pip install                     \
                "cooler==$COOLER_VERSION"         \
                "pyBigWig==$PYBIGWIG_VERSION"     \
&&  apt-get remove -q -y gcc                      \
                         python3-distutils        \
&&  apt-get autoremove -q -y                      \
&&  rm -rf /var/lib/apt/lists/*

RUN python3 -c 'import cooler, pyBigWig'
RUN cooler --version

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='ubuntu-modle-ci'
