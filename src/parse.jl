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

macro mt_mstr(s)
    parse(s)
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


