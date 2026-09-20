# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS=ubuntu:26.04

# curl -sSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --show-keys
# curl -sSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --show-keys
ARG APT_LLVM_ORG_GPG_SIGNATURE=6084F3CF814B57C1CF12EFD515CF4D18AF4F7421
ARG GITHUB_CLI_GPG_SIGNATURE=7F38BBB59D064DBCB3D84D725612B36462313325

FROM $BASE_OS AS update-apt-src

ARG BASE_OS
ARG APT_LLVM_ORG_GPG_SIGNATURE
ARG GITHUB_CLI_GPG_SIGNATURE

RUN apt-get update -q \
&&  apt-get install -y ca-certificates gnupg lsb-release \
&&  rm -rf /var/lib/apt/lists/* \
&&  mkdir -p "$HOME/.gnupg" \
&&  chmod 600 "$HOME/.gnupg"

RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${APT_LLVM_ORG_GPG_SIGNATURE}" \
 && gpg --batch --export "${APT_LLVM_ORG_GPG_SIGNATURE}" > /usr/share/keyrings/apt.llvm.org.gpg \
 && chmod 644 /usr/share/keyrings/apt.llvm.org.gpg

RUN mkdir -p /usr/share/keyrings/github \
 && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${GITHUB_CLI_GPG_SIGNATURE}" \
 && gpg --batch --export "${GITHUB_CLI_GPG_SIGNATURE}" > /usr/share/keyrings/github-cli-archive-keyring.gpg \
 && chmod 644 /usr/share/keyrings/github-cli-archive-keyring.gpg

# Configure https://apt.llvm.org/
RUN if [ "$BASE_OS" = 'ubuntu:22.04' ] ; then \
    echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-16 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-16 main" >> /etc/apt/sources.list; \
fi

RUN if [ "$BASE_OS" != 'ubuntu:26.04' ] ; then \
    echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-17 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-17 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-18 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-18 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-19 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-19 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-20 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-20 main" >> /etc/apt/sources.list; \
fi

RUN echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-21 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-21 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-22 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-22 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-23 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-23 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main"        >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main"    >> /etc/apt/sources.list

# Configure https://cli.github.com/
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/github-cli-archive-keyring.gpg] https://cli.github.com/packages stable main" >> /etc/apt/sources.list

RUN apt-get update -q

FROM $BASE_OS AS base

ARG PIP_NO_CACHE_DIR=0
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

COPY --from=update-apt-src /etc/apt/sources.list /etc/apt/sources.list
COPY --from=update-apt-src /usr/share/keyrings/* /usr/share/keyrings/

RUN apt-get update -q || true                      \
&&  apt-get install -y ca-certificates             \
&&  apt-get update -q                              \
&&  apt-get install -q -y --no-install-recommends  \
                          cppcheck                 \
                          git                      \
                          lsb-release              \
                          make                     \
                          ninja-build              \
                          patch                    \
                          xz-utils                 \
                          zstd                     \
&&  rm -rf /var/lib/apt/lists/*

ARG PYTHON_VERSION=3.14

ARG PYTHON="python${PYTHON_VERSION}"

RUN apt-get update -q                              \
&&  apt-get install -q -y --no-install-recommends  \
                          python-is-python3        \
                          "${PYTHON}"              \
                          "${PYTHON}-venv"         \
&&  rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/$PYTHON 100

ARG CMAKE_VERSION="4.4.*"
ARG CONAN_VERSION="2.32.*"

RUN python3 -m venv /opt/venv --upgrade    \
&&  /opt/venv/bin/pip install --upgrade    \
                pip                        \
                setuptools                 \
                wheel                      \
&&  /opt/venv/bin/pip install              \
                 "cmake==${CMAKE_VERSION}" \
                 "conan==${CONAN_VERSION}"

ARG COMPILER_NAME=clang
ARG COMPILER_VERSION=23
ARG COMPILER="$COMPILER_NAME-$COMPILER_VERSION"

RUN if [ $COMPILER_NAME = gcc ] ; then \
      apt-get update -q && apt-get install -q -y \
        -t "llvm-toolchain-$(lsb_release -cs)-23" \
        clang-tidy-23 \
        "g++-${COMPILER_VERSION}" \
        libc++abi-23-dev \
        libc++-23-dev \
        libunwind-23-dev \
        lld-23 \
    && rm -rf /var/lib/apt/lists/*; \
fi

RUN if [ $COMPILER_NAME = clang ] ; then \
    apt-get update -q && apt-get install -q -y \
      -t "llvm-toolchain-$(lsb_release -cs)-${COMPILER_VERSION}" \
      "clang-tidy-${COMPILER_VERSION}" \
      "libc++abi-${COMPILER_VERSION}-dev" \
      "libc++-${COMPILER_VERSION}-dev" \
      "lld-${COMPILER_VERSION}" \
      "llvm-${COMPILER_VERSION}" \
    && rm -rf /var/lib/apt/lists/*; \
fi

RUN if echo "$COMPILER" | grep -Eq '^clang-(1[2-9]|2[0-3])$'; then \
    apt-get update -q && apt-get install -q -y \
      -t "llvm-toolchain-$(lsb_release -cs)-${COMPILER_VERSION}" \
      "libunwind-${COMPILER_VERSION}-dev" \
    && rm -rf /var/lib/apt/lists/*; \
fi

RUN if echo "$COMPILER" | grep -Eq '^clang-(1[4-9]|2[0-3])$'; then \
    apt-get update -q && apt-get install -q -y \
      -t "llvm-toolchain-$(lsb_release -cs)-${COMPILER_VERSION}" \
      "libclang-rt-${COMPILER_VERSION}-dev" \
    && rm -rf /var/lib/apt/lists/*; \
fi

ENV CC=/usr/bin/cc
ENV CXX=/usr/bin/c++
ENV CONAN_DEFAULT_PROFILE_PATH=/opt/conan/profiles/default
ENV PATH="/opt/venv/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/venv/lib:$LD_LIBRARY_PATH"

# Populate Conan data
RUN mkdir "$HOME/.conan2/" \
&& conan --help

COPY assets/settings.yml /root/.conan2/settings.yml

RUN ln -s "$HOME/.conan2/" /opt/conan

RUN if [ $COMPILER_NAME = gcc ] ; then \
    CC=gcc-$COMPILER_VERSION  \
    CXX=g++-$COMPILER_VERSION \
    conan profile detect --force                                                          \
&&  update-alternatives --install /usr/bin/gcc  gcc  /usr/bin/gcc-$COMPILER_VERSION  100  \
&&  update-alternatives --install /usr/bin/g++  g++  /usr/bin/g++-$COMPILER_VERSION  100  \
&&  update-alternatives --install /usr/bin/cc   cc   /usr/bin/gcc-$COMPILER_VERSION  100  \
&&  update-alternatives --install /usr/bin/c++  c++  /usr/bin/g++-$COMPILER_VERSION  100  \
&&  update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/ld   ld   /usr/bin/ld.lld-23              100  \
&&  update-alternatives --install /usr/bin/lld  lld  /usr/bin/lld-23                 100; \
fi

RUN if [ $COMPILER_NAME = clang ] ; then \
    CC=clang-$COMPILER_VERSION    \
    CXX=clang++-$COMPILER_VERSION \
    conan profile detect --force; \
    for bin in /usr/bin/clang* /usr/bin/llvm*; do \
      update-alternatives --install "${bin%-$COMPILER_VERSION}" "$(basename "$bin" "-$COMPILER_VERSION")" "$bin" 100; \
    done; \
    update-alternatives --install /usr/bin/cc  cc  /usr/bin/clang-$COMPILER_VERSION   100  \
&&  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-$COMPILER_VERSION 100  \
&&  update-alternatives --install /usr/bin/ld  ld  /usr/bin/ld.lld-$COMPILER_VERSION  100  \
&&  update-alternatives --install /usr/bin/lld lld /usr/bin/lld-$COMPILER_VERSION     100; \
fi

RUN sed -i '/^compiler\.libcxx.*$/d' "$CONAN_DEFAULT_PROFILE_PATH"      \
&&  echo 'compiler.libcxx=libstdc++11' >> "$CONAN_DEFAULT_PROFILE_PATH" \
&&  cat "$CONAN_DEFAULT_PROFILE_PATH"

RUN printf '#include <iostream>\nint main(){ std::cout << "test\\n"; }' > /tmp/test.cpp \
&&  "$CXX" -fsanitize=address /tmp/test.cpp -o /tmp/test \
&&  if ldd /tmp/test | grep -qF 'not found'; then \
       ldd /tmp/test; exit 1; \
    fi \
&&  rm /tmp/test*


FROM ubuntu:22.04 AS ccache-builder

ARG CCACHE_VER=4.14
ARG DEBIAN_FRONTEND=noninteractive
ARG PIP_NO_CACHE_DIR=0
ARG CLANG_VERSION=23
ENV TZ=Etc/UTC
ARG PYTHON="python3.10"

ARG PYTHON_VENV=/tmp/venv
ARG PATH="$PYTHON_VENV/bin:$PATH"

RUN apt-get update -q || true \
&&  apt-get install -y ca-certificates \
&&  apt-get install -y ca-certificates curl gnupg lsb-release \
&& rm -rf /var/lib/apt/lists/*

COPY --from=update-apt-src /usr/share/keyrings/* /usr/share/keyrings/

# Configure https://apt.llvm.org/
RUN echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-${CLANG_VERSION} main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-${CLANG_VERSION} main" >> /etc/apt/sources.list

RUN apt-get update -q || true \
&&  apt-get install -y ca-certificates \
&&  apt-get update -q \
&&  apt-get install -y \
    cmake \
    curl \
    "clang-${CLANG_VERSION}" \
    "clang++-${CLANG_VERSION}" \
    elfutils \
    python-is-python3 \
    "${PYTHON}" \
    "${PYTHON}-venv" \
    xz-utils \
&& rm -rf /var/lib/apt/lists/*

RUN "/usr/bin/python" -m venv "$PYTHON_VENV" --upgrade \
&&  "$PYTHON_VENV/bin/pip" install 'cmake>=3.18'

RUN curl -L "https://github.com/ccache/ccache/releases/download/v$CCACHE_VER/ccache-$CCACHE_VER.tar.xz" | tar -xJf -

RUN cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_COMPILER="clang-${CLANG_VERSION}" \
          -DCMAKE_CXX_COMPILER="clang++-${CLANG_VERSION}" \
          -DENABLE_TESTING=ON \
          -DREDIS_STORAGE_BACKEND=OFF \
          -DDEPS=DOWNLOAD \
          -DSTATIC_LINK=ON \
          -DCMAKE_INSTALL_PREFIX=/tmp/ccache/ \
          -S "ccache-$CCACHE_VER/" \
          -B /tmp/build

RUN cmake --build /tmp/build -j "$(nproc)"

# Some tests require gcc and g++
RUN apt-get update -q \
&&  apt-get install -y gcc g++ \
&& rm -rf /var/lib/apt/lists/*

RUN cd /tmp/build/ \
&&  ctest --output-on-failure -j "$(nproc)"

RUN cmake --install /tmp/build

FROM base AS final

COPY --from=ccache-builder /tmp/ccache/bin/ccache /usr/local/bin/ccache

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors='Roberto Rossini'
LABEL org.opencontainers.image.url='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.documentation='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.source='https://github.com/paulsengroup/ci-docker-images'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='ubuntu-cxx'
LABEL compiler="$COMPILER"
LABEL cmake="cmake-$CMAKE_VERSION"
LABEL conan="conan-$CONAN_VERSION"
