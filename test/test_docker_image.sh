#!/usr/bin/env bash

# Copyright (c) 2024 Roberto Rossini <roberros@uio.no>
#
# SPDX-License-Identifier: MIT

set -eu
set -o pipefail

if [ $# -ne 1 ]; then
  2>&1 echo "Usage: $0 image:latest"
  exit 1
fi

IMG="$1"

tmpdir="$(mktemp -d)"
# shellcheck disable=SC2064
trap "rm -rf '$tmpdir'" EXIT

cat > "$tmpdir/runme.sh" <<- 'EOM'

set -eu

# print distro information
cat /etc/*-release

# print compiler information
cc --version
c++ --version

# print CMake information
which cmake
cmake --version

# print ccache information
which ccache
ccache --version

# test Conan
printf '[requires]\nfmt/11.0.2' > conanfile.txt
conan install --build=missing \
      -pr:b="$CONAN_DEFAULT_PROFILE_PATH" \
      -pr:h="$CONAN_DEFAULT_PROFILE_PATH" \
      conanfile.txt
EOM

chmod 755 "$tmpdir/runme.sh"

sudo docker run --rm --entrypoint=/bin/bash \
  -v "$tmpdir/runme.sh:/tmp/runme.sh:ro" \
  "$IMG" \
  /tmp/runme.sh
