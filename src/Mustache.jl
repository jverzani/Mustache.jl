module Mustache

using DataFrames

include("utils.jl")
include("tokens.jl")
include("scanner.jl")
include("context.jl")
include("writer.jl")
include("parse.jl")

export @mt_str, render

## Macro to comile simple parsing outside of loops
## use as mt"{{a}} and {{b}}", say
macro mt_str(s)
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
function render(io::IO, template::ASCIIString, view)
    _writer = Writer()
    render(io, _writer, parse(template), view)
end

render(template::ASCIIString, view) = sprint(io -> render(io, template, view))
render(template::ASCIIString) = render(template, Main)



end