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

"""Build rule for generating C or C++ sources with Bison.
"""

def correct_bison_env_for_action(env, bison):
    """Modify the Bison environment variables to work in an action that doesn't a have built bison runfiles directory.

    The `bison_toolchain.bison_env` parameter assumes that Bison will provided via an executable attribute
    and thus have built runfiles available to it. This is not the case for this action and any other actions
    trying to use bison as a tool via the toolchain. This function transforms existing environment variables
    to support running Bison as desired.

    Args:
        env (dict): The existing bison environment variables
        bison (File): The Bison executable

    Returns:
        Dict: Environment variables required for running Bison.
    """
    bison_env = dict(env)

    # Convert the environment variables to non-runfiles forms
    bison_runfiles_dir = "{}.runfiles/{}".format(
        bison.path,
        bison.owner.workspace_name,
    )

    actual = "external/{}".format(bison.owner.workspace_name)

    for key, value in bison_env.items():
        bison_env[key] = value.replace(bison_runfiles_dir, actual)

    return bison_env

def _genyacc_impl(ctx):
    """Implementation for genyacc rule."""

    bison_toolchain = ctx.toolchains["@rules_bison//bison:toolchain_type"].bison_toolchain

    # Argument list
    args = ctx.actions.args()
    args.add("--defines=%s" % ctx.outputs.header_out.path)
    args.add("--output-file=%s" % ctx.outputs.source_out.path)
    if ctx.attr.prefix:
        args.add("--name-prefix=%s" % ctx.attr.prefix)
    args.add_all([ctx.expand_location(opt) for opt in ctx.attr.extra_options])
    args.add(ctx.file.src.path)

    # Output files
    outputs = ctx.outputs.extra_outs + [
        ctx.outputs.header_out,
        ctx.outputs.source_out,
    ]

    ctx.actions.run(
        executable = bison_toolchain.bison_tool.executable,
        env = correct_bison_env_for_action(
            env = bison_toolchain.bison_env,
            bison = bison_toolchain.bison_tool.executable,
        ),
        arguments = [args],
        inputs = ctx.files.src,
        tools = [bison_toolchain.all_files],
        outputs = outputs,
        mnemonic = "Yacc",
        progress_message = "Generating %s and %s from %s" %
                           (
                               ctx.outputs.source_out.short_path,
                               ctx.outputs.header_out.short_path,
                               ctx.file.src.short_path,
                           ),
    )

genyacc = rule(
    implementation = _genyacc_impl,
    doc = "Generate C/C++-language sources from a Yacc file using Bison.",
    attrs = {
        "extra_options": attr.string_list(
            doc = "A list of extra options to pass to Bison.  These are " +
                  "subject to $(location ...) expansion.",
        ),
        "extra_outs": attr.output_list(
            doc = "A list of extra generated output files.",
        ),
        "header_out": attr.output(
            mandatory = True,
            doc = "The generated 'defines' header file",
        ),
        "prefix": attr.string(
            doc = "External symbol prefix for Bison. This string is " +
                  "passed to bison as the -p option, causing the resulting C " +
                  "file to define external functions named 'prefix'parse, " +
                  "'prefix'lex, etc. instead of yyparse, yylex, etc.",
        ),
        "source_out": attr.output(
            mandatory = True,
            doc = "The generated source file",
        ),
        "src": attr.label(
            mandatory = True,
            allow_single_file = [".y", ".yy", ".yc", ".ypp", ".yxx"],
            doc = "The .y, .yy, or .yc source file for this rule",
        ),
    },
    toolchains = [
        "@rules_bison//bison:toolchain_type",
    ],
    output_to_genfiles = True,
)
