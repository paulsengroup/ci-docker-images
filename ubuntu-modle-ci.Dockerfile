# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS base

ARG BASE_OS
ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

RUN if ! echo "$BASE_OS" | grep -q 'ubuntu-22.04' 2> /dev/null; then \
    apt-get update -q \
&&  apt-get install -q -y curl                       \
                          dirmngr                    \
                          gpg                        \
                          software-properties-common \
&&  curl -s -L 'https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc' \
     | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc > /dev/null              \
&&  add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
&&  add-apt-repository -y ppa:c2d4u.team/c2d4u4.0+                                                      \
&&  apt-get remove -q -y curl                       \
                         dirmngr                    \
                         gpg                        \
                         software-properties-common \
&&  apt-get autoremove -q -y                        \
&&  rm -rf /var/lib/apt/lists/* ;                   \
fi

RUN apt-get update -q                          \
&&  apt-get install -q -y python3-scipy        \
                          r-base               \
                          r-base-dev           \
                          r-cran-minqa         \
                          r-cran-mnormt        \
                          r-cran-rcpparmadillo \
&&  echo "options(Ncpus = $(nproc))" | tee /etc/R/Rprofile.site > /dev/null  \
&&  mv /etc/R/Makeconf /etc/R/Makeconf.old                                   \
    | sed -E "s|=\s+gcc|= $(which gcc)|g" /etc/R/Makeconf.old                \
    | sed -E "s|=\s+g[+]{2}|= $(which g++)|g"                                \
    | sed -E "s|=\s+gfortran|= $(which gfortran)|g" > /etc/R/Makeconf        \
&&  echo "MAKEFLAGS = -j$(nproc)" >> /etc/R/Makeconf                         \
&&  rm /etc/R/Makeconf.old \
&&  Rscript --no-save -e 'install.packages("wCorr", dependencies=c("Depends", "Imports", "LinkingTo"), repos="https://cloud.r-project.org")' \
&&  apt-get remove -q -y r-base-dev  \
&&  apt-get autoremove -q -y         \
&&  rm -rf /var/lib/apt/lists/*


LABEL maintainer='Roberto Rossini <roberros@uio.no>'
