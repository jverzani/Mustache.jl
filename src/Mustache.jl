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

export @mt_str, @mt_mstr, render, render_from_file



"""
    mt"string"

Macro to parse tokens from a string. Useful when template is to be reused.

"""
macro mt_str(s)
    parse(s)
end

macro mt_mstr(s)
    parse(s)
end

"""
    render([io], tokens, view)

Render a set of tokens with a view, using optional `io` object to print or store.

Arguments
---------

* `io::IO`: Optional `IO` object.

* `tokens`: Either Mustache tokens, or a string to parse into tokens

* `view`: A view provides a context to look up unresolved symbols
  demarcated by mustache braces. A view may be specified by a
  dictionary, a module, a composite type, a vector, a named tuple, a
  data frame, a `Tables` object, or keyword arguments.

"""
function render(io::IO, tokens::MustacheTokens, view)
    _writer = Writer()
    render(io, _writer, tokens, view)
end
function render(io::IO, tokens::MustacheTokens; kwargs...)
    render(io, tokens, kwargs)
end

render(tokens::MustacheTokens, view) = sprint(io -> render(io, tokens, view))
render(tokens::MustacheTokens; kwargs...) = sprint(io -> render(io, tokens, Dict(kwargs...)))

## Exported call without first parsing tokens via mt"literal"
##
## @param template a string containing the template for expansion
## @param view a Dict, Module, CompositeType, DataFrame holding variables for expansion
function render(io::IO, template::AbstractString, view; tags= ("{{", "}}"))
    _writer = Writer()
    render(io, _writer, parse(template, tags), view)
end
function render(io::IO, template::AbstractString; kwargs...)
    _writer = Writer()
    render(io, _writer, parse(template), Dict(kwargs...))
end
render(template::AbstractString, view; tags=("{{", "}}")) = sprint(io -> render(io, template, view, tags=tags))
render(template::AbstractString; kwargs...) = sprint(io -> render(io, template, Dict(kwargs...)))

## Dict for storing parsed templates
TEMPLATES = Dict{AbstractString, MustacheTokens}()

## Load template from file
"""
    Mustache.load(filepath, args...)

Load a filepath with extension `mustache` and return the compiled tokens.
Tokens are memoized for efficiency,

Additional arguments are passed to `parse` (for adjusting the tags).
"""
function load(filepath, args...)

    isfile(filepath) || throw(ArgumentError("File $filepath not found"))

    key = string(mtime(filepath)) * filepath * string(hash(args))
    haskey(TEMPLATES,key) && return  TEMPLATES[key]

    open(filepath) do s
        global tpl = parse(read(s, String), args...)
    end

    TEMPLATES[key] = tpl
    tpl

end
# old name
const template_from_file = load


"""
    render_from_file(filepath, view)
    render_from_file(filepath; kwargs...)

Renders a template from `filepath` and `view`. 

"""
render_from_file

@deprecate render_from_file(filepath, view) render(Mustache.load(filepath), view)
@deprecate render_from_file(filepath; kwargs...) render(Mustache.load(filepath); kwargs...)
# function render_from_file(filepath, view)
#     Base.depwarn("Deprecated. Use `render(Mustache.load(filepath), view)`", :render_from_file)
#     render(Mustache.load(filepath), view)
# end

# function render_from_file(filepath::AbstractString; kwargs...)
#     Base.depwarn("Deprecated. Use `render(Mustache.load(filepath); kwargs...)`", :render_from_file)
#     render(Mustache.load(filepath); kwargs...)
# end

end
