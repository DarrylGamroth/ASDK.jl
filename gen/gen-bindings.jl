using Clang.Generators

using AlpaoSDK_jll

cd(@__DIR__)

include_dir = joinpath(AlpaoSDK_jll.artifact_dir, "include")

options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()
push!(args, "-I$include_dir")

headers = [
    joinpath(include_dir, "asdkWrapper.h")
]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
