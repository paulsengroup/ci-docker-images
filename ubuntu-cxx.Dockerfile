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

RUN apt-get update -q \
&&  apt-get install -q -y curl                       \
                          dirmngr                    \
                          gpg                        \
                          software-properties-common \
&&  curl -s -L 'https://apt.kitware.com/keys/kitware-archive-latest.asc'          \
     | tee -a /etc/apt/trusted.gpg.d/kitware_ubuntu_key.asc > /dev/null           \
&&  curl -s -L 'https://apt.llvm.org/llvm-snapshot.gpg.key'                       \
     | tee -a /etc/apt/trusted.gpg.d/llvm_ubuntu_key.asc > /dev/null              \
&&  add-apt-repository -y "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"                             \
&&  add-apt-repository -y "deb https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main"     \
&&  add-apt-repository -y "deb https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-13 main"  \
&&  add-apt-repository -y "deb https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-14 main"  \
&&  add-apt-repository -y ppa:ubuntu-toolchain-r/test                                                               \
&&  apt-get remove -q -y curl                       \
                         dirmngr                    \
                         gpg                        \
                         software-properties-common \
&&  apt-get autoremove -q -y                        \
&&  rm -rf /var/lib/apt/lists/*

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&& echo CET | tee /etc/timezone > /dev/null

ARG CMAKE_VERSION

ARG COMPILER_NAME
ARG COMPILER_VERSION
ARG COMPILER="$COMPILER_NAME-$COMPILER_VERSION"

ARG CONAN_VERSION

RUN if [ $CMAKE_VERSION = "" ]; then echo "Missing CMAKE_VERSION definition" && exit 1; fi
RUN if [ $COMPILER_NAME = "" ]; then echo "Missing COMPILER_NAME definition" && exit 1; fi
RUN if [ $COMPILER_VERSION = "" ]; then echo "Missing COMPILER_VERSION definition" && exit 1; fi
RUN if [ $CONAN_VERSION = "" ]; then echo "Missing CONAN_VERSION definition" && exit 1; fi

RUN apt-get update -q                                    \
&&  apt-get install -q -y "$COMPILER"                    \
                          ccache                         \
                          "clang-tidy-$COMPILER_VERSION" \
                          cppcheck                       \
                          make                           \
                          ninja-build                    \
                          python3                        \
                          python3-pip                    \
&&  if [ $COMPILER_NAME = gcc ] ; then apt-get install -q -y "g++-${COMPILER_VERSION}"; fi \
&&  pip install "cmake==${CMAKE_VERSION}" \
                "conan==${CONAN_VERSION}" \
&&  apt-get remove -q -y python3-pip      \
&&  apt-get autoremove -q -y              \
&&  rm -rf /var/lib/apt/lists/*

RUN if [ $COMPILER_NAME = gcc ] ; then \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 100                      \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 100;                   \
fi

RUN if [ $COMPILER_NAME = clang ] ; then \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$COMPILER_VERSION 100        \
&&  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100                                \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100;                           \
fi

RUN conan profile new "$HOME/.conan/profiles/default" --detect --force          \
&&  conan config init                                                           \
&&  conan profile update settings.compiler="$COMPILER_NAME" default             \
&&  conan profile update settings.compiler.version="$COMPILER_VERSION" default  \
&&  conan profile update settings.compiler.libcxx=libstdc++11 default           \
&&  conan profile update settings.compiler.cppstd=17 default

# Add "7" to the list of known Clang versions
RUN sed -i 's/"5.0", "6.0", "7.0", "7.1",/"5.0", "6.0", "7", "7.0", "7.1",/'    \
        "$HOME/.conan/settings.yml"

FROM base as testing

RUN printf '[requires]\nfmt/8.1.1' > /tmp/conanfile.txt \
&&  conan install --build=fmt /tmp/conanfile.txt

FROM base as final

ARG CMAKE_VERSION

ARG COMPILER_NAME
ARG COMPILER_VERSION
ARG COMPILER="$COMPILER_NAME-$COMPILER_VERSION"

ARG CONAN_VERSION

ENV CC=/usr/bin/cc
ENV CXX=/usr/bin/c++

LABEL maintainer='Roberto Rossini <roberros@uio.no>'
LABEL compiler="$COMPILER"
LABEL cmake="cmake-$CMAKE_VERSION"
LABEL conan="conan-$CONAN_VERSION"

RUN cc --version
RUN c++ --version
