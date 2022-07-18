"""
    render([io], tokens, view)
    render([io], tokens; kwargs...)
    (tokens::MustacheTokens)([io]; kwargs...)

Render a set of tokens with a view, using optional `io` object to print or store.

## Arguments

* `io::IO`: Optional `IO` object.

* `tokens`: Either Mustache tokens, or a string to parse into tokens

* `view`: A view provides a context to look up unresolved symbols
  demarcated by mustache braces. A view may be specified by a
  dictionary, a module, a composite type, a vector, a named tuple, a
  data frame, a `Tables` object, or keyword arguments.

!!! note
    The `render` method is currently exported, but this export may be deprecated in the future.
"""
function render(io::IO, tokens::MustacheTokens, view)
    _writer = Writer()
    render(io, _writer, tokens, view)
end
function render(io::IO, tokens::MustacheTokens; kwargs...)
    render(io, tokens, Dict(kwargs...))
end

render(tokens::MustacheTokens, view) = sprint(io -> render(io, tokens, view))
render(tokens::MustacheTokens; kwargs...) = sprint(io -> render(io, tokens; kwargs...))

## make MustacheTokens callable for kwargs...
function (m::MustacheTokens)(io::IO, args...; kwargs...)
    if length(args) == 1
        render(io, m, first(args))
    else
        render(io, m; kwargs...)
    end
end
(m::MustacheTokens)(args...; kwargs...) = sprint(io -> m(io, args...; kwargs...))



## Exported call without first parsing tokens via mt"literal"
##
## @param template a string containing the template for expansion
## @param view a Dict, Module, CompositeType, DataFrame holding variables for expansion
function render(io::IO, template::AbstractString, view; tags= ("{{", "}}"))
    return render(io, parse(template, tags), view)
end
function render(io::IO, template::AbstractString; kwargs...)
    return render(io, parse(template); kwargs...)
end
render(template::AbstractString, view; tags=("{{", "}}")) = sprint(io -> render(io, template, view, tags=tags))
render(template::AbstractString; kwargs...) = sprint(io -> render(io, template; kwargs...))



# Exported, but should be deprecated....
"""
    render_from_file(filepath, view)
    render_from_file(filepath; kwargs...)

Renders a template from `filepath` and `view`.

!!! note
    This function simply combines `Mustache.render` and `Mustache.load` and may be deprecated in the future.
"""
render_from_file(filepath, view) = render(Mustache.load(filepath), view)
render_from_file(filepath::AbstractString; kwargs...) = render(Mustache.load(filepath); kwargs...)
