# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS base

ENV CONAN_V2=1
ENV CONAN_REVISIONS_ENABLED=1
ENV CONAN_NON_INTERACTIVE=1
ENV CONAN_CMAKE_GENERATOR=Ninja

ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

ARG CMAKE_VERSION

ARG COMPILER_NAME
ARG COMPILER_VERSION
ARG COMPILER="$COMPILER_NAME-$COMPILER_VERSION"

ARG CONAN_VERSION

RUN if [ -z $CMAKE_VERSION ]; then echo "Missing CMAKE_VERSION definition" && exit 1; fi
RUN if [ -z $COMPILER_NAME ]; then echo "Missing COMPILER_NAME definition" && exit 1; fi
RUN if [ -z $COMPILER_VERSION ]; then echo "Missing COMPILER_VERSION definition" && exit 1; fi
RUN if [ -z $CONAN_VERSION ]; then echo "Missing CONAN_VERSION definition" && exit 1; fi

RUN apt-get update -q                                    \
&&  apt-get install -q -y "$COMPILER"                    \
                          ccache                         \
                          clang-tidy                     \
                          cppcheck                       \
                          git                            \
                          make                           \
                          ninja-build                    \
                          python3                        \
                          python3-pip                    \
                          zstd                           \
&&  if [ $COMPILER_NAME = gcc ] ; then apt-get install -q -y "g++-${COMPILER_VERSION}"; fi \
&&  pip install "cmake==${CMAKE_VERSION}" \
                "conan==${CONAN_VERSION}" \
&&  apt-get remove -q -y python3-pip      \
&&  apt-get autoremove -q -y              \
&&  rm -rf /var/lib/apt/lists/*

RUN if [ $COMPILER_NAME = gcc ] ; then \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-$COMPILER_VERSION 100    \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-$COMPILER_VERSION 100; \
fi

RUN if [ $COMPILER_NAME = clang ] ; then \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$COMPILER_VERSION 100       \
&&  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$COMPILER_VERSION 100 \
&&  update-alternatives --install /usr/bin/cc cc /usr/bin/clang-$COMPILER_VERSION 100             \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-$COMPILER_VERSION 100;        \
fi


RUN mkdir -p /opt/conan/profiles \
&&  conan config init                                                                               \
&&  conan profile new /opt/conan/profiles/default --detect --force                                  \
&&  conan profile update settings.compiler="$COMPILER_NAME" /opt/conan/profiles/default             \
&&  conan profile update settings.compiler.version="$COMPILER_VERSION" /opt/conan/profiles/default  \
&&  conan profile update settings.compiler.cppstd=17 /opt/conan/profiles/default                    \
&&  conan profile update settings.compiler.libcxx=libstdc++11 /opt/conan/profiles/default

ENV CC=/usr/bin/cc
ENV CXX=/usr/bin/c++
ENV CONAN_DEFAULT_PROFILE_PATH=/opt/conan/profiles/default


LABEL maintainer='Roberto Rossini <roberros@uio.no>'
LABEL compiler="$COMPILER"
LABEL cmake="cmake-$CMAKE_VERSION"
LABEL conan="conan-$CONAN_VERSION"
