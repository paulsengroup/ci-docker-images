# Copyright (C) 2023 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

FROM almalinux:9 AS base

ARG PIP_NO_CACHE_DIR=0
ARG GCC_VERSION
ARG GCC_VERSION="${GCC_VERSION:-12}"

RUN dnf install -y --setopt=tsflags=nodocs \
                  gcc-toolset-$GCC_VERSION \
                  git \
                  make \
                  python39 \
                  python-pip \
&& dnf clean all --enablerepo='*'


RUN update-alternatives --install /usr/bin/cc        cc  /opt/rh/gcc-toolset-$GCC_VERSION/root/usr/bin/gcc 100 \
&& update-alternatives  --install /usr/bin/c++       c++ /opt/rh/gcc-toolset-$GCC_VERSION/root/usr/bin/g++ 100 \
&& update-alternatives  --install /usr/local/bin/gcc gcc /opt/rh/gcc-toolset-$GCC_VERSION/root/usr/bin/gcc 100 \
&& update-alternatives  --install /usr/local/bin/g++ g++ /opt/rh/gcc-toolset-$GCC_VERSION/root/usr/bin/g++ 100

ARG CONAN_VERSION
ARG CMAKE_VERSION
ARG CONAN_VERSION="${CONAN_VERSION:-2.0.*}"
ARG CMAKE_VERSION="${CMAKE_VERSION:-3.26.*}"

RUN python3 -m venv /opt/venv --upgrade \
&& /opt/venv/bin/pip install \
                 "cmake==${CMAKE_VERSION}" \
                 "conan==${CONAN_VERSION}"

ENV CC=/usr/bin/cc
ENV CXX=/usr/bin/c++
ENV CONAN_DEFAULT_PROFILE_PATH=/opt/conan/profiles/default
ENV PATH="/opt/venv/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/venv/lib:$LD_LIBRARY_PATH"

RUN mkdir -p /opt/conan/profiles \
&& CC=gcc  \
   CXX=g++ \
   conan profile detect --force                                        \
&& mv "$HOME/.conan2/profiles/default" "$CONAN_DEFAULT_PROFILE_PATH"   \
&& sed -i '/^compiler\.libcxx.*$/d' "$CONAN_DEFAULT_PROFILE_PATH"      \
&& echo 'compiler.libcxx=libstdc++11' >> "$CONAN_DEFAULT_PROFILE_PATH" \
&& cat "$CONAN_DEFAULT_PROFILE_PATH"

ARG CCACHE_VERSION
ARG CCACHE_SHA256
ARG CCACHE_VERSION="${CCACHE_VERSION:-4.8}"
ARG CCACHE_SHA256="${CCACHE_SHA256:-b963ee3bf88d7266b8a0565e4ba685d5666357f0a7e364ed98adb0dc1191fcbb}"

ARG CCACHE_URL="https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION.tar.xz"


# Download and install ccache
RUN curl -LO "$CCACHE_URL" \
&& echo "$CCACHE_SHA256  ccache-$CCACHE_VERSION.tar.xz" > "ccache-$CCACHE_VERSION.sha256" \
&& sha256sum -c "ccache-$CCACHE_VERSION.sha256" \
&& tar -xf "ccache-$CCACHE_VERSION.tar.xz" \
&& cd "ccache-$CCACHE_VERSION/" \
&& printf '[requires]\nzstd/1.5.5\nhiredis/1.1.0\n' > conanfile.txt \
&& printf '[generators]\nCMakeToolchain\n' >> conanfile.txt \
&& conan install conanfile.txt \
        --build=missing \
        -pr:b="$CONAN_DEFAULT_PROFILE_PATH" \
        -pr:h="$CONAN_DEFAULT_PROFILE_PATH" \
        --output-folder=build/ \
&& cmake -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake \
         -DSTATIC_LINK_DEFAULT=ON \
         -DHIREDIS_FROM_INTERNET=OFF \
         -DZSTD_FROM_INTERNET=OFF \
         -DENABLE_TESTING=OFF \
         -DENABLE_DOCUMENTATION=OFF \
         -DCMAKE_BUILD_TYPE=Release \
         -S . \
         -B build/ \
&& cmake --build build -j $(nproc) \
&& cmake --install build \
&& conan cache clean "*" --build \
&& conan cache clean "*" --download \
&& conan cache clean "*" --source \
&& conan remove --confirm "*" \
&& rm -rf "$PWD"

RUN ccache --version
RUN cc --version
RUN c++ --version
RUN gcc --version
RUN g++ --version


# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='almalinux9-cxx'
