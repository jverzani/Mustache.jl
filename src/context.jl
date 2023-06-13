## context

## A context stores objects where named values are looked up.
mutable struct Context
    view ## of what? a Dict, Module, CompositeKind, DataFrame.parent.
    parent ## a context or nothing
    _cache::Dict
end


function Context(view, parent=nothing)
    d = Dict()
    d["."] = isa(view, AnIndex) ? view.value : view
    Context(view, parent, d)
end

## used by renderTokens
function ctx_push(ctx::Context, view)
    Context(view, ctx) ## add context as a parent
end

function ctx_pop(ctx::Context)
    ctx.parent
end

# we have some rules here
# * Each part of a dotted name should resolve only against its parent.
# * Any falsey value prior to the last part of the name should yield ''.
# * The first part of a dotted name should resolve as any other name.
function lookup_dotted(ctx::Context, dotted)
    for key in split(dotted, ".")
        nctx = lookup(Context(ctx.view), key)
        falsy(nctx) && return nothing
        ctx = Context(nctx, ctx)
    end
    ctx.view
end

# look up key in context
function lookup(ctx::Context, key)
    if haskey(ctx._cache, key)
        return ctx._cache[key]
    end

    # use global lookup down
    global_lookup = false
    if startswith(key, "~")
        global_lookup = true
        key = replace(key, r"^~" => "")
    end

    # begin
    context = ctx
    value = nothing
    while context !== nothing
        value′ = nothing

        ## does name have a .? We first check if it is a key, then use lookup_dotted
        value′ = lookup_in_view(context.view, stripWhitespace(key))
        if value′ === nothing && occursin(r"\.", key)

            value′ = lookup_dotted(context, key)

            if value′ == nothing
                ## do something with "."
                ## we use .[ind] to refer to value in parent of given index;
                m = match(r"^\.\[(.*)\]$", key)


                if m !== nothing
                    idx = m.captures[1]
                    vals = context.parent.view

                    # this has limited support for indices: "end", or a number, but no
                    # arithmetic, such as `end-1`.
                    ## This is for an iterable; rather than
                    ## limit the type, we let non-iterables error.
                    if true # isa(vals, AbstractVector)  || isa(vals, Tuple) # supports getindex(v, i)?
                        if idx == "end"
                            value′ = AnIndex(-1, vals[end])
                        else
                            ind = Base.parse(Int, idx)
                            value′ = AnIndex(ind, string(vals[ind]))
                        end
                    end
                else
                    !global_lookup && break
                end
            end
        end

        if value′ !== nothing
            value = value′
            !global_lookup && break
        end

        context = context.parent
    end

    ## cache
    ctx._cache[key] = value
    return(value)
end

## Lookup value in an object by key
## This of course varies based on the view.
## After checking several specific types, if view is Tables compatible
## this will return "column" corresponding to the key
function lookup_in_view(view, key)
    val = _lookup_in_view(view, key)
    !falsy(val) && return val

    if Tables.istable(view)
        isempty(Tables.rows(view)) && return nothing
        sch = Tables.schema(Tables.rows(view))
        falsy(sch) && return nothing
        k = normalize(key)
        if k ∈ sch.names
            return [row[k] for row ∈ Tables.rows(view)]
        end
    # elseif  is_dataframe(view)

    #     if occursin(r"^:", key)  key = key[2:end] end
    #     key = Symbol(key)
    #     out = nothing
    #     if haskey(view, key)
    #             out = view[1, key] ## first element only
    #     end
    #     out
    else
        __lookup_in_view(view, key)
    end
end

# look up key in view, return `nothing` if not found
function _lookup_in_view(view::AbstractDict, key)
    get(view, normalize(key), nothing)
end

# support legacy use of `first` and `second` as variable names
# referring to piece, otherwise look up value
function _lookup_in_view(view::Pair, key)
    ## is it a symbol?
    key == "first" && return view.first
    key == "second" && return view.second
    view.first == normalize(key) ? view.second : nothing
end

function _lookup_in_view(view::NamedTuple, key)
    get(view, normalize(key), nothing)
end

function _lookup_in_view(view::Module, key)

    hasmatch = false
    re = Regex("^$key\$")
    for i in names(view, all=true)
        if occursin(re, string(i))
            hasmatch = true
            break
        end
    end

    out = nothing
    if hasmatch
        out = getfield(view, Symbol(key))  ## view.key
    end
    out

end

_lookup_in_view(view, key) = nothing

## Default lookup is likely not great,
function __lookup_in_view(view, key)
    k = normalize(key)
    k′ = Symbol(k)

    # check propertyname, then fieldnames
    if k in propertynames(view)
        getproperty(view, k)
    elseif k′ in propertynames(view)
        getproperty(view, k′)
    else

        nms = fieldnames(typeof(view))

        # we match on symbol or string for fieldname
        if isa(k, Symbol)
            has_match = k in nms
        else
            has_match = Symbol(k) in nms
        end

        out = nothing
        if has_match
            out = getfield(view, Symbol(k))  ## view.key
        end

        out
    end
end
