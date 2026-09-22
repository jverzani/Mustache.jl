# Mustache.jl

Documentation for [Mustache.jl](https://github.com/jverzani/Mustache.jl).


## Examples

Following the main [documentation](http://mustache.github.io/mustache.5.html) for `Mustache.js` we have a "typical Mustache template" defined by:


```@example mustache
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

```@example mustache
d = Dict(
"name" => "Chris",
"value" => 10000,
"taxed_value" => 10000 - (10000 * 0.4),
"in_ca" => true)

Mustache.render(tpl, d) |> print
```

The `render` function pieces things together. Like `print`, the first
argument is for an optional `IO` instance. In the above example, where
one is not provided, a string is returned. (The `print` call is for formatting purposes.)

The flow is

* a template is parsed into tokens by `Mustache.parse`. This can be called directly, indirectly through the non-standard string literal `mt`, the non-standard string literal `jmt` (which allows for string interpolation), or when loading a file with `Mustache.load`. The templates use tags comprised of matching mustaches (`{}`), either two or three, to indicate a value to be substituted for. These particular symbols indicating tags may be adjusted when `parse` is called.

* The tokens and a view are `render`ed into a string. The `render` function takes tokens as its second argument. If this argument is a string, `parse` is called internally. The `render` function than reassambles the template, substituting values, as appropriate, from the "view" passed to it and writes the output to the specified `io` argument.


There are only 4 exports: `mt` and `jmt` (string literals to specify a template), `render`, and `render_from_file`.


The view used to provide values to substitute into the template can be
specified in a variety of ways. The above example used a dictionary. A
Module may also be used, such as `Main`:


```@example mustache
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

```@example mustache
goes_together = mt"{{{:x}}} and {{{:y}}}."
Mustache.render(goes_together; x="Salt", y="pepper")
Mustache.render(goes_together; x="Bread", y="butter")
```

`MustacheTokens` objects are functors; keyword arguments can also be passed to a `Tokens` object directly which resolves to calling `render`:

```@example mustache
goes_together = mt"{{{:x}}} and {{{:y}}}."
goes_together(; x="Fish", y="chips")
```



Similarly, a named tuple may be used as a view.  As well, one can use
Composite Kinds. This may make writing `show` methods easier:

```@example mustache
using Distributions
tpl = "Beta distribution with alpha={{α}}, beta={{β}}"
Mustache.render(tpl, Beta(1, 2))
```

gives

```
"Beta distribution with alpha=1.0, beta=2.0"
```

## The pipeline

A template is specified and rendered with values coming from a view. This section gives a more detail.

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
* a vector or tuple (in which case "`.`" is used to match)


### Templates and tokens

A template is parsed into tokens.

* Parsing is done at compile time, if the `mt` string literal is used to define the template. If re-using a template, this is encouraged, as it will be more performant.

```@example mustache
mt"""
{{:x}} is  {{:y}}
"""
```

* If string interpolation is desired prior to the parsing into tokens, the `jmt` string literal can be used.

```@example mustache
x = "John"
jmt"""
$x is {{:y}}
"""
```

* As well, a string can be used to define a template. When `parse` is called, the string will be parsed into tokens. This is the flow if `render` is called on a string (and not tokens).




### Tags

Tags representing variables for substitution have the form `{{varname}}`,
`{{:symbol}}`, or their triple-braced versions `{{{varname}}}` or
`{{{:symbol}}}`.


The `varname` version will match variables in a view such as a dictionary or a module.

The `:symbol` version will match variables passed in via named tuple or keyword arguments.

```@example mustache
b = "be"
Mustache.render(mt"a {{b}} c", Main)  # "a be c"
Mustache.render(mt"a {{:b}} c", b="bee") # "a bee c"
Mustache.render(mt"a {{:b}} c", (b="bee", c="sea")) # "a bee c"
```


The triple brace prevents HTML substitution for
entities such as `<`. The following are escaped when only double
braces are used: "&", "<", ">", "'", "\", and "/".

```@example mustache
Mustache.render(mt"a {{:b}} c", b = "%< bee >%")   # "a %&lt; bee &gt;% c"
Mustache.render(mt"a {{{:b}}} c", b = "%< bee >%") # "a %< bee >% c"
```

If different tags are specified to `parse`,
say `<<` or `>>`, then `<<{` and `}>>` indicate the prevention of substitution.

```@example mustache
tokens = Mustache.parse("a <<:b>> c", ("<<", ">>"))
Mustache.render(tokens, b = "%< B >%")  # a %&lt; B &gt;% c"

tokens = Mustache.parse("a <<{:b}>> c", ("<<", ">>"))
Mustache.render(tokens, b = "%< B >%")  # "a %< B >% c"
```


If the variable refers to a function, the value will be the result of
calling the function with no arguments passed in.

```@example mustache
Mustache.render(mt"a {{:b}} c", b = () -> "Bea")  # "a Bea c"
```

```@example mustache
using Dates
Mustache.render(mt"Written in the year {{:yr}}."; yr = year∘now) # "Written in the year 2023."
```

#### Filtering

This isn't part of the Mustache spec, but a filter can be applied to the value after it is looked up and before it is rendered. The tag syntax uses a semicolon, `:` to disambiguate the variable from its filter, as in `{{:varname; functionname}}`. The named function is looked up in the same view (or `Main`, then `Base` if not found) and is
called with the resolved value.

```@example mustache
Mustache.render(mt"Hello {{:name; uppercase}}!", name="world", uppercase=uppercase)
```

Inline anonymous functions are accepted too:

```@example mustache
Mustache.render(mt"Hello {{:name; x -> uppercase(x)}}!", name="world")
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
the variable.

#### Using a true(ish) value to conditionally display a section

When the variable is not a function or a container the
part between them is used only if the variable is defined and not
"falsy:"

```@example mustache
a = mt"{{#:b}}Hi{{/:b}}";
a(; b=true) # "Hi"
a(; c=true) # ""
a(; b=false) # "" also, as `b` is "falsy" (e.g., false, nothing, "")
```

##### Inverted

Related, if the tag begins with `^varname` and ends with `/varname`
the text between these tags is included only if the variable is *not*
defined or is `falsy`.

#### Using a function to modify the string within a section

If the variable name refers to a function that function will be passed
the unevaluated string within the section, as expected by the Mustache
specification:

```@example mustache
Mustache.render("{{#:a}}one{{/:a}}", a=length)  # "3"
```

The specification has been widened to accept functions of two arguments, the string and a render function:

```@example mustache
tpl = mt"{{#:bold}}Hi {{:name}}.{{/:bold}}"
function bold(text, render)
    "<b>" * render(text) * "</b>"
end
tpl(; name="Tater", bold=bold) # "<b>Hi Tater.</b>"
```



If the tag "|" is used, the section value will be rendered first, an enhancement to the specification.

```@example mustache
fmt(txt) = "<b>" * string(round(parse(Float64, txt), digits=2)) * "</b>";
tpl = """{{|:lambda}}{{:value}}{{/:lambda}} dollars.""";
Mustache.render(tpl, value=1.23456789, lambda=fmt)  # "<b>1.23</b> dollars."
```

(Without the `|` in the tag, an error, `ERROR: ArgumentError: cannot parse "{{:value}}" as Float64`, will be thrown.)


#### Iteration in a section

If the section variable, `{{#varname}}`, binds to an iterable
collection, then the text in the section is repeated for each item in
the collection with the view used for the context of the template
given by the item.

This is useful for collections of named objects, such as DataFrames
(where the collection is comprised of rows) or arrays of
dictionaries. For `Tables.jl` objects the rows are iterated over.

##### Iterating over vectors

Iterating over a associative array, like a dictionary or named tuple, the keys are used as variable name.
Though it isn't part of the Mustache specification, when iterating
over a vector or tuple---which have no obvious key save for index---`Mustache.jl uses` `{{.}}` to refer to the item:

```@example mustache
tpl = mt"{{#:vec}}{{.}} {{/:vec}}"
Mustache.render(tpl, vec = ["A1", "B2", "C3"])  # "A1 B2 C3 "
```

Note the extra space after `C3`.

There is also *limited* support for indexing with the iteration of a vector that
allows one to treat the last element differently. The syntax `.[ind]`
refers to the value `vec[ind]`. (There is no support for the usual
arithmetic on indices.)

To print commas one can use this pattern:

```@example mustache
tpl = mt"{{#:vec}}{{.}}{{^.[end]}}, {{/.[end]}}{{/:vec}}"
Mustache.render(tpl, vec = ["A1", "B2", "C3"])  # "A1, B2, C3"
```

To put the first value in bold, but no others, say:

```@example mustache
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

##### Iterating over DataFrames or other Tables compatible objects

For data frames, the rows are iterated over. Data frames in `Julia` have named columns, not rows.
Here is a template for making a markdown table from a data frame.
It uses a filter to process the unnamed values of an iterable.

```@example mustache
tpl = mt"""
|{{:d; x -> join(names(x), " |")}}|
|{{:d; r -> join(repeat([":----|"], size(r,2)))}}
{{#:d}}
|{{#.}}{{.}}|{{/.}}
{{/:d}}
: {{:TITLE}}
"""
```



We illustrate on some synthetic data.

```julia
using DataFrames
d = DataFrame(names=["John", "Paul", "George", "Ringo"], hand=["right", "left", "right", "right"])
tpl(; d, TITLE="dominant hand") |> print
```


This can be compared to using an array of `Dict`s, convenient if you have data by the row:

```@example mustache
A = [Dict("a" => "eh", "b" => "bee"),
     Dict("a" => "ah", "b" => "buh")]
tpl = mt"{{#:A}}Pronounce a as {{a}} and b as {{b}}. {{/:A}}"
Mustache.render(tpl, A=A) |> print
```

### Iterating when the value of a section variable is a function

From the Mustache documentation, consider the template

```@example mustache
tpl = mt"""{{#:beatles}}
* {{:makename}}
{{/:beatles}}
"""
```

when `beatles` is a vector of named tuples (or some other `Tables.jl` object) and `name` is a function.

When iterating over `beatles`, `name` can reference the rows of the `beatles` object by name. In `JavaScript`, this is done with `this.XXX`. In `Julia`, the values are stored in the `task_local_storage` object (with symbols as keys) allowing the access. The `Mustache.get_this` function allows `JavaScript`-like usage:

```@example mustache
function makename()
    this = Mustache.get_this()
    this.first * " " * this.last
end
beatles = [(first="John", last="Lennon"), (first="Paul", last="McCartney")]

tpl(; beatles, makename) |> print
```


#### Conditional checking without iteration

The section tag, `#`, check for existence; pushes the object into the view; and then iterates over the object. For cases where iteration is not desirable; the tag type `@` can be used.

Compare these:

```@example mustache
struct RANGE
  range
end

tpl = mt"""
<input type="range" {{@:range}} min="{{start}}" step="{{step}}" max="{{stop}}" {{/:range}}>
""";

Mustache.render(tpl, RANGE(1:1:2))

tpl = mt"""
<input type="range" {{#:range}} min="{{start}}" step="{{step}}" max="{{stop}}" {{/:range}}>
""";

Mustache.render(tpl, RANGE(1:1:2)) # iterates over Range.range
```



### Additional features

#### Non-eager finding of values

A view might have more than one variable bound to a symbol. The first one found is replaced in the template *unless* the variable is prefaced with `~`. This example illustrates:

```@example mustache
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

#### Partials

Partials are used to include partial templates into a template.

Partials begin with a greater than sign, like `{{> box.tpl }}`. In this example, the file `box.tpl` is opened and inserted into the template, then populated. A full path may be specified.

They also inherit the calling context.

In this way you may want to think of partials as includes, imports,
template expansion, nested templates, or subtemplates, even though
those aren't literally the case here.

The partial specified by `{{< box.tpl }}` is not parsed, rather included as is into the file. This can be faster.


The variable can be a filename, as indicated above, or if not a variable. For example

```@example mustache
tpl = """\"{{>partial}}\""""

Mustache.render(tpl, Dict("partial"=>"*{{text}}*","text"=>"content"))
```

## Summary of tags

To summarize the different tags marking a variable or container:


* `{{variable}}` does substitution of the value held in `variable` in the current view; escapes HTML characters. The double braces can be adjusted using `Mustache.parse`.
* `{{{variable}}}` does substitution of the value held in `variable` in the current view; does not escape HTML characters. The outer pair of mustache braces can be adjusted using `Mustache.parse`.
* `{{&variable}}` is an alternative syntax for triple braces (useful with custom braces)
* `{{~variable}}` does substitution of the value held in `variable` in the outmost view
* `{{#variable}}` is section syntax. Sections are closed by `{{/variable}}`. Depending on the type of variable, it specifies the following:
   - if `variable` is not a container or a function and is not absent or
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
   - if `variable` is a vector or tuple---for the part of the
     template up to `{{\variable}}`---will iterate over the
     values. Use `{{.}}` to refer to the (unnamed) values. The values
     `.[end]` and `.[i]`, for a numeric literal, will refer to values
     in the vector or tuple. For tabular data, `{{.}}` can also be iterated over.
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

```@example mustache
template = "<{{#lambda}}{{x}}{{/lambda}}>"
data = Dict("x" => "Error!", "lambda" => (txt) ->  txt == "{{x}}" ? "yes" : "no")
Mustache.render(template, data) ## "<yes>", as txt == "{{x}}"
```

The tag "|" is similar to the section tag "#", but will receive the *evaluated* section:

```@example mustache
template = "<{{|lambda}}{{x}}{{/lambda}}>"
data = Dict("x" => "Error!", "lambda" => (txt) ->  txt == "{{x}}" ? "yes" : "no")
Mustache.render(template, data) ## "<no>", as "Error!" != "{{x}}"
```

Tags referencing variables can have a filter applied:

```@example mustache
tpl = mt"""
{{:x}} --> {{:x; uppercasefirst}} --> {{:x; x-> uppercase(x[1:2]) * x[3:end]}} --> {{:x; uppercase}}
"""
tpl(; x = "boo")  |> print
```

## API

```@autodocs
Modules = [Mustache]
```
