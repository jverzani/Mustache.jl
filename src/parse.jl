## Main function to parse a template This works in several steps: each
## character parsed into a token, the tokens are squashed, then
## nested, then rendered.

"""
   Mustache.parse(template, tags = ("{{", "}}"))

Parse a template into tokens. 

* `template`: a string containing a template
* `tags`: the tags used to indicate a variable. Adding interior braces (`{`,`}`) around the 
variable will prevent HTML escaping. (That is for the default tags, `{{{varname}}}` is used; for 
tags like `("<<",">>")` then `<<{varname}>>` is used.)

"""
function parse(template, tags = ("{{", "}}"))
    tokens = make_tokens(template, tags)
    out = nestTokens(tokens)
    MustacheTokens(out)
end


"""
    mt"string"

Macro to parse tokens from a string. 

"""
macro mt_str(s)
    parse(s)
end


"""
    jmt"string"

Macro that interpolates values escaped by dollar signs, then parses strings.

Note: modified from [HypertextLiteral](https://github.com/clarkevans/HypertextLiteral.jl/blob/master/src/macros.jl)

Example:

```
x = 1
toks = jmt"\$(2x) by {{:a}}"
toks(a=2) # "2 by 2"
```
"""
macro jmt_str(expr::String)
    # Essentially this is an ad-hoc scanner of the string, splitting
    # it by `$` to find interpolated parts and delegating the hard work
    # to `Meta.parse`, treating everything else as a literal string.

    args = Any[]
    start = idx = 1
    strlen = length(expr)
    while true
        idx = findnext(isequal('$'), expr, start)
        if idx == nothing
           push!(args, expr[start:strlen])
           break
        end
        push!(args, expr[start:idx-1])
        start = idx + 1
        (nest, tail) = Meta.parse(expr, start; greedy=false)
        if nest == nothing
            throw("missing interpolation expression")
        end
        if !(expr[start] == '(' || nest isa Symbol)
            throw(DomainError(nest,
             "interpolations must be symbols or parenthesized"))
        end
        if Meta.isexpr(nest, :(=))
            throw(DomainError(nest,
             "assignments are not permitted in an interpolation"))
        end
        if nest isa String
            # this is an interpolated string literal
            nest = Expr(:string, nest)
        end
        push!(args, nest)
        start = tail
    end

    quote
        Mustache.parse(string($(map(esc, args)...)))
    end

end



## Dict for storing parsed templates
TEMPLATES = Dict{AbstractString, MustacheTokens}()


"""
    Mustache.load(filepath, args...)

Load file specified through  `filepath` and return the compiled tokens.
Tokens are memoized for efficiency,

Additional arguments are passed to `Mustache.parse` (for adjusting the tags).
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


# old names. To be deprecated?
const template_from_file = load


