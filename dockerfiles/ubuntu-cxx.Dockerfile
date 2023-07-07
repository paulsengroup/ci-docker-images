# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS update-apt-src
RUN apt-get update \
&&  apt-get install -y curl gnupg lsb-release

RUN echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main" >> /etc/apt/sources.list
RUN echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main" >> /etc/apt/sources.list
RUN echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-15 main" >> /etc/apt/sources.list
RUN echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-15 main" >> /etc/apt/sources.list
RUN echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-16 main" >> /etc/apt/sources.list
RUN echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-16 main" >> /etc/apt/sources.list

RUN curl -L 'https://apt.llvm.org/llvm-snapshot.gpg.key' | gpg --dearmor > /usr/share/keyrings/apt.llvm.org.gpg \
&&  chmod 644 /usr/share/keyrings/apt.llvm.org.gpg


FROM $BASE_OS AS base

ENV CONAN_CMAKE_GENERATOR=Ninja
ARG PIP_NO_CACHE_DIR=0

RUN ln -snf /usr/share/zoneinfo/CET /etc/localtime \
&&  echo CET | tee /etc/timezone > /dev/null


RUN apt-get update -q                              \
&&  apt-get install -q -y --no-install-recommends  \
                          ca-certificates          \
&&  rm -rf /var/lib/apt/lists/*

COPY --from=update-apt-src /etc/apt/sources.list /etc/apt/sources.list
COPY --from=update-apt-src /usr/share/keyrings/apt.llvm.org.gpg /usr/share/keyrings/apt.llvm.org.gpg

ARG COMPILER_NAME
ARG COMPILER_VERSION
ARG COMPILER="$COMPILER_NAME-$COMPILER_VERSION"

ARG PYTHON_VERSION

RUN if [ -z $COMPILER_NAME ]; then echo "Missing COMPILER_NAME definition" && exit 1; fi
RUN if [ -z $COMPILER_VERSION ]; then echo "Missing COMPILER_VERSION definition" && exit 1; fi
RUN if [ -z $PYTHON_VERSION ]; then echo "Missing PYTHON_VERSION definition" && exit 1; fi

ARG PYTHON="python${PYTHON_VERSION}"

RUN apt-get update -q                              \
&&  apt-get install -y ca-certificates             \
&&  apt-get update -q                              \
&&  apt-get install -q -y --no-install-recommends  \
                          "$COMPILER"              \
                          ccache                   \
                          cppcheck                 \
                          git                      \
                          make                     \
                          ninja-build              \
                          ${PYTHON}                \
                          ${PYTHON}-venv           \
                          xz-utils                 \
                          zstd                     \
&&  if [ $COMPILER_NAME = gcc ] ; then apt-get install -q -y clang-tidy "g++-${COMPILER_VERSION}" lld; fi \
&&  if [ $COMPILER_NAME = clang ] ; then apt-get install -q -y "clang-tidy-${COMPILER_VERSION}" "lld-${COMPILER_VERSION}" "llvm-${COMPILER_VERSION}"; fi \
&&  rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/$PYTHON 100

ARG CMAKE_VERSION
ARG CONAN_VERSION

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

ENV CC=/usr/bin/cc
ENV CXX=/usr/bin/c++
ENV CONAN_DEFAULT_PROFILE_PATH=/opt/conan/profiles/default
ENV PATH="/opt/venv/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/venv/lib:$LD_LIBRARY_PATH"

RUN if [ $COMPILER_NAME = gcc ] ; then \
    CC=gcc-$COMPILER_VERSION  \
    CXX=g++-$COMPILER_VERSION \
    conan profile detect --force                                                       \
&&  mkdir -p /opt/conan/profiles                                                       \
&&  mv "$HOME/.conan2/profiles/default" /opt/conan/profiles/default                    \
&&  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-$COMPILER_VERSION 100    \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/ld ld /usr/bin/lld 100;                     \
fi

RUN if [ $COMPILER_NAME = clang ] ; then \
    CC=clang-$COMPILER_VERSION    \
    CXX=clang++-$COMPILER_VERSION \
    conan profile detect --force                                                                           \
&&  mkdir -p /opt/conan/profiles                                                                           \
&&  mv "$HOME/.conan2/profiles/default" "$CONAN_DEFAULT_PROFILE_PATH"                                      \
&&  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$COMPILER_VERSION 100                \
&&  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$COMPILER_VERSION 100          \
&&  update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-$COMPILER_VERSION 100 \
&&  update-alternatives --install /usr/bin/cc cc /usr/bin/clang-$COMPILER_VERSION 100                      \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-$COMPILER_VERSION 100                  \
&&  update-alternatives --install /usr/bin/ld ld /usr/bin/lld-$COMPILER_VERSION 100;                       \
fi

RUN sed -i '/^compiler\.libcxx.*$/d' "$CONAN_DEFAULT_PROFILE_PATH"      \
&&  echo 'compiler.libcxx=libstdc++11' >> "$CONAN_DEFAULT_PROFILE_PATH" \
&&  cat "$CONAN_DEFAULT_PROFILE_PATH"

ARG MOLD_VERSION='1.11.0'
ARG MOLD_X86_URL="https://github.com/rui314/mold/releases/download/v$MOLD_VERSION/mold-$MOLD_VERSION-x86_64-linux.tar.gz"
ARG MOLD_X86_SHA256_STR="bf788940db4a9ac19e7745c821bf6ee18ff4d75441a803d84f86c9f3b0aa2a5e  mold-$MOLD_VERSION-x86_64-linux.tar.gz"
ARG MOLD_ARM_URL="https://github.com/rui314/mold/releases/download/v$MOLD_VERSION/mold-$MOLD_VERSION-arm-linux.tar.gz"
ARG MOLD_ARM_SHA256_STR="f9a57b03ddfe0d4259b8859cc5163dff313f4d706f07c88c9e3cfa2390e66e38  mold-$MOLD_VERSION-arm-linux.tar.gz"

RUN apt-get update \
&& apt-get install -q -y --no-install-recommends curl \
&& cd /tmp \
&& if [ $(uname -m) = x86_64 ] ; then \
&& curl -LO "$MOLD_X86_URL" \
&& echo "$MOLD_X86_SHA256_STR" >> mold.sha256; \
else \
&& curl -LO "$MOLD_ARM_URL" \
&& echo "$MOLD_ARM_SHA256_STR" >> mold.sha256; \
fi \
&& sha256sum -c mold.sha256 \
&& tar -xf "mold-$MOLD_VERSION"-*.tar.gz \
       -C /usr/local \
       --strip-components=1 \
&& apt-get remove -y curl \
&& rm -rf /tmp/mold* /var/lib/apt/lists/*

RUN if [ $COMPILER_NAME = clang ] ; then ln -sf "/usr/bin/llvm-symbolizer-${COMPILER_VERSION}" /usr/local/bin/llvm-symbolizer; fi


# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini <roberros@uio.no>'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='ubuntu-ci'
LABEL compiler="$COMPILER"
LABEL cmake="cmake-$CMAKE_VERSION"
LABEL conan="conan-$CONAN_VERSION"
