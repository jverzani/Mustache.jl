module Mustache

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
function render(io::IO, template::AbstractString, view)
    _writer = Writer()
    render(io, _writer, parse(template), view)
end
function render(io::IO, template::AbstractString; kwargs...)
    _writer = Writer()
    render(io, _writer, parse(template), Dict(kwargs...))
end
render(template::AbstractString, view) = sprint(io -> render(io, template, view))
render(template::AbstractString; kwargs...) = sprint(io -> render(io, template, Dict(kwargs...)))

## Dict for storing parsed templates
TEMPLATES = Dict{AbstractString, MustacheTokens}()

## Load template from file
function template_from_file(filepath)
    f = open(x -> read(x, String), filepath)
    tpl = parse(f)
    return tpl
end

"""

Renders a template from `filepath` and `view`. If it has seen the file
before then it finds the compiled `MustacheTokens` in `TEMPLATES` rather
than calling `parse` a second time.

"""
function render_from_file(filepath, view)
    if haskey(TEMPLATES, filepath)
        render(TEMPLATES[filepath], view)
    else
        try
            tpl = template_from_file(filepath)
            TEMPLATES[filepath] = tpl
            render(tpl, view)
        catch
            nothing
        end
    end
end
function render_from_file(filepath::AbstractString; kwargs...)
    render_from_file(filepath, kwargs)
end

end
