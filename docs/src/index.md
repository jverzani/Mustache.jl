# Mustache.jl

Documentation for [Mustache.jl](https://github.com/jverzani/Mustache.jl).


## Examples

Following the main [documentation](http://mustache.github.io/mustache.5.html) for `Mustache.js` we have a "typical Mustache template" defined by:


```julia
using Mustache

tpl = mt"""
Hello {{name}}
You have just won {{value}} dollars!
{{#in_ca}}
Well, {{taxed_value}} dollars, after taxes.
{{/in_ca}}
"""
```

The values with braces (mustaches on their side) are looked up in a view, such as a dictionary or module. For example,

```julia
d = Dict(
"name" => "Chris",
"value" => 10000,
"taxed_value" => 10000 - (10000 * 0.4),
"in_ca" => true)

Mustache.render(tpl, d)
```

Yielding

```
Hello Chris
You have just won 10000 dollars!
Well, 6000.0 dollars, after taxes.
```

The `render` function pieces things together. Like `print`, the first
argument is for an optional `IO` instance. In the above example, where
one is not provided, a string is returned.

The flow is

* a template is parsed into tokens by `Mustache.parse`. This can be called directly, indirectly through the non-standard string literal `mt`, or when loading a file with `Mustache.load`. The templates use tags comprised of matching mustaches (`{}`), either two or three, to indicate a value to be substituted for. These tags may be adjusted when `parse` is called.

* The tokens and a view are `render`ed. The `render` function takes tokens as its second argument. If this argument is a string, `parse` is called internally. The `render` function than reassambles the template, substituting values, as appropriate, from the "view" passed to it and writes the output to the specified `io` argument.


There are only 4 exports: `mt` and `jmt`, string literals to specify a template, `render`, and `render_from_file`.


The view used to provide values to substitute into the template can be
specified in a variety of ways. The above example used a dictionary. A
Module may also be used, such as `Main`:


```julia
name, value, taxed_value, in_ca = "Christine", 10000, 10000 - (10000 * 0.4), false
Mustache.render(tpl, Main) |> print
```

Which yields:

```
Hello Christine
You have just won 10000 dollars!
```


Further, keyword arguments can be used when the variables in the
templates are symbols:

```julia
goes_together = mt"{{{:x}}} and {{{:y}}}."
Mustache.render(goes_together, x="Salt", y="pepper")
Mustache.render(goes_together, x="Bread", y="butter")
```

`Tokens` objects are functors; keyword arguments can also be passed to a `Tokens` object directly (bypassing the use of `render`):

```julia
goes_together = mt"{{{:x}}} and {{{:y}}}."
goes_together(x="Fish", y="chips")
```



Similarly, a named tuple may be used as a view.  As well, one can use
Composite Kinds. This may make writing `show` methods easier:

```julia
using Distributions
tpl = "Beta distribution with alpha={{α}}, beta={{β}}"
Mustache.render(tpl, Beta(1, 2))
```

gives

```
"Beta distribution with alpha=1.0, beta=2.0"
```

### Rendering

The `render` function combines tokens and a view to fill in the template. The basic call is `render([io::IO], tokens, view)`, however there are variants:


* `render(tokens; kwargs...)`
* `render(string, view)`  (`string` is parsed into tokens)
* `render(string; kwargs...)`

Finally, tokens are callable, so there are these variants to call `render`:

* `tokens([io::IO], view)`
* `tokens([io::IO]; kwargs...)`

### Views

Views are used to hold values for the templates variables. There are many possible objects that can be used for views:

* a dictionary
* a named tuple
* keyword arguments to `render`
* a module

For templates which iterate over a variable, these can be

* a `Tables.jl` compatible object with row iteration support (e.g., A `DataFrame`, a tuple of named tuples, ...)
* a vector or tuple (in which case "`.`" is used to match


### Templates and tokens

A template is parsed into tokens. The `render` function combines the tokens with the view to create the output.

* Parsing is done at compile time, if the `mt` string literal is used to define the template. If re-using a template, this is encouraged, as it will be more performant.

* If string interpolation is desired prior to the parsing into tokens, the `jmt` string literal can be used.

* As well, a string can be used to define a template. When `parse` is called, the string will be parsed into tokens. This is the flow if `render` is called on a string (and not tokens).




### Variables

Tags representing variables for substitution have the form `{{varname}}`,
`{{:symbol}}`, or their triple-braced versions `{{{varname}}}` or
`{{{:symbol}}}`.


The `varname` version will match variables in a view such as a dictionary or a module.

The `:symbol` version will match variables passed in via named tuple or keyword arguments.

```julia
b = "be"
Mustache.render(mt"a {{b}} c", Main)  # "a be c"
Mustache.render(mt"a {{:b}} c", b="bee") # "a bee c"
Mustache.render(mt"a {{:b}} c", (b="bee", c="sea")) # "a bee c"
```


The triple brace prevents HTML substitution for
entities such as `<`. The following are escaped when only double
braces are used: "&", "<", ">", "'", "\", and "/".

```julia
Mustache.render(mt"a {{:b}} c", b = "%< bee >%")   # "a %&lt; bee &gt;% c"
Mustache.render(mt"a {{{:b}}} c", b = "%< bee >%") # "a %< bee >% c"
```

If different tags are specified to `parse`,
say `<<` or `>>`, then `<<{` and `}>>` indicate the prevention of substitution.

```julia
tokens = Mustache.parse("a <<:b>> c", ("<<", ">>"))
Mustache.render(tokens, b = "%< B >%")  # a %&lt; B &gt;% c"

tokens = Mustache.parse("a <<{:b}>> c", ("<<", ">>"))
Mustache.render(tokens, b = "%< B >%")  # "a %< B >% c"
```


If the variable refers to a function, the value will be the result of
calling the function with no arguments passed in.

```julia
Mustache.render(mt"a {{:b}} c", b = () -> "Bea")  # "a Bea c"
```

```julia
using Dates
Mustache.render(mt"Written in the year {{:yr}}."; yr = year∘now) # "Written in the year 2023."
```

### Sections

In the main example, the template included:

```
{{#in_ca}}
Well, {{taxed_value}} dollars, after taxes.
{{/in_ca}}
```

Tags beginning with `#varname` and closed with `/varname` create
"sections."  These have different behaviors depending on the value of
the variable. When the variable is not a function or a container the
part between them is used only if the variable is defined and not
"falsy:"

```julia
a = mt"{{#:b}}Hi{{/:b}}";
a(; b=true) # "Hi"
a(; c=true) # ""
a(; b=false) # "" also, as `b` is "falsy" (e.g., false, nothing, "")
```

If the variable name refers to a function that function will be passed
the unevaluated string within the section, as expected by the Mustache
specification:

```julia
Mustache.render("{{#:a}}one{{/:a}}", a=length)  # "3"
```

The specification has been widened to accept functions of two arguments, the string and a render function:

```julia
tpl = mt"{{#:bold}}Hi {{:name}}.{{/:bold}}"
function bold(text, render)
    "<b>" * render(text) * "</b>"
end
tpl(; name="Tater", bold=bold) # "<b>Hi Tater.</b>"
```



If the tag "|" is used, the section value will be rendered first, an enhancement to the specification.

```julia
fmt(txt) = "<b>" * string(round(parse(Float64, txt), digits=2)) * "</b>";
tpl = """{{|:lambda}}{{:value}}{{/:lambda}} dollars.""";
Mustache.render(tpl, value=1.23456789, lambda=fmt)  # "<b>1.23</b> dollars."
```

(Without the `|` in the tag, an error, `ERROR: ArgumentError: cannot parse "{{:value}}" as Float64`, will be thrown.)



### Inverted

Related, if the tag begins with `^varname` and ends with `/varname`
the text between these tags is included only if the variable is *not*
defined or is `falsy`.


### Iteration

If the section variable, `{{#varname}}`, binds to an iterable
collection, then the text in the section is repeated for each item in
the collection with the view used for the context of the template
given by the item.

This is useful for collections of named objects, such as DataFrames
(where the collection is comprised of rows) or arrays of
dictionaries. For `Tables.jl` objects the rows are iterated over.

For data frames, the variable names are specified as
symbols or strings. Here is a template for making a web page:

```julia
tpl = mt"""
<html>
<head>
<title>{{:TITLE}}</title>
</head>
<body>
<table>
<tr><th>name</th><th>summary</th></tr>
{{#:D}}
<tr><td>{{:names}}</td><td>{{:summs}}</td></tr>
{{/:D}}
</body>
</html>
"""
```
This can be used to generate a web page for `varinfo`-like values:

```julia
_names = String[]
_summaries = String[]
for s in sort(map(string, names(Main)))
    v = Symbol(s)
    if isdefined(Main,v)
        push!(_names, s)
        push!(_summaries, summary(eval(v)))
    end
end

using DataFrames
d = DataFrame(names=_names, summs=_summaries)

out = Mustache.render(tpl, TITLE="A quick table", D=d)
print(out)
```


This can be compared to using an array of `Dict`s, convenient if you have data by the row:

```julia
A = [Dict("a" => "eh", "b" => "bee"),
     Dict("a" => "ah", "b" => "buh")]
tpl = mt"{{#:A}}Pronounce a as {{a}} and b as {{b}}. {{/:A}}"
Mustache.render(tpl, A=A) |> print
```

yielding

```
Pronounce a as eh and b as bee. Pronounce a as ah and b as buh.
```

The same approach can be made to make a LaTeX table from a data frame:

```julia

function df_to_table(df, label="label", caption="caption")
    fmt = repeat("c", size(df,2))
    header = join(string.(names(df)), " & ")
    row = join(["{{:$x}}" for x in map(string, names(df))], " & ")

tpl="""
\\begin{table}
  \\centering
  \\begin{tabular}{$fmt}
  $header\\\\
{{#:DF}}    $row\\\\
{{/:DF}}  \\end{tabular}
  \\caption{$caption}
  \\label{tab:$label}
\\end{table}
"""

    Mustache.render(tpl, DF=df)
end
```

In the above, a string is used above -- and not a `mt` macro -- so that string
interpolation can happen. The `jmt_str` string macro allows for substitution, so the above template could also have been more simply written as:

```julia
function df_to_table(df, label="label", caption="caption")
    fmt = repeat("c", size(df,2))
    header = join(string.(names(df)), " & ")
    row = join(["{{:$x}}" for x in map(string, names(df))], " & ")

tpl = jmt"""
\begin{table}
  \centering
  \begin{tabular}{$fmt}
  $header\\
{{#:DF}}    $row\\
{{/:DF}}  \end{tabular}
  \caption{$caption}
  \label{tab:$label}
\end{table}
"""

    Mustache.render(tpl, DF=df)
end
```

#### Iterating over vectors

Though it isn't part of the Mustache specification, when iterating
over an unnamed vector or tuple, `Mustache.jl uses` `{{.}}` to refer to the item:

```julia
tpl = mt"{{#:vec}}{{.}} {{/:vec}}"
Mustache.render(tpl, vec = ["A1", "B2", "C3"])  # "A1 B2 C3 "
```

Note the extra space after `C3`.

There is also *limited* support for indexing with the iteration of a vector that
allows one to treat the last element differently. The syntax `.[ind]`
refers to the value `vec[ind]`. (There is no support for the usual
arithmetic on indices.)

To print commas one can use this pattern:

```julia
tpl = mt"{{#:vec}}{{.}}{{^.[end]}}, {{/.[end]}}{{/:vec}}"
Mustache.render(tpl, vec = ["A1", "B2", "C3"])  # "A1, B2, C3"
```

To put the first value in bold, but no others, say:

```julia
tpl = mt"""
{{#:vec}}
{{#.[1]}}<bold>{{.}}</bold>{{/.[1]}}
{{^.[1]}}{{.}}{{/.[1]}}
{{/:vec}}
"""
Mustache.render(tpl, vec = ["A1", "B2", "C3"])  # basically "<bold>A1</bold>B2 C3"
```

This was inspired by
[this](http://stackoverflow.com/questions/11147373/only-show-the-first-item-in-list-using-mustache)
question, but the syntax chosen was more Julian. This syntax -- as
implemented for now -- does not allow for iteration. That is
constructs like `{{#.[1]}}` don't introduce iteration, but only offer
a conditional check.

### Iterating when the value of a section variable is a function

From the Mustache documentation, consider the template

```julia
tpl = mt"{{#:beatles}}
* {{:name}}
{{/:beatles}}"
```

when `beatles` is a vector of named tuples (or some other `Tables.jl` object) and `name` is a function.

When iterating over `beatles`, `name` can reference the rows of the `beatles` object by name. In `JavaScript`, this is done with `this.XXX`. In `Julia`, the values are stored in the `task_local_storage` object (with symbols as keys) allowing the access. The `Mustache.get_this` function allows `JavaScript`-like usage:

```julia
function name()
    this = Mustache.get_this()
    this.first * " " * this.last
end
beatles = [(first="John", last="Lennon"), (first="Paul", last="McCartney")]

tpl(; beatles, name) # "* John Lennon\n* Paul McCartney\n"
```


### Conditional checking without iteration

The section tag, `#`, check for existence; pushes the object into the view; and then iterates over the object. For cases where iteration is not desirable; the tag type `@` can be used.

Compare these:

```julia
julia> struct RANGE
  range
end

julia> tpl = mt"""
<input type="range" {{@:range}} min="{{start}}" step="{{step}}" max="{{stop}}" {{/:range}}>
""";

julia> Mustache.render(tpl, RANGE(1:1:2))
"<input type=\"range\"  min=\"1\" step=\"1\" max=\"2\" >\n"

julia> tpl = mt"""
<input type="range" {{#:range}} min="{{start}}" step="{{step}}" max="{{stop}}" {{/:range}}>
""";

julia> Mustache.render(tpl, RANGE(1:1:2)) # iterates over Range.range
"<input type=\"range\"  min=\"1\" step=\"1\" max=\"2\"  min=\"1\" step=\"1\" max=\"2\" >\n"
```

### Non-eager finding of values

A view might have more than one variable bound to a symbol. The first one found is replaced in the template *unless* the variable is prefaced with `~`. This example illustrates:

```julia
d = Dict(:two=>Dict(:x=>3), :x=>2)
tpl = mt"""
{{#:one}}
{{#:two}}
{{~:x}}
{{/:two}}
{{/:one}}
"""
Mustache.render(tpl, one=d) # "2\n"
Mustache.render(tpl, one=d, x=1) # "1\n"
```

Were `{{:x}}` used, the value `3` would have been found within the dictionary `Dict(:x=>3)`; however, the presence of `{{~:x}}` is an instruction to keep looking up in the specified view to find other values, and use the last one found to substitute in. (This is hinted at in [this issue](https://github.com/janl/mustache.js/issues/399))

### Partials

Partials are used to include partial templates into a template.

Partials begin with a greater than sign, like `{{> box.tpl }}`. In this example, the file `box.tpl` is opened and inserted into the template, then populated. A full path may be specified.

They also inherit the calling context.

In this way you may want to think of partials as includes, imports,
template expansion, nested templates, or subtemplates, even though
those aren't literally the case here.

The partial specified by `{{< box.tpl }}` is not parsed, rather included as is into the file. This can be faster.


The variable can be a filename, as indicated above, or if not a variable. For example

```julia
julia> tpl = """\"{{>partial}}\""""
"\"{{>partial}}\""

julia> Mustache.render(tpl, Dict("partial"=>"*{{text}}*","text"=>"content"))
"\"*content*\""
```

### Summary of tags

To summarize the different tags marking a variable:


* `{{variable}}` does substitution of the value held in `variable` in the current view; escapes HTML characters
* `{{{variable}}}` does substitution of the value held in `variable` in the current view; does not escape HTML characters. The outer pair of mustache braces can be adjusted using `Mustache.parse`.
* `{{&variable}}` is an alternative syntax for triple braces (useful with custom braces)
* `{{~variable}}` does substitution of the value held in `variable` in the outmost view
* `{{#variable}}` depending on the type of variable, does the following:
   - if `variable` is not a functions container and is not absent or
     `nothing` will use the text between the matching tags, marked
     with `{{/variable}}`; otherwise that text will be skipped. (Like
     an `if/end` block.)
   - if `variable` is a function, it will be applied to contents of
     the section. Use of `|` instead of `#` will instruct the
     rendering of the contents before applying the function. The spec
     allows for a function to have signature `(x, render)` where `render` is
     used internally to convert. This implementation allows rendering
     when `(x)` is the single argument.
   - if `variable` is a `Tables.jl` compatible object (row wise, with
     named rows), will iterate over the values, pushing the named
     tuple to be the top-most view for the part of the template up to
     `{{\variable}}`.
   - if `variable` is a vector or tuple -- for the part of the
     template up to `{{\variable}}` -- will iterate over the
     values. Use `{{.}}` to refer to the (unnamed) values. The values
     `.[end]` and `.[i]`, for a numeric literal, will refer to values
     in the vector or tuple.
* `{{^variable}}`/`{{.variable}}` tags will show the values when `variable` is not defined, or is `nothing`.
* `{{>partial}}` will include the partial value into the template, filling in the template using the current view. The partial can be a variable or a filename (checked with `isfile`).
* `{{<partial}}` directly include partial value into template without filling in with the current view.
* `{{!comment}}` comments begin with a bang, `!`

## Alternatives

`Julia` provides some alternatives to this package which are better
suited for many jobs:

* For simple substitution inside a string there is string
  [interpolation](https://docs.julialang.org/en/latest/manual/strings/).

* For piecing together pieces of text either the `string` function or
  string concatenation (the `*` operator) are useful. (Also an
  `IOBuffer` is useful for larger tasks of this type.)

* For formatting numbers and text, the
  [Formatting.jl](https://github.com/JuliaLang/Formatting.jl) package,
  the [Format](https://github.com/JuliaString/Format.jl) package, and the
  [StringLiterals](https://github.com/JuliaString/StringLiterals.jl)
  package are available.

* The
  [HypertextLiteral](https://github.com/MechanicalRabbit/HypertextLiteral.jl)
  package is useful when interpolating HTML, SVG, or SGML tagged
  content.

## Differences from Mustache.js

This project deviates from Mustache.js in a few significant ways:


* Julia structures are used, not JavaScript objects. As illustrated,
  one can use Dicts, Modules, DataFrames, functions, ...

* In the Mustache spec, when lambdas are used as section names, the function is passed the unevaluated section:

```julia
template = "<{{#lambda}}{{x}}{{/lambda}}>"
data = Dict("x" => "Error!", "lambda" => (txt) ->  txt == "{{x}}" ? "yes" : "no")
Mustache.render(template, data) ## "<yes>", as txt == "{{x}}"
```

The tag "|" is similar to the section tag "#", but will receive the *evaluated* section:

```julia
template = "<{{|lambda}}{{x}}{{/lambda}}>"
data = Dict("x" => "Error!", "lambda" => (txt) ->  txt == "{{x}}" ? "yes" : "no")
Mustache.render(template, data) ## "<no>", as "Error!" != "{{x}}"
```

## API

```@autodocs
Modules = [Mustache]
```
