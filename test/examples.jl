## Some simple tests of the package

using Mustache; 

tpl = "the value of x is {{x}} and that of y is {{y}}"

## a dict
out = Mustache.render(tpl, {"x"=>1, "y"=>2})
println(out)

## A module
x = 1; y = "two"
Mustache.render(tpl, Main)

## a CompositeKind
type ThrowAway
    x
    y
end

Mustache.render(tpl, ThrowAway("ex","why"))


## a more useful CompositeKind
using Distributions
tpl = "Beta distribution with alpha={{alpha}}, beta={{beta}}"
Mustache.render(tpl, Beta(1, 2))


## conditional text
using Mustache
tpl = "{{#b}}this doesn't show{{/b}}{{#a}}this does show{{/a}}"
Mustache.render(tpl, {"a" => 1})



## iterable DataFrame
using Mustache
using DataFrames


## SHow values in Main in a web page

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
";

out = Mustache.render(tpl, {"Title" => "A quick table", "d" => d})
## show in browser (on Mac)
f = tempname()
io = open("$f.html", "w")
print(io, out)
close(io)
run(`open $f.html`)
