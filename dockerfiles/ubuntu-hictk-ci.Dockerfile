# Copyright (C) 2024 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT


ARG HICTK_VERSION
ARG HICTK_VERSION="${HICTK_VERSION:-0.0.10}"
FROM ghcr.io/paulsengroup/hictk:${HICTK_VERSION} as hictk

ARG BASE_OS
FROM ubuntu:24.04 AS base

ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

ARG COOLER_VERSION
ARG PYTHON_VERSION
ARG COOLER_VERSION="${COOLER_VERSION:-0.9.3}"

RUN if [ -z $PYTHON_VERSION ]; then echo "Missing PYTHON_VERSION definition" && exit 1; fi
ARG PYTHON="python${PYTHON_VERSION}"

RUN apt-get update -q                              \
&&  apt-get install -q -y --no-install-recommends  \
                          gcc                      \
                          libasan8                 \
                          libpython$PYTHON_VERSION \
                          libtsan2                 \
                          libubsan1                \
                          pkg-config               \
                          ${PYTHON}-venv           \
                          ${PYTHON}-dev            \
                          xz-utils                 \
                          zlib1g-dev               \
                          zstd                     \
&& ${PYTHON} -m venv /opt/venv --upgrade    \
&& /opt/venv/bin/pip install --upgrade      \
               pip                          \
               setuptools                   \
               wheel                        \
&& /opt/venv/bin/pip install                \
                "cooler==${COOLER_VERSION}" \
&& apt-get remove -q -y gcc                 \
                        pkg-config          \
                        ${PYTHON}-dev       \
                        zlib1g-dev          \
&& apt-get autoremove -q -y                 \
&& rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/$PYTHON 100
ENV PATH="/opt/venv/bin:$PATH"

COPY --from=hictk /usr/local/bin/hictk /usr/local/bin/

RUN python3 -c 'import cooler'
RUN cooler --version
RUN hictk --version

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='ubuntu-hictk-ci'
