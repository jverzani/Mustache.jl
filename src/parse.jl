## Main function to parse a template This works in several steps: each
## character parsed into a token, the tokens are squashed, then
## nested, then rendered.

"""
   Mustache.parse(template, tags = ("{{", "}}"))

Parse a template into tokens.

* `template`: a string containing a template
* `tags`: the tags used to indicate a variable. Adding interior braces (`{`,`}`) around the  variable will prevent HTML escaping. (That is for the default tags, `{{{varname}}}` is used; for tags like `("<<",">>")` then `<<{varname}>>` is used.)

# Extended

The template interprets tags in different ways. The string macro `mt`
is used below to both `parse` (on construction) and `render` (when
called).

## Variable substitution.

Like basic string interpolation, variable substitution can be performed using a non-prefixed tag:

```jldoctest mustache
julia> using Mustache

julia> a = mt"Some {{:variable}}.";

julia> a(; variable="pig")
"Some pig."

julia> a = mt"Cut: {{{:scissors}}}";

julia> a(; scissors = "8< ... >8")
"Cut: 8< ... >8"
```

Both using a symbol, as the values to substitute are passed through keyword arguments. The latter uses triple braces to inhibit the escaping of HTML entities.

Tags can be given special meanings through prefixes. For example, to avoid the HTML escaping an `&` can be used:

```jldoctest mustache
julia> a = mt"Cut: {{&:scissors}}";

julia> a(; scissors = "8< ... >8")
"Cut: 8< ... >8"
```

## Sections

Tags can create "sections" which can be used to conditionally include text, apply a function to text, or iterate over the values passed to `render`.

### Include text
To include text, the `#` prefix can open a section followed by a `/` to close the section:

```jldoctest mustache
julia> a = mt"I see a {{#:ghost}}ghost{{/:ghost}}";

julia> a(; ghost=true)
"I see a ghost"

julia> a(; ghost=false)
"I see a "
```

The latter is to illustrate that if the variable does not exist or is "falsy", the section text will not display.

The `^` prefix shows text when the variable is not present.

```jldoctest mustache
julia> a = mt"I see {{#:ghost}}a ghost{{/:ghost}}{{^:ghost}}nothing{{/:ghost}}";

julia> a(; ghost=false)
"I see nothing"
```

### Apply a function to the text

If the variable refers to a function, it will be applied to the text within the section:

```jldoctest mustache
julia> a = mt"{{#:fn}}How many letters{{/:fn}}";

julia> a(; fn=length)
"16"
```

The use of the prefix `!` will first render the text in the section, then apply the function:

```jldoctest mustache
julia> a = mt"The word '{{:variable}}' has {{|:fn}}{{:variable}}{{/:fn}} letters.";

julia> a(; variable="length", fn=length)
"The word 'length' has 6 letters."
```

### Iterate over values

If the variable in a section is an iterable container, the values will be iterated over. `Tables.jl` compatible values are iterated in a row by row manner, such as this view, which is a tuple of named tuples:

```jldoctest mustache
julia> a = mt"{{#:data}}x={{:x}}, y={{:y}} ... {{/:data}}";

julia> a(; data=((x=1,y=2), (x=2, y=4)))
"x=1, y=2 ... x=2, y=4 ... "
```

Iterables like vectors, tuples, or ranges -- which have no named values -- can have their values referenced by a `{{.}}` tag:

```jldoctest mustache
julia> a = mt"{{#:countdown}}{{.}} ... {{/:countdown}} blastoff";

julia> a(; countdown = 5:-1:1)
"5 ... 4 ... 3 ... 2 ... 1 ...  blastoff"
```

## Partials

Partials allow substitution. The use of the tag prefix `>` includes either a file or a string and renders it accordingly:

```jldoctest mustache
julia> a = mt"{{>:partial}}";

julia> a(; partial="variable is {{:variable}}", variable=42)
"variable is 42"
```

The use of the tag prefix `<` just includes the partial (a file in this case) without rendering.

## Comments

Using the tag-prefix `!` will comment out the text:

```jldoctest mustache
julia> a = mt"{{! ignore this comment}}This is rendered";

julia> a()
"This is rendered"
```

Multi-lne comments are permitted.

"""
function parse(template, tags = ("{{", "}}"))
    tokens = make_tokens(template, tags)
    out = nestTokens(tokens)
    MustacheTokens(out)
end


"""
    mt"string"

String macro to parse tokens from a string. See [`parse`](@ref).

"""
macro mt_str(s)
    parse(s)
end


"""
    jmt"string"

String macro that interpolates values escaped by dollar signs, then parses strings.

Note: very lightly modified from a macro in [HypertextLiteral](https://github.com/JuliaPluto/HypertextLiteral.jl/blob/master/src/macro.jl).

Example:

```
x = 1
toks = jmt"\$(2x) by {{:a}}"
toks(; a=2) # "2 by 2"
```
"""
macro jmt_str(expr::String)
    # Essentially this is an ad-hoc scanner of the string, splitting
    # it by `$` to find interpolated parts and delegating the hard work
    # to `Meta.parse`, treating everything else as a literal string.
    args = Any[]
    start = idx = 1
    strlen = lastindex(expr)
    while true
        idx = findnext(isequal('$'), expr, start)
        if idx == nothing
           chunk = expr[start:strlen]
           push!(args, expr[start:strlen])
           break
        end
        push!(args, expr[start:prevind(expr, idx)])
        start = nextind(expr, idx)
        if length(expr) >= start && expr[start] == '$'
            push!(args, "\$")
            start += 1
            continue
        end
        (nest, tail) = Meta.parse(expr, start; greedy=false)
        if nest == nothing
            throw("missing expression at $idx: $(expr[start:end])")
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
