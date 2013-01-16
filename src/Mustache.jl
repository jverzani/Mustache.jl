module Mustache

using DataFrames

include("utils.jl")
include("tokens.jl")
include("scanner.jl")
include("context.jl")
include("writer.jl")
include("parse.jl")

## This is the main function
## Can call as Mustache.render(tpl, view)
##
## @param template a string containing the template for expansion
## @param view a Dict, Module, CompositeType, DataFrame holding variables for expansion
function render(template::ASCIIString, view)
    _writer = Writer()
    render(_writer, template, view)
end


end