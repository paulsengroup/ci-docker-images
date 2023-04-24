# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

FROM centos:7 AS base

ARG PIP_NO_CACHE_DIR=0

# Install gcc-11, git-2.27 and python3
RUN yum install -y centos-release-scl \
&& yum install -y --setopt=tsflags=nodocs \
                  devtoolset-11 \
                  rh-git227 \
                  python3 \
&& yum clean all --enablerepo='*'


RUN update-alternatives --install /usr/bin/cc        cc  /opt/rh/devtoolset-11/root/usr/bin/gcc 100 \
&& update-alternatives  --install /usr/bin/c++       c++ /opt/rh/devtoolset-11/root/usr/bin/g++ 100 \
&& update-alternatives  --install /usr/local/bin/gcc gcc /opt/rh/devtoolset-11/root/usr/bin/gcc 100 \
&& update-alternatives  --install /usr/local/bin/g++ g++ /opt/rh/devtoolset-11/root/usr/bin/g++ 100 \
&& update-alternatives  --install /usr/bin/git       git /opt/rh/rh-git227/root/usr/bin/git     100

ARG CCACHE_VERSION
ARG CCACHE_SHA256
ARG CCACHE_VERSION="${CCACHE_VERSION:-4.8}"
ARG CCACHE_SHA256="${CCACHE_SHA256:-3b35ec9e8af0f849e66e7b5392e2d436d393adbb0574b7147b203943258c6205}"

ARG CCACHE_URL="https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION-linux-x86_64.tar.xz"

# Download and install ccache
RUN curl -LO "$CCACHE_URL" \
&& echo "$CCACHE_SHA256  ccache-$CCACHE_VERSION-linux-x86_64.tar.xz" > "ccache-$CCACHE_VERSION-linux-x86_64.sha256" \
&& sha256sum -c "ccache-$CCACHE_VERSION-linux-x86_64.sha256" \
&& tar -xf "ccache-$CCACHE_VERSION-linux-x86_64.tar.xz" \
&& make -C "ccache-$CCACHE_VERSION-linux-x86_64" install \
&& rm -rf "ccache-$CCACHE_VERSION-linux-x86_64"*

RUN ccache --version

# Install CMake and Conan
RUN pip3 install --upgrade pip  \
&& pip3 install 'cmake>=3.20'   \
                'conan==2.0.*'

ENV CC=/usr/bin/cc
ENV CXX=/usr/bin/c++
ENV CONAN_DEFAULT_PROFILE_PATH=/opt/conan/profiles/default

# Init conan profile
RUN mkdir -p /opt/conan/profiles \
&& CC=gcc  \
   CXX=g++ \
   conan profile detect --force                                        \
&& mv "$HOME/.conan2/profiles/default" "$CONAN_DEFAULT_PROFILE_PATH"   \
&& sed -i '/^compiler\.libcxx.*$/d' "$CONAN_DEFAULT_PROFILE_PATH"      \
&& echo 'compiler.libcxx=libstdc++11' >> "$CONAN_DEFAULT_PROFILE_PATH" \
&& cat "$CONAN_DEFAULT_PROFILE_PATH"

RUN cc --version
RUN c++ --version
RUN gcc --version
RUN g++ --version


ENV LD_LIBRARY_PATH="/opt/rh/httpd24/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='centos7-cxx'
