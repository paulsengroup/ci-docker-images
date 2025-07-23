# Copyright (C) 2025 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT


ARG BASE_OS=alpine:3.22

FROM $BASE_OS AS base

ENV CONAN_CMAKE_GENERATOR=Ninja
ARG PIP_NO_CACHE_DIR=0

RUN apk add --no-cache \
    bash \
    ccache \
    clang20-dev \
    clang20-extra-tools \
    clang20-static \
    compiler-rt \
    cppcheck \
    git \
    libc++-dev \
    libc++-static \
    linux-headers \
    lld20 \
    llvm-libunwind-dev \
    llvm-libunwind-static \
    m4 \
    make \
    ninja \
    patch \
    perl \
    py3-pip \
    python3 \
    xz \
    zstd

ARG CMAKE_VERSION='2.18.*'
ARG CONAN_VERSION='4.0.*'

RUN if [ -z $CMAKE_VERSION ]; then echo "Missing CMAKE_VERSION definition" && exit 1; fi
RUN if [ -z $CONAN_VERSION ]; then echo "Missing CONAN_VERSION definition" && exit 1; fi

RUN python3 -m venv /opt/venv --upgrade    \
&&  /opt/venv/bin/pip install --upgrade    \
                pip                        \
                setuptools                 \
                wheel                      \
&&  /opt/venv/bin/pip install              \
                 "cmake==${CMAKE_VERSION}" \
                 "conan==${CONAN_VERSION}"

ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++
ENV CONAN_DEFAULT_PROFILE_PATH=/opt/conan/profiles/default
ENV PATH="/opt/venv/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/venv/lib:$LD_LIBRARY_PATH"

# Populate Conan data
RUN mkdir "$HOME/.conan2/" \
&& conan --help

COPY assets/settings.yml /root/.conan2/settings.yml

RUN ln -s "$HOME/.conan2/" /opt/conan
RUN conan profile detect --force &> /dev/null

RUN sed -i 's/^compiler\.libcxx.*$/compiler.libcxx=libc++/' "$CONAN_DEFAULT_PROFILE_PATH" \
&& cat "$CONAN_DEFAULT_PROFILE_PATH"

RUN printf '#include <iostream>\nint main(){ std::cout << "test\\n"; }' > /tmp/test.cpp \
&&  "$CXX" -fsanitize=address /tmp/test.cpp -o /tmp/test \
&&  if ldd /tmp/test | grep -qF 'not found'; then \
       ldd /tmp/test; exit 1; \
    fi \
&&  rm /tmp/test*

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='alpine-cxx'
LABEL cmake="cmake-$CMAKE_VERSION"
LABEL conan="conan-$CONAN_VERSION"
