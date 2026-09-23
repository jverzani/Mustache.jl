using Documenter
using MaterialDocs
using Mustache

makedocs(
    sitename = "Mustache",
    #format = Documenter.HTML(),
    format   = Material3(theme = :ocean_depth, dark_mode = :toggle),
    modules = [Mustache]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jverzani/Mustache.jl.git"
)
