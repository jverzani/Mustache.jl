Try to make mustache.js for `julia`

This code is a fairly faithful translation of code of https://github.com/janl/mustache.js/blob/master/mustache.js 

All credit should go there. All bugs are my own.

The mustache folks say:

    Mustache is a logic-less template syntax. It can be used for HTML,
    config files, source code - anything. It works by expanding tags in a
    template using values provided in a hash or object.

Some basic examples with `julia`:

```julia
using Mustache; 

tpl = "the position is {{x}} and tail is  {{y}}"

## a dict
out = Mustache.render(tpl, {"x"=>1, "y"=>2})
println(out)
```

Yields

```julia
the position is 1 and tail is  2
```

(Should `render` be exported, I don't really think so, as it is too generic.)

Similarly, we can do this with a module, such as `Main`:

```julia
x = 1; y = "two"
Mustache.render(tpl, Main)
```

gives

```julia
"the position is 1 and tail is  two"
```

One can use Composite Kinds. This may make writing `show` methods easier:

```julia
using Distributions
tpl = "Beta distribution with alpha={{alpha}}, beta={{beta}}"
Mustache.render(tpl, Beta(1, 2))
```

gives

```julia
"Beta distribution with alpha=1.0, beta=2.0"
```

One can iterate over data frames. Here is a template for making a web page:

```julia
tpl = "
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
"
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
d = DataFrame({"names" => _names, "summs" => _summaries})

out = Mustache.render(tpl, {"Title" => "A quick table", "d" => d})
print(out)
```



This project deviates from that of http://mustache.github.com in a few significant ways:

* I've punted on the partials. I've never been that fancy.
* I hard code the tags
* Julian structures are used, not JavaScript objects. As illustrated,
  one can use Dicts, Modules, DataFrames





