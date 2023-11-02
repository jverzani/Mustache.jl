
## regular expressions to use
whiteRe = r"\s*"
spaceRe = r"\s+"
nonSpaceRe = r"\S"
eqRe = r"\s*="
curlyRe = r"\s*\}"

# # section
# ^ inversion
# / close section
# > partials
# { dont' escape
# & unescape a variable
# = set delimiters {{=<% %>=}} will set delimiters to <% %>
# ! comments
# | lamdda "section" with *evaluated* value
tagRe = r"^[#^/<>{&=!|]"

function asRegex(txt)
    for i in ("[","]")
        txt = replace(txt, Regex("\\$i") => "\\$i")
    end
    for i in ("(", ")", "{","}", "|")
        txt = replace(txt, Regex("[$i]") => "[$i]")
    end
    Regex(txt)
end


isWhitespace(x) = occursin(whiteRe, x)
function stripWhitespace(x)
    y = replace(x, r"^\s+" => "")
    replace(y, r"\s+$" => "")
end


## this is for falsy value
## Falsy is true if x is false, 0 length, "", ...
falsy(x::Bool) = !x
falsy(x::Array) = isempty(x) || all(falsy, x)
falsy(x::AbstractString) = x == ""
falsy(x::Nothing) = true
falsy(x::Missing) = true
#falsy(x) = (x == nothing) || false                #  default
function falsy(x)
    Tables.istable(x) && isempty(Tables.rows(x)) && return true
    x == nothing && return true
    false
end

## escape_html with entities

entityMap = [("&", "&amp;"),
             ("<", "&lt;"),
             (">", "&gt;"),
             ("'", "&#39;"),
             ("\"", "&quot;"),
             ("/", "&#x2F;")]

function escape_html(x)
    y = string(x)
    for (k,v) in entityMap
        y = replace(y, k => v)
    end
    y
end

## Make these work
function escapeRe(string)
    replace(string, r"[\-\[\]{}()*+?.,\\\^$|#\s]" => "\\\$&");
end

function escapeTags(tags)
   [Regex(escapeRe(tags[1]) * "\\s*"),
    Regex("\\s*" * escapeRe(tags[2]))]
end

# key may be string or a ":symbol"
function normalize(key)
    if occursin(r"^:", key)
        key = key[2:end]
        key = Symbol(key)
    end
    return key
end

# means to push values into scope of function through
# magic `this` variable, ala JavaScript
# user in function has
# `this = Mustache.get_this()`
# then `this.prop` should get value or nothing
struct This{T}
    __v__::T
end
# get
function Base.getproperty(this::This, key::Symbol)
    key == :__v__ && return getfield(this, :__v__)
    get(this.__v__, key, nothing)
end

# push to task local storage to evaluate function
function push_task_local_storage(view)
    task_local_storage(:__this__,This(view))
end

get_this() = get(task_local_storage(), :__this__, This(()))


## heuristic to avoid loading DataFrames
## Once `Tables.jl` support for DataFrames is available, this can be dropped
is_dataframe(x) = !isa(x, Dict) && !isa(x, Module) &&!isa(x, Array) && occursin(r"DataFrame", string(typeof(x)))
