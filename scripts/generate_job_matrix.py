#!/usr/bin/env python3

# Copyright (C) 2024 Roberto Rossini (roberros@uio.no)
#
# SPDX-License-Identifier: MIT

import argparse
import json
import os
import sys
from typing import Dict, List

JobDicts = List[Dict[str, str]]


def make_cli() -> argparse.ArgumentParser:
    cli = argparse.ArgumentParser()

    cli.add_argument(
        "--conan-version",
        type=str,
        default="2.18.*",
    )
    cli.add_argument(
        "--cmake-version",
        type=str,
        default="4.0.*",
    )
    cli.add_argument(
        "--include-alpine",
        action="store_true",
        default=False,
    )
    cli.add_argument(
        "--include-ubuntu",
        action="store_true",
        default=False,
    )
    cli.add_argument(
        "--runner-x86",
        type=str,
        default="ubuntu-24.04",
    )
    cli.add_argument(
        "--runner-arm",
        type=str,
        default="ubuntu-24.04-arm",
    )

    return cli


def generate_alpine(
    cmake_version: str,
    conan_version: str,
    runner_x86: str,
    runner_arm: str,
    os_version: str | None = None,
) -> Dict[str, JobDicts]:
    os_name = "alpine"
    if os_version is None:
        os_version = "3.22"

    includes_amd64 = [
        {
            "runner": runner_x86,
            "os-name": os_name,
            "os-version": os_version,
            "cmake-version": cmake_version,
            "conan-version": conan_version,
            "platform": "linux/amd64",
            "compiler-name": None,
            "compiler-version": None,
            "python-version": None,
        }
    ]

    includes_arm64 = [
        {
            "runner": runner_arm,
            "os-name": os_name,
            "os-version": os_version,
            "cmake-version": cmake_version,
            "conan-version": conan_version,
            "platform": "linux/arm64",
            "compiler-name": None,
            "compiler-version": None,
            "python-version": None,
        }
    ]

    return {
        "includes_amd64": includes_amd64,
        "includes_arm64": includes_arm64,
    }


def generate_ubuntu(
    cmake_version: str,
    conan_version: str,
    runner_x86: str,
    runner_arm: str,
) -> Dict[str, JobDicts]:
    templates = (
        {
            "compiler-name": "gcc",
            "compiler-version": 8,
            "os-version": "20.04",
            "python-version": "3.9",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 9,
            "os-version": "22.04",
            "python-version": "3.11",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 10,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 11,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 12,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 13,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 14,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "gcc",
            "compiler-version": 15,
            "os-version": "25.04",
            "python-version": "3.13",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 8,
            "os-version": "20.04",
            "python-version": "3.9",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 9,
            "os-version": "20.04",
            "python-version": "3.9",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 10,
            "os-version": "20.04",
            "python-version": "3.9",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 11,
            "os-version": "22.04",
            "python-version": "3.11",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 12,
            "os-version": "22.04",
            "python-version": "3.11",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 13,
            "os-version": "22.04",
            "python-version": "3.11",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 14,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 15,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 16,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 17,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 18,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 19,
            "os-version": "24.04",
            "python-version": "3.12",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 20,
            "os-version": "20.04",
            "python-version": "3.9",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 20,
            "os-version": "22.04",
            "python-version": "3.11",
        },
        {
            "compiler-name": "clang",
            "compiler-version": 20,
            "os-version": "24.04",
            "python-version": "3.12",
        },
    )

    includes_amd64 = []
    includes_arm64 = []

    for t in templates:
        t |= {"os-name": "ubuntu", "cmake-version": cmake_version, "conan-version": conan_version}
        includes_amd64.append(t | {"runner": runner_x86, "platform": "linux/amd64"})
        includes_arm64.append(t | {"runner": runner_arm, "platform": "linux/arm64"})

    return {
        "includes_amd64": includes_amd64,
        "includes_arm64": includes_arm64,
    }


def merge_includes(
    inc1: Dict[str, JobDicts],
    inc2: Dict[str, JobDicts],
) -> Dict[str, JobDicts]:
    keys = set(inc1.keys()) | set(inc2.keys())
    out = {}
    for k in keys:
        v1 = inc1.get(k, [])
        v2 = inc2.get(k, [])

        out[k] = v1 + v2

    return out


def print_jobs(key, data, f):
    data = json.dumps(
        {"include": data},
        sort_keys=True,
    )

    print(f"{key}={data}", file=f)


def print_job_matrix(matrix: Dict[str, JobDicts]):
    includes = matrix["includes_amd64"] + matrix["includes_arm64"]

    json.dump(
        {"include": includes},
        fp=sys.stdout,
        indent=2,
        sort_keys=True,
    )

    path = os.environ.get("GITHUB_OUTPUT")
    if path is None:
        return

    with open(path, "a") as f:
        print_jobs("matrix-amd64", matrix["includes_amd64"], f)
        print_jobs("matrix-arm64", matrix["includes_arm64"], f)
        print_jobs("matrix", includes, f)


def main():
    args = vars(make_cli().parse_args())

    cmake_version = args["cmake_version"]
    conan_version = args["conan_version"]
    runner_x86 = args["runner_x86"]
    runner_arm = args["runner_arm"]

    includes = {}
    if args["include_alpine"]:
        includes = generate_alpine(
            cmake_version=cmake_version,
            conan_version=conan_version,
            runner_x86=runner_x86,
            runner_arm=runner_arm,
        )

    if args["include_ubuntu"]:
        includes = merge_includes(
            includes,
            generate_ubuntu(
                cmake_version=cmake_version,
                conan_version=conan_version,
                runner_x86=runner_x86,
                runner_arm=runner_arm,
            ),
        )

    if len(includes) == 0:
        raise RuntimeError("No jobs were generated. Is this intended?")

    print_job_matrix(includes)


if __name__ == "__main__":
    main()
