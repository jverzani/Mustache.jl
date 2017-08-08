## writer

mutable struct Writer
    _cache::Dict
    _partialCache::Dict
    _loadPartial ## Function or nothing
end

Writer() = Writer(Dict(), Dict(), nothing)

function clearCache(w::Writer)
    w._cache=Dict()
    w._partialCache=Dict()
end

function compile(io::IO, w::Writer, template, tags)
#    if haskey(w._cache, template)
#        return(w._cache[template])
#    end

##    tokens = parse(template, tags)
    tokens = template
    compileTokens(io, w, tokens.tokens, template)
#    w._cache[template] = compileTokens(io, w, tokens.tokens, template)

#    return(w._cache[template])
end

function compilePartial(w::Writer, name, template, tags)
    fn = compile(w, template, tags)
    w._partialCache[name] = fn
    fn
end

function getPartial(w::Writer, name)
## didn't do loadPartial, as not sure where template is
#    if !haskey(w._partialCache, name) && is(w._loadPartial, Function)
#        compilePartial(w,

    w._partialCache[name]
end

function compileTokens(io, w::Writer, tokens, template)
    ## return a function
    function f(w::Writer, view) #  no partials
       renderTokens(io, tokens, w, Context(view), template) # io in closure
    end
    return(f)
end

function render(io::IO, w::Writer, template, view)
    f = compile(io, w, template, ["{{", "}}"])
    f(w, view)
end
