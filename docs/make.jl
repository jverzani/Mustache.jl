using Documenter
using Mustache

makedocs(
    sitename = "Mustache",
    format = Documenter.HTML(),
    modules = [Mustache]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jverzani/Mustache.jl.git"
)
