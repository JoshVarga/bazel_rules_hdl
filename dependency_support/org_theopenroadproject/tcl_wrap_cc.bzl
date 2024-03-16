# Copyright 2021 Google LLC
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

"""A TCL SWIG wrapping rule for google3.

These rules generate a C++ src file that is expected to be used as srcs in
cc_library or cc_binary rules. See below for expected usage.

cc_library(srcs=[':tcl_foo"])
tcl_wrap_cc(name = "tcl_foo", srcs=["exception.i"],...)
"""
TclSwigInfo = provider("TclSwigInfo for taking dependencies on other swig info rules", fields = ["transitive_srcs", "includes", "swig_options"])

def _get_transative_srcs(srcs, deps):
    return depset(
        srcs,
        transitive = [dep[TclSwigInfo].transitive_srcs for dep in deps],
    )

def _get_transative_includes(local_includes, deps):
    return depset(
        local_includes,
        transitive = [dep[TclSwigInfo].includes for dep in deps],
    )

def _get_transative_options(options, deps):
    return depset(
        options,
        transitive = [dep[TclSwigInfo].swig_options for dep in deps],
    )

def _tcl_wrap_cc_impl(ctx):
    """Generates a single C++ file from the provided srcs in a DefaultInfo.
    """
    if len(ctx.files.srcs) > 1 and not ctx.attr.root_swig_src:
        fail("If multiple src files are provided root_swig_src must be specified.")

    root_file = ctx.file.root_swig_src
    root_file = root_file if root_file != None else ctx.files.srcs[0]

    root_label = ctx.attr.root_swig_src
    root_label = root_label if root_label != None else ctx.attr.srcs[0]
    root_label = root_label.label

    outfile_name = ctx.attr.out if ctx.attr.out else ctx.attr.name + ".cc"
    output_file = ctx.actions.declare_file(outfile_name)

    (inputs, _) = ctx.resolve_tools(tools = [ctx.attr._swig])

    include_root_directory = root_label.workspace_root + "/" + root_label.package

    src_inputs = _get_transative_srcs(ctx.files.srcs + ctx.files.root_swig_src, ctx.attr.deps)
    includes_paths = _get_transative_includes(
        ["{}{}".format(include_root_directory, include) for include in ctx.attr.swig_includes],
        ctx.attr.deps,
    )
    swig_options = _get_transative_options(ctx.attr.swig_options, ctx.attr.deps)

    args = ctx.actions.args()
    args.add("-tcl8")
    args.add("-c++")
    if ctx.attr.module:
        args.add("-module")
        args.add(ctx.attr.module)
    if ctx.attr.namespace_prefix:
        args.add("-namespace")
        args.add("-prefix")
        args.add(ctx.attr.namespace_prefix)
    args.add_all(swig_options.to_list())
    args.add_all(includes_paths.to_list(), format_each = "-I%s")
    args.add("-o")
    args.add(output_file.path)
    args.add(root_file.path)

    ctx.actions.run(
        outputs = [output_file],
        inputs = src_inputs,
        arguments = [args],
        tools = inputs,
        executable = ([file for file in ctx.files._swig if file.basename == "swig"][0]),
    )
    return [
        DefaultInfo(files = depset([output_file])),
        TclSwigInfo(
            transitive_srcs = src_inputs,
            includes = includes_paths,
            swig_options = swig_options,
        ),
    ]

tcl_wrap_cc = rule(
    implementation = _tcl_wrap_cc_impl,
    attrs = {
        "deps": attr.label_list(
            allow_empty = True,
            doc = "tcl_wrap_cc dependencies",
            providers = [TclSwigInfo],
        ),
        "module": attr.string(
            mandatory = False,
            default = "",
            doc = "swig module",
        ),
        "namespace_prefix": attr.string(
            mandatory = False,
            default = "",
            doc = "swig namespace prefix",
        ),
        "out": attr.string(
            doc = "The name of the C++ source file generated by these rules.",
        ),
        "root_swig_src": attr.label(
            allow_single_file = [".swig", ".i"],
            doc = """If more than one swig file is included in this rule.
            The root file must be explicitly provided. This is the which will be passed to
            swig for generation.""",
        ),
        "srcs": attr.label_list(
            allow_empty = False,
            allow_files = [".i", ".swig", ".h", ".hpp"],
            doc = "Swig files that generate C++ files",
        ),
        "swig_includes": attr.string_list(
            doc = "List of directories relative to the BUILD file to append as -I flags to SWIG",
        ),
        "swig_options": attr.string_list(
            doc = "args to pass directly to the swig binary",
        ),
        "_swig": attr.label(
            default = "@org_swig//:swig_stable",
            allow_files = True,
            cfg = "exec",
        ),
    },
)
