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
@test Mustache.render(tpl, d) == "<b>Willy is awesome.\n</b>"

## Test of using Dict in {{#}}/{{/}} things
tpl = mt"{{#:d}}{{x}} and {{y}}{{/:d}}"
d = Dict(); d["x"] = "salt"; d["y"] = "pepper"
@test Mustache.render(tpl, d=d) == "salt and pepper"

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
@test Mustache.render(tpl, d) == expected


## Test with Named Tuples as a view
tpl = "{{#:NT}}{{:a}} and {{:b}}{{/:NT}}"
expected = "eh and bee"
@test Mustache.render(tpl, NT=(a="eh", b="bee")) == expected

expected = "eh and "
@test Mustache.render(tpl, NT=(a="eh",)) == expected

## Test with a Table interface
nt = (a="eh", b="bee", c="see")
rt = [nt, nt, nt] # Tables.istable(rt) == true
expected =  "eh and bee"^3
@test Mustache.render(tpl, NT=rt) == expected

## test render_from_file
expected = "Testing 1, 2, 3..."
@test render_from_file(joinpath(@__DIR__, "test.tpl"), (one="1", two="2", three="3")) == expected
@test render_from_file(joinpath(@__DIR__, "test.tpl"), one="1", two="2", three="3") == expected

filepath = joinpath(@__DIR__, "test-sections-lf.tpl")
@test Mustache.render_from_file(filepath, Dict("a"=>Dict("x"=>111,),)) == """    111\n"""
@test Mustache.render_from_file(filepath, Dict("y"=>222,)) == "    222\n"

filepath = joinpath(@__DIR__, "test-sections-crlf.tpl")
@test Mustache.render_from_file(filepath, Dict("a"=>Dict("x"=>111,),)) == "    111\r\n"
@test Mustache.render_from_file(filepath, Dict("y"=>222,)) == "    222\r\n"

@testset "closed issues" begin

    ## issue #51 inverted section
    @test Mustache.render("""{{^repos}}No repos :({{/repos}}""", Dict("repos" => [])) == "No repos :("
    @test Mustache.render("{{^repos}}foo{{/repos}}",Dict("repos" => [Dict("name" => "repo name")])) == ""


    ## Issue #80 with 0 as falsy
    tpl = "this is {{:zero}}"
    @test render(tpl, zero=0) == "this is 0"


    ## Issue 88
    template = "{{#:vec}}{{.}}{{^.[end]}},{{/.[end]}}{{/:vec}}";
    @test render(template, vec=["a", "b", "c"]) == "a,b,c"
    @test render(template, vec=fill("a", 3)) == "a,a,a"

    ## Issue 91 handle istable without a schema. (Is getfield a general enough solution?)
    tpl = "{{#list}}{{ item }} {{/list}}"
    v = Dict("list"  => Any[Dict("item" => "one"),Dict("item" => "two")])
    @test Mustache.render(tpl, v) == "one two "
end
