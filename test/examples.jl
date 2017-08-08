## Some simple tests of the package

using Mustache
mtrender = render

tpl = mt"the value of x is {{x}} and that of y is {{y}}"

## a dict
out = mtrender(tpl, Dict("x"=>1, "y"=>2))
println(out)

## A module
x = 1; y = "two"
mtrender(tpl, Main)

## a CompositeKind
mutable struct ThrowAway
    x
    y
end

mtrender(tpl, ThrowAway("ex","why"))


## a more useful CompositeKind
using Distributions
tpl = mt"Beta distribution with alpha={{alpha}}, beta={{beta}}"
mtrender(tpl, Beta(1, 2))


## conditional text
using Mustache
tpl = "{{#b}}this doesn't show{{/b}}{{#a}}this does show{{/a}}"
mtrender(tpl, Dict("a" => 1))



## We can iterate over data frames. Handy for making tables
using Mustache
using DataFrames


## SHow values in Main in a web page

_names = Array(String, 0)
_summaries = Array(String, 0)
m = Main
for s in sort(map(string, names(m)))
    v = Symbol(s)
    if isdefined(m,v)
        push!(_names, s)
        push!(_summaries, summary(eval(m,v)))
    end
end

using DataFrames
d = DataFrame(names = _names, summs = _summaries)

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

out = mtrender(tpl, {"Title" => "A quick table", "d" => d})
## show in browser (on Mac)
f = tempname()
io = open("$f.html", "w")
print(io, out)
close(io)
run(`open $f.html`)


## A dict using symbols
d = { :a => 1, :b => 2}
tpl = "symbol {{:a}} and {{:b}}"
mtrender(tpl, d)



## array of Dicts
using Mustache

A = [Dict("a" => "eh", "b" => "bee"),
     Dict("a" => "ah", "b" => "buh")]

## Contrast to data frame:
# D = DataFrame(quote
#   a = ["eh", "ah"]
#   b = ["bee", "buh"]
# end);

tpl = mt"{{#A}} pronounce a as {{a}} and b as {{b}}.{{/A}}"

mtrender(tpl, Dict("A" => A))


## use .[ind] to index within a vector:

tpl = mt"{{#:vec}}{{.[1]}}{{/:vec}}" # just first one
mtrender(tpl, vec=["A1","B2","C3"])

tpl = mt"{{#:vec}}{{.}}{{^.[end]}}, {{/.[end]}}{{/:vec}}" # serial commas
mtrender(tpl, vec=["A1","B2","C3"])
