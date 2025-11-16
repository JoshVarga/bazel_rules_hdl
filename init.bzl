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

""" initializes the bazel_rules_hdl workspace """

load("@rules_bison//bison:bison.bzl", "bison_register_toolchains")
load("@rules_flex//flex:flex.bzl", "flex_register_toolchains")
load("@rules_m4//m4:m4.bzl", "m4_register_toolchains")
# NOTE: Pip dependencies are handled by MODULE.bazel when Bzlmod is enabled
# load("//dependency_support:requirements.bzl", install_pip_deps = "install_deps")
load("//dependency_support/boost:init_boost.bzl", "init_boost")

def init(python_interpreter = None, python_interpreter_target = None):  # @unused pylint: disable=unused-argument
    """Initializes the bazel_rules_hdl workspace.

    If @bazel_rules_hdl is imported into another Bazel workspace, that workspace
    must call `init` to allow @bazel_rules_hdl to set itself up.

    NOTE: python_interpreter and python_interpreter_target parameters are kept
    for backward compatibility but are no longer used when Bzlmod is enabled,
    as Python dependencies are managed via MODULE.bazel.

    Args:
      python_interpreter: (Deprecated when using Bzlmod) Path to external Python interpreter.
      python_interpreter_target: (Deprecated when using Bzlmod) Bazel target of a Python interpreter.
    """

    # NOTE: rules_proto dependencies are handled by MODULE.bazel when Bzlmod is enabled
    # rules_proto_dependencies()
    # rules_proto_toolchains()


    init_boost()
    m4_register_toolchains(version = "1.4.18")
    bison_register_toolchains(version = "3.3.2")
    flex_register_toolchains(version = "2.6.4")
