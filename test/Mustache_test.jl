using Mustache
using Test

tpl = mt"a:{{x}} b:{{{y}}}"

x, y = "ex", "why"
d = Dict("x"=>"ex", "y"=>"why")
mutable struct ThrowAway
    x
    y
end

struct Issue123
    range
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

d = Dict("name" => "Willy", "wrapped" => (txt, r) -> "<b>" * r(txt) * "</b>")
@test Mustache.render(tpl, d) == "<b>Willy is awesome.\n</b>"

# this shouldn't be "Willy", rather "{{name}}"
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

## If the value of a section key is a function, it is called with the section's literal block of text, un-rendered, as its first argument. The second argument is a special rendering function that uses the current view as its view argument. It is called in the context of the current view object.
tpl = mt"{{#:bold}}Hi {{:name}}.{{/:bold}}"
function bold(text, render)
    this = Mustache.get_this()
    "<b>" * render(text) * "</b>" * this.xtra
end
expected = "<b>Hi Tater.</b>Hi Willy."
@test Mustache.render(tpl; name="Tater", bold=bold, xtra = "Hi Willy.") == expected



## if the value of a section variable is a function, it will be called in the context of the current item in the list on each iteration.
tpl = mt"{{#:beatles}}
* {{:name}}
{{/:beatles}}"
function name()
    this = Mustache.get_this()
    this.first * " " * this.last
end
beatles = [(first="John", last="Lennon"), (first="Paul", last="McCartney")]
expected = "* John Lennon\n* Paul McCartney\n"
@test tpl(;beatles, name) == expected




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

## test load
filepath = joinpath(@__DIR__, "test.tpl")
expected = "Testing 1, 2, 3..."
@test render(Mustache.load(filepath),  (one="1", two="2", three="3")) == expected
@test render(Mustache.load(filepath), one="1", two="2", three="3") == expected

filepath = joinpath(@__DIR__, "test-sections-lf.tpl")
tokens = Mustache.load(filepath)
@test Mustache.render(tokens, Dict("a"=>Dict("x"=>111,),)) == """    111\n"""
@test Mustache.render(tokens, Dict("y"=>222,)) == "    222\n"

filepath = joinpath(@__DIR__, "test-sections-crlf.tpl")
tokens = Mustache.load(filepath)
@test Mustache.render(tokens, Dict("a"=>Dict("x"=>111,),)) == "    111\r\n"
@test Mustache.render(tokens, Dict("y"=>222,)) == "    222\r\n"


## Test of MustacheTokens being callable
tpl = mt"""Hello {{:name}}"""
@test tpl(name="world") == "Hello world"  # using kwargs...
@test tpl((name="world",)) == "Hello world" # using arg

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

    ## Issue 99 expose tags
    tpl = "<<#list>><< item >> <</list>>"
    v = Dict("list"  => Any[Dict("item" => "one"),Dict("item" => "two")])
    @test Mustache.render(tpl, v, tags=("<<", ">>")) == "one two "


    tpl = "[[#list]][[ item ]] [[/list]]"
    @test Mustache.render(tpl, v, tags=("[[", "]]")) == "one two "

    ## Issue 104, bad nesting (needed to pop context)
    tpl1 = mt"""
{{#nested.vec}}
{{.}}
{{/nested.vec}}
{{nested.foo}}
"""
tpl2 = mt"""
{{#nested}}
{{#vec}}
{{.}}
{{/vec}}
{{foo}}
{{/nested}}
{{nested.foo}}
"""
    data2 = Dict("nested" => Dict("vec" => [1,2], "foo" => "bar"))
    @test Mustache.render(tpl1, data2) == "1\n2\nbar\n"
    @test Mustache.render(tpl2, data2) == "1\n2\nbar\nbar\n"

    ##  Issue 114 Combine custom tags with no HTML escaping
    @test Mustache.render("\$[[{JL_VERSION_MATRIX}]]", Dict("JL_VERSION_MATRIX"=>"&"), tags=("\$[[","]]")) == "&"

    ## Issue fixed by PR #122
    tpl = """
{{#:vec}}{{#.[1]}}<bold>{{.}}</bold>{{/.[1]}}{{^.[1]}}{{.}} {{/.[1]}}{{/:vec}}
"""
    @test Mustache.render(tpl, vec = ["A1", "B2", "C3"]) == "<bold>A1</bold>B2 C3 \n"

    ##
    tpl = mt"""
<input type="range" {{@:range}} min="{{start}}" step="{{step}}" max="{{stop}}" {{/:range}}>
"""
    @test render(tpl, Issue123(1:2:3)) == "<input type=\"range\"  min=\"1\" step=\"2\" max=\"3\" >\n"


    ## Issue 124 regression test"
    tpl = mt"""
{{^dims}}<input type="text" value="">{{/dims}}
{{#dims}}<textarea {{#.[1]}}cols="{{.}}"{{/.[1]}} {{#.[2]}}rows="{{.}}"{{/.[2]}}></textarea>{{/dims}}
"""
    @test render(tpl, Dict("dims"=>missing)) == "<input type=\"text\" value=\"\">\n\n"
    @test render(tpl, Dict("dims"=>["1", "2"])) == "\n<textarea cols=\"1\" ></textarea><textarea  rows=\"2\"></textarea>\n"
    @test render(tpl, Dict("dims"=>("1", "2"))) == "\n<textarea cols=\"1\" ></textarea><textarea  rows=\"2\"></textarea>\n"
    @test render(tpl, Dict("dims"=>(1, 2))) == "\n<textarea cols=\"1\" ></textarea><textarea  rows=\"2\"></textarea>\n"
