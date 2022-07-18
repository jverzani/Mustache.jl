"""
Mustache

[Mustache](https://github.com/jverzani/Mustache.jl) is a templating package for `Julia` based on [Mustache.js](http://mustache.github.io/). [ [Docs](https://jverzani.github.io/Mustache.jl/dev/) ]
"""
module Mustache

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end


using Tables

include("utils.jl")
include("tokens.jl")
include("context.jl")
include("writer.jl")
include("parse.jl")
include("render.jl")

export @mt_str, @jmt_str, render, render_from_file


end
