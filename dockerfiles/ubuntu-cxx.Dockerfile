# Copyright (C) 2022 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

ARG BASE_OS

FROM $BASE_OS AS update-apt-src

ARG BASE_OS

RUN apt-get update -q \
&&  apt-get install -y ca-certificates curl gnupg lsb-release

RUN curl -L 'https://apt.llvm.org/llvm-snapshot.gpg.key' | gpg --dearmor > /usr/share/keyrings/apt.llvm.org.gpg \
&&  curl -L 'https://cli.github.com/packages/githubcli-archive-keyring.gpg' -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
&&  chmod 644 /usr/share/keyrings/*.gpg

# Configure https://apt.llvm.org/
RUN if [ "$BASE_OS" = 'ubuntu:22.04' ] ; then \
    echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-16 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-16 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-17 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-17 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-18 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-18 main" >> /etc/apt/sources.list; \
fi

RUN echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main"        >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main"    >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-19 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-19 main" >> /etc/apt/sources.list  \
&&  echo "deb [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-20 main"     >> /etc/apt/sources.list  \
&&  echo "deb-src [signed-by=/usr/share/keyrings/apt.llvm.org.gpg] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-20 main" >> /etc/apt/sources.list

# Configure https://cli.github.com/
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >> /etc/apt/sources.list

RUN apt-get update -q

FROM $BASE_OS AS base

ENV CONAN_CMAKE_GENERATOR=Ninja
ARG PIP_NO_CACHE_DIR=0
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

COPY --from=update-apt-src /etc/apt/sources.list /etc/apt/sources.list
COPY --from=update-apt-src /usr/share/keyrings/* /usr/share/keyrings/

ARG COMPILER_NAME
ARG COMPILER_VERSION
ARG COMPILER="$COMPILER_NAME-$COMPILER_VERSION"

ARG PYTHON_VERSION

RUN if [ -z $COMPILER_NAME ]; then echo "Missing COMPILER_NAME definition" && exit 1; fi
RUN if [ -z $COMPILER_VERSION ]; then echo "Missing COMPILER_VERSION definition" && exit 1; fi
RUN if [ -z $PYTHON_VERSION ]; then echo "Missing PYTHON_VERSION definition" && exit 1; fi

ARG PYTHON="python${PYTHON_VERSION}"

RUN apt-get update -q || true                      \
&&  apt-get install -y ca-certificates             \
&&  apt-get update -q                              \
&&  apt-get install -q -y --no-install-recommends  \
                          "$COMPILER"              \
                          cppcheck                 \
                          git                      \
                          make                     \
                          ninja-build              \
                          patch                    \
                          "${PYTHON}"              \
                          "${PYTHON}-venv"         \
                          xz-utils                 \
                          zstd                     \
&&  if [ $COMPILER_NAME = gcc ] ; then \
    apt-get install -q -y \
      clang-tidy-20 \
      "g++-${COMPILER_VERSION}" \
      libc++abi-20-dev \
      libc++-20-dev \
      lld-20; \
    fi \
&&  if [ $COMPILER_NAME = clang ] ; then \
    apt-get install -q -y \
    "clang-tidy-${COMPILER_VERSION}" \
    "libc++abi-${COMPILER_VERSION}-dev" \
    "libc++-${COMPILER_VERSION}-dev" \
    "lld-${COMPILER_VERSION}" \
    "llvm-${COMPILER_VERSION}"; \
    fi \
&&  if echo "$COMPILER" | grep -Eq '^clang-(1[2-9]|20)$'; then \
      apt-get install -q -y "libunwind-${COMPILER_VERSION}-dev"; \
    fi \
&&  if echo "$COMPILER" | grep -Eq '^clang-(1[4-9]|20)$'; then \
      apt-get install -q -y "libclang-rt-${COMPILER_VERSION}-dev"; \
    fi \
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
&&  update-alternatives --install /usr/bin/ld   ld   /usr/bin/lld-20                 100; \
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
&&  update-alternatives --install /usr/bin/ld  ld  /usr/bin/lld-$COMPILER_VERSION     100; \
fi

RUN ln -s "$HOME/.conan2/" /opt/conan

RUN sed -i '/^compiler\.libcxx.*$/d' "$CONAN_DEFAULT_PROFILE_PATH"      \
&&  echo 'compiler.libcxx=libstdc++11' >> "$CONAN_DEFAULT_PROFILE_PATH" \
&&  cat "$CONAN_DEFAULT_PROFILE_PATH"

RUN printf '#include <iostream>\nint main(){ std::cout << "test\\n"; }' > /tmp/test.cpp \
&&  "$CXX" -fsanitize=address /tmp/test.cpp -o /tmp/test \
&&  if ldd /tmp/test | grep -qF 'not found'; then \
       ldd /tmp/test; exit 1; \
    fi \
&&  rm /tmp/test*

ARG BASE_OS

FROM $BASE_OS AS ccache-builder

ARG CCACHE_VER=4.11.3

COPY --from=update-apt-src /etc/apt/sources.list /etc/apt/sources.list
COPY --from=update-apt-src /usr/share/keyrings/* /usr/share/keyrings/

RUN apt-get update -q || true \
&&  apt-get install -y ca-certificates \
&&  apt-get update -q \
&&  apt-get install -y \
    cmake \
    curl \
    elfutils \
    clang-20 \
    clang++-20 \
    xz-utils

RUN curl -L "https://github.com/ccache/ccache/releases/download/v$CCACHE_VER/ccache-$CCACHE_VER.tar.xz" | tar -xJf -

RUN cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_COMPILER=clang-20 \
          -DCMAKE_CXX_COMPILER=clang++-20 \
          -DENABLE_TESTING=ON \
          -DREDIS_STORAGE_BACKEND=OFF \
          -DDEPS=DOWNLOAD \
          -DSTATIC_LINK=ON \
          -DCMAKE_INSTALL_PREFIX=/tmp/ccache/ \
          -S "ccache-$CCACHE_VER/" \
          -B /tmp/build

RUN cmake --build /tmp/build -j "$(nproc)"

RUN cd /tmp/build/ \
&&  ctest --output-on-failure -j "$(nproc)"

RUN cmake --install /tmp/build

FROM base as final

COPY --from=ccache-builder /tmp/ccache/bin/ccache /usr/local/bin/ccache

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