@test render(tpl, Dict("dims"=>1:2)) == "\n<textarea cols=\"1\" ></textarea><textarea  rows=\"2\"></textarea>\n"

   ## issue 128 global versus local
    d = Dict(:two=>Dict(:x=>3), :x=>2)
    tpl = mt"""
{{#:one}}
{{#:two}}
{{:x}}
{{/:two}}
{{/:one}}
"""
    @test render(tpl, one=d) == "3\n"

    tpl = mt"""
{{#:one}}
{{#:two}}
{{~:x}}
{{/:two}}
{{/:one}}
"""
    @test render(tpl, one=d) == "2\n"
    @test render(tpl, one=d, x=1) == "1\n"

    ## Issue #133 triple brace with }
    tpl = raw"\includegraphics{<<{:filename}>>}"
    tokens = Mustache.parse(tpl, ("<<",">>"))
    @test render(tokens, filename="XXX") == raw"\includegraphics{XXX}"

    # alternative is to use `&` to avoid escaping
    @test render(raw"\includegraphics{<<&:filename>>}", (filename="XXX",), #render(string, view;tags=...)
                 tags=("<<",">>")) == raw"\includegraphics{XXX}"


    ## jmt macro
    x = 1
    tpl = jmt"$(2x) by {{:a}}"
    @test tpl(a=2) == "2 by 2"


    ## Issue #139 -- mishandling of tables data with partials
    A = [Dict("a" => "eh", "b" => "bee"),
         Dict("a" => "ah", "b" => "buh")]
    tpl = mt"{{#:A}}Pronounce a as {{>:d}} and b as {{b}}. {{/:A}}"
    out1 = render(tpl, A=A, d="*{{a}}*")

    A = [Dict(:a => "eh", :b => "bee"),
         Dict(:a => "ah", :b => "buh")]
    tpl = mt"{{#:A}}Pronounce a as {{>:d}} and b as {{:b}}. {{/:A}}"
    out2 = render(tpl, A=A, d="*{{:a}}*")

    A = [(a = "eh", b = "bee"),
         (a = "ah", b = "buh")]
    tpl = mt"{{#:A}}Pronounce a as {{>:d}} and b as {{:b}}. {{/:A}}"
    out3 = render(tpl, A=A, d="*{{:a}}*")
    @test out1 == out2 == out3

    ## lookup in Tables compatible data
    ## find column
    tpl = mt"{{#:vec}}{{.}} {{/:vec}}"
    A = [(vec=1, a=2),
         (vec=2, a=3),
         (vec=3, a=4)]
    @test render(tpl, A) == "1 2 3 "

    ## Issue #143 look up key before checking for dotted
    @test render("Hello, {{ values.name }}!", Dict("values.name"=>"world")) == "Hello, world!"
end
