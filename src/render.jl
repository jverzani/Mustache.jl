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


# Exported, but should be deprecated....
"""
    render_from_file(filepath, view)
    render_from_file(filepath; kwargs...)

Renders a template from `filepath` and `view`. 
"""
render_from_file(filepath, view) = render(Mustache.load(filepath), view)
render_from_file(filepath::AbstractString; kwargs...) = render(Mustache.load(filepath); kwargs...)
