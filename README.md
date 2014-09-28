# Mustache

[![Build Status](https://travis-ci.org/jverzani/Mustache.jl.svg?branch=master)](https://travis-ci.org/jverzani/Mustache.jl)
[![Coverage Status](https://coveralls.io/repos/jverzani/Mustache.jl/badge.png)](https://coveralls.io/r/jverzani/Mustache.jl)
[![Mustache](http://pkg.julialang.org/badges/Mustache_release.svg)](http://pkg.julialang.org/?pkg=Mustache&ver=release)

[Mustache](http://mustache.github.io/) is 

    ... a logic-less template syntax. It can be used for HTML,
    config files, source code - anything. It works by expanding tags in a
    template using values provided in a hash or object.

This package ports over most of the [mustache.js](https://github.com/janl/mustache.js) implementation for use in [Julia](http://julialang.org). All credit should go there. All bugs are my own.

Some basic examples with `julia`:

```julia
using Mustache

tpl = mt"the position is {{x}} and tail is  {{y}}"

## a dict
render(tpl, {"x"=>1, "y"=>2})
```

Yields

```julia
the position is 1 and tail is  2
```

The first argument of `render` can be an `IO` instance.
If it is not given, then `sprint` is used to provide one.

The non-standard string literal `mt`, used above to make the `tpl`
object, is optional. If used, then the parsing is done at compile time
and should be faster when used in a loop, say. A triple-quoted form is also available.

Similarly, we can use a module as a view such as `Main`:

```julia
x = 1; y = "two"
render(tpl, Main)
```

gives

```julia
"the position is 1 and tail is  two"
```

Or, with a temporary module:

```julia
module TMP
  x = 1; y = "two"
end
render("{{x}} and {{y}}", TMP) |> println
```


One can use Composite Kinds. This may make writing `show` methods easier:

```julia
using Distributions
tpl = "Beta distribution with alpha={{alpha}}, beta={{beta}}"
render(tpl, Beta(1, 2))
```

gives

```julia
"Beta distribution with alpha=1.0, beta=2.0"
```

One can iterate over data frames. Here is a template for making a web page:

```julia
tpl = """
<html>
<head>
<title>{{Title}}</title>
</head>
<body>
<table>
<tr><th>name</th><th>summary</th></tr>
{{#d}}
<tr><td>{{names}}</td><td>{{summs}}</td></tr>
{{/d}}
</body>
</html>
"""
```
This can be used to generate a web page for `whos`-like values:

```julia
_names = Array(String, 0)
_summaries = Array(String, 0)
m = Main
for s in sort(map(string, names(m)))
    v = symbol(s)
    if isdefined(m,v)
        push!(_names, s)
        push!(_summaries, summary(eval(m,v)))
    end
end

using DataFrames
d = DataFrame(names=_names, summs=_summaries)

out = render(tpl, {"Title" => "A quick table", "d" => d})
print(out)
```


This can be compared to using an array of `Dict`s, convenient if you have data by the row:

```julia
A = [{"a" => "eh", "b" => "bee"},
     {"a" => "ah", "b" => "buh"}]
tpl = mt"{{#A}}Pronounce a as {{a}} and b as {{b}}. {{/A}}"
render(tpl, {"A" => A}) |> print
```

yielding

```julia
Pronounce a as eh and b as bee. Pronounce a as ah and b as buh.
```


This project deviates from that of http://mustache.github.com in a few significant ways:

* The partials tag (the `>` tag) is not implemented.
* The tags are only demarked with `{{` and `}}`.
* Julian structures are used, not JavaScript objects. As illustrated,
  one can use Dicts, Modules, DataFrames