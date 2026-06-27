import Pkg
Pkg.activate(@__DIR__)
Pkg.develop(Pkg.PackageSpec(path = joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using Literate
using DieselGen

ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")

DocMeta.setdocmeta!(DieselGen, :DocTestSetup, :(using DieselGen); recursive = true)

const LITERATE_DIR = joinpath(@__DIR__, "..", "examples")
const GENERATED_DIR = joinpath(@__DIR__, "src", "generated")

mkpath(GENERATED_DIR)
Literate.markdown(joinpath(LITERATE_DIR, "perf_map.jl"), GENERATED_DIR; documenter = true, name = "perf_map")
Literate.markdown(joinpath(LITERATE_DIR, "unsteady_usage.jl"), GENERATED_DIR; documenter = true, name = "unsteady_usage")

makedocs(
    sitename = "DieselGen.jl",
    modules = [DieselGen],
    remotes = nothing,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "master",
        repolink = "https://github.com/sandialabs/DieselGen.jl",
    ),
    pages = [
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "Theory" => "theory.md",
        "API" => "api.md",
        "Examples" => [
            "examples.md",
            "generated/perf_map.md",
            "generated/unsteady_usage.md",
        ],
    ],
)

if get(ENV, "CI", "false") == "true"
    deploydocs(repo = "github.com/sandialabs/DieselGen.jl.git", devbranch = "master")
end
