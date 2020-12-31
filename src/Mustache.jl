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
