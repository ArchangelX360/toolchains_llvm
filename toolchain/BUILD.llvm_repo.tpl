# Copyright 2021 The Bazel Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package(default_visibility = ["//visibility:public"])

# Some targets may need to directly depend on these files.
exports_files(glob(
    [
        "bin/*",
        "lib/**",
        "include/**",
        "share/clang/*",
    ],
    allow_empty = True,
))

## LLVM toolchain files

ALL_DLLS = glob(["bin/*.dll"], allow_empty=True)

filegroup(
    name = "clang",
    srcs = select({{
       # TODO: does not work for cross-compilation, must be changed
       "@platforms//os:windows": [
           "bin/clang.exe",
           "bin/clang++.exe",
           "bin/clang-cpp.exe",
           "bin/clang-cl.exe",
           "bin/lld-link.exe",
       ] + ALL_DLLS,
       "//conditions:default": [
           "bin/clang",
           "bin/clang++",
           "bin/clang-cpp",
           "bin/clang-cl",
           "bin/lld-link",
       ],
   }}),
)

filegroup(
    name = "ld",
    # Not all distributions contain wasm-ld.
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/ld.lld.exe",
            "bin/ld64.lld.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/ld.lld",
            "bin/ld64.lld",
        ] + glob(["bin/wasm-ld"], allow_empty = True),
    }}),
)

filegroup(
    name = "include",
    srcs = glob(
        [
            "include/**/c++/**",
            "lib/clang/*/include/**",
        ],
        allow_empty = True, # empty in Windows distributions
    ),
)

filegroup(
    name = "all_includes",
    srcs = glob(
        ["include/**"],
        allow_empty = True,
    ),
)

# This filegroup should only have source directories, not individual files.
# We rely on this assumption in system_module_map.bzl.
filegroup(
    name = "cxx_builtin_include",
    srcs = [
        "include/c++",
        "lib/clang/{LLVM_VERSION}/include",
    ],
)

filegroup(
    name = "extra_config_site",
    srcs = glob(["include/*/c++/v1/__config_site"], allow_empty = True)
)

filegroup(
    name = "bin",
    srcs = glob(["bin/**"]),
)

filegroup(
    name = "lib",
    srcs = [
        # Include the .dylib files in the linker sandbox even though they will
        # not be available at runtime to allow sanitizers to work locally.
        # Any library linked from the toolchain to be released should be linked statically.
        "lib/clang/{LLVM_VERSION}/lib",
    ] + select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [],
        "//conditions:default": glob([
            "lib/**/libc++*.a",
            "lib/**/libunwind.a",
        ], allow_empty = True),
    }}),
)

filegroup(
    name = "lib_legacy",
    srcs = glob([
        # Include the .dylib files in the linker sandbox even though they will
        # not be available at runtime to allow sanitizers to work locally.
        # Any library linked from the toolchain to be released should be linked statically.
        "lib/clang/{LLVM_VERSION}/lib/**",
        "lib/**/libc++*.a",
        "lib/**/libunwind.a",
    ], allow_empty = True),
)

filegroup(
    name = "ar",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-ar.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-ar",
        ],
    }}),
)

filegroup(
    name = "as",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/clang.exe",
            "bin/llvm-as.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/clang",
            "bin/llvm-as",
        ],
    }}),
)

filegroup(
    name = "nm",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-nm.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-nm",
        ],
    }}),
)

filegroup(
    name = "objcopy",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-objcopy.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-objcopy",
        ],
    }}),
)

filegroup(
    name = "objdump",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-objdump.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-objdump",
        ],
    }}),
)

filegroup(
    name = "profdata",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-profdata.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-profdata",
        ],
    }}),
)

filegroup(
    name = "dwp",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-dwp.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-dwp",
        ],
    }}),
)

filegroup(
    name = "ranlib",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-ranlib.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-ranlib",
        ],
    }}),
)

filegroup(
    name = "readelf",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-readelf.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-readelf",
        ],
    }}),
)

filegroup(
    name = "strip",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-strip.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-strip",
        ],
    }}),
)

filegroup(
    name = "symbolizer",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/llvm-symbolizer.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/llvm-symbolizer",
        ],
    }}),
)

filegroup(
    name = "clang-tidy",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/clang-tidy.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/clang-tidy",
        ],
    }}),
)

filegroup(
    name = "clang-format",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/clang-format.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/clang-format",
        ],
    }}),
)

filegroup(
    name = "git-clang-format",
    srcs = select({{
        # TODO: does not work for cross-compilation, must be changed
        "@platforms//os:windows": [
            "bin/git-clang-format.exe",
        ] + ALL_DLLS,
        "//conditions:default": [
            "bin/git-clang-format",
        ],
    }}),
)

filegroup(
    name = "libclang",
    srcs = glob(
        [
            "lib/libclang.so",
            "lib/libclang.dylib",
        ],
        allow_empty = True,
    ),
)
