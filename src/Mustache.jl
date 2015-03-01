module Mustache

# using DataFrames
using Requires
include("utils.jl")
include("tokens.jl")
include("scanner.jl")
include("context.jl")
include("writer.jl")
include("parse.jl")

export @mt_str, @mt_mstr, render, render_from_file

## Macro to comile simple parsing outside of loops
## use as mt"{{a}} and {{b}}", say
macro mt_str(s)
    parse(s)
end

macro mt_mstr(s)
    parse(s)
end

## Main function for use with compiled strings
## @param tokens  Created using mt_str macro, as in mt"abc do re me"
function render(io::IO, tokens::MustacheTokens, view)
    _writer = Writer()
    render(io, _writer, tokens, view)
end

render(tokens::MustacheTokens, view) = sprint(io -> render(io, tokens, view))
render(tokens::MustacheTokens) = render(tokens, Main)

## Exported call without first parsing tokens via mt"literal"
##
## @param template a string containing the template for expansion
## @param view a Dict, Module, CompositeType, DataFrame holding variables for expansion
function render(io::IO, template::String, view)
    _writer = Writer()
    render(io, _writer, parse(template), view)
end

render(template::String, view) = sprint(io -> render(io, template, view))
render(template::String) = render(template, Main)


## Dict for storing parsed templates
TEMPLATES = Dict{String, MustacheTokens}()

## Load template from file
function template_from_file(filepath)
    f = open(filepath)
    tpl = parse(readall(f))
    close(f)
    return tpl
end

## Renders a template from `filepath` and `view`. If it has seen the file
## before then it finds the compiled `MustacheTokens` in `TEMPLATES` rather
## than calling `parse` a second time.
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

end
