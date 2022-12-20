# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS base

ARG BASE_OS
ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

ARG WCORR_VERSION='1.9.5'
ARG RSCRIPT_INSTALL_STR="install.packages('wCorr', version='$WCORR_VERSION', dependencies=c('Depends', 'Imports', 'LinkingTo'), repos='https://cloud.r-project.org')"

RUN apt-get update -q                             \
&&  apt-get install -q -y --no-install-recommends \
                          r-base                  \
                          r-base-dev              \
                          r-cran-minqa            \
                          r-cran-mnormt           \
                          r-cran-rcpparmadillo    \
&&  echo "options(Ncpus = $(nproc))" | tee /etc/R/Rprofile.site > /dev/null  \
&&  sed -iE "s|=\s+gcc|= $(which gcc)|g" /etc/R/Makeconf                     \
&&  sed -iE "s|=\s+g[+]{2}|= $(which g++)|g" /etc/R/Makeconf                 \
&&  sed -iE "s|=\s+gfortran|= $(which gfortran)|g" /etc/R/Makeconf           \
&&  echo "MAKEFLAGS = -j$(nproc)" >> /etc/R/Makeconf                         \
&&  Rscript --no-save -e "$RSCRIPT_INSTALL_STR" \
&&  apt-get remove -q -y r-base-dev             \
&&  apt-get autoremove -q -y                    \
&&  rm -rf /var/lib/apt/lists/*


ARG COOLER_VERSION='0.8.11'
ARG SCIPY_VERSION='>=1.9'
ARG NUMPY_VERSION='<1.24'

RUN apt-get update -q                             \
&&  apt-get install -q -y --no-install-recommends \
                          gcc                     \
                          python3                 \
                          python3-dev             \
                          python3-pip             \
&&  pip3 install "cooler==$COOLER_VERSION"        \
                  cython                          \
                 "numpy$NUMPY_VERSION"            \
                 "scipy$SCIPY_VERSION"            \
&&  pip uninstall -y cython                       \
&&  apt-get remove -q -y gcc                      \
                         python3-dev              \
                         python3-pip              \
&&  apt-get autoremove -q -y                      \
&&  rm -rf /var/lib/apt/lists/*


# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='ubuntu-modle-ci'
