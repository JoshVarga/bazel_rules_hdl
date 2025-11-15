# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""BUILD helpers for using iverilog.
"""

load("@rules_cc//cc:defs.bzl", "cc_binary")

def vpi_binary(name, out, srcs, **kwargs):
    """Creates a .vpi file with the given name from the given sources.

    All the extra arguments are passed directly to cc_binary.

    Args:
      name: The name of the target.
      out: The name of the output .vpi or .tgt file.
      srcs: Source files for the plugin.
      **kwargs: Additional arguments passed to cc_binary.
    """
    cc_target = name + "_shared"
    
    # Add platform-specific linker flags
    linkopts = kwargs.pop("linkopts", [])
    linkopts = linkopts + select({
        "@platforms//os:macos": [
            # Allow undefined symbols to be resolved at runtime from the loading executable
            "-undefined",
            "dynamic_lookup",
        ],
        "@platforms//os:linux": [
            # On Linux, allow undefined symbols in shared libraries
            "-Wl,--allow-shlib-undefined",
        ],
        "//conditions:default": [],
    })
    
    cc_binary(
        name = cc_target,
        srcs = srcs,
        linkshared = 1,
        linkopts = linkopts,
        **kwargs
    )

    native.genrule(
        name = name,
        srcs = [":" + cc_target],
        outs = [out],
        cmd = "cp $< $@",
        output_to_bindir = 1,
        executable = 1,
    )
