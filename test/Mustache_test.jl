using Mustache
using Test

tpl = mt"a:{{x}} b:{{{y}}}"

x, y = "ex", "why"
d = Dict("x"=>"ex", "y"=>"why")
mutable struct ThrowAway
    x
    y
end

@test render(tpl, Main) == "a:ex b:why"
@test render(tpl, d) == "a:ex b:why"
@test render(tpl, ThrowAway(x,y)) == "a:ex b:why"


## triple quoted
tpl = mt"""a:{{x}} b:{{y}}"""


@test render(tpl, Main) == "a:ex b:why"
@test render(tpl, d) == "a:ex b:why"
@test render(tpl, ThrowAway(x,y)) == "a:ex b:why"

## conditional
tpl = "{{#b}}this doesn't show{{/b}}{{#a}}this does show{{/a}}"
@test render(tpl, Dict("a" => 1)) == "this does show"

## dict using symbols
d = Dict(:a => x, :b => y)
tpl = "a:{{:a}} b:{{:b}}"
@test render(tpl, d) == "a:ex b:why"

## keyword args
@test render(tpl, a="ex", b="why") == "a:ex b:why"

## unicode
module TMP
α = 1
β = 2
end
@test render("{{α}} + 1 = {{β}}", TMP) == "1 + 1 = 2"
@test render("{{:β}}", β=2) == "2"
@test render("α - {{:β}}", β=2) == "α - 2"
@test render("{{:α}}", α="β") == "β"

## {{.}} test
tpl = mt"{{#:vec}}{{.}} {{/:vec}}"
@test render(tpl, vec=[1,2,3]) == "1 2 3 "

## test of function, see http://mustache.github.io/mustache.5.html (Lambdas)

tpl = mt"""{{#wrapped}}
{{name}} is awesome.
{{/wrapped}}
"""

d = Dict("name" => "Willy", "wrapped" => (txt) -> "<b>" * txt * "</b>")
@test_skip Mustache.render(tpl, d) == "<b>Willy is awesome.\n</b>"

## Test of using Dict in {{#}}/{{/}} things
tpl = mt"{{#:d}}{{x}} and {{y}}{{/:d}}"
d = Dict(); d["x"] = "salt"; d["y"] = "pepper"
@test Mustache.render(tpl, d=d) == "salt and pepper"

## issue #51 inverted section
@test Mustache.render("""{{^repos}}No repos :({{/repos}}""", Dict("repos" => [])) == "No repos :("    
@test Mustache.render("{{^repos}}foo{{/repos}}",Dict("repos" => [Dict("name" => "repo name")])) == ""


## Added a new tag "|" for applying a function to a section
tpl = """{{|lambda}}{{value}}{{/lambda}} dollars."""
d = Dict("value"=>"1.23456789", "lambda"=>(txt) -> "<b>" * string(round(parse(Float64, txt), digits=2)) * "</b>")
@test Mustache.render(tpl, d) == "<b>1.23</b> dollars."

tpl = """{{|lambda}}key{{/lambda}} dollars."""
d = Dict("lambda" => (txt) -> begin
         d = Dict("key" => "value")
         d[txt]
         end
         )
@test Mustache.render(tpl, d) == "value dollars."



## test nested section with filtering lambda
tpl = """
{{#lambda}}
{{#iterable}}
{{#iterable2}}
{{.}}
{{/iterable2}}
{{/iterable}}
{{/lambda}}
"""


d = Dict("iterable"=>Dict("iterable2"=>["a","b","c"]), "lambda"=>(txt) -> "XXX $txt XXX")
expected = "XXX a\nb\nc\n XXX"
@test_skip Mustache.render(tpl, d) == expected
