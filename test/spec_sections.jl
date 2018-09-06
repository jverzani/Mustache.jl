using Mustache
using Test

@testset " sections " begin


	## Truthy sections should have their contents rendered.
tpl = """\"{{#boolean}}This should be rendered.{{/boolean}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """\"This should be rendered.\""""

	## Falsey sections should have their contents omitted.
tpl = """\"{{#boolean}}This should not be rendered.{{/boolean}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """\"\""""

	## Objects and hashes should be pushed onto the context stack.
tpl = """\"{{#context}}Hi {{name}}.{{/context}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("context"=>Dict{Any,Any}("name"=>"Joe"))) == """\"Hi Joe.\""""

	## All elements on the context stack should be accessible.
tpl = """{{#a}}
{{one}}
{{#b}}
{{one}}{{two}}{{one}}
{{#c}}
{{one}}{{two}}{{three}}{{two}}{{one}}
{{#d}}
{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}
{{#e}}
{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}
{{/e}}
{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}
{{/d}}
{{one}}{{two}}{{three}}{{two}}{{one}}
{{/c}}
{{one}}{{two}}{{one}}
{{/b}}
{{one}}
{{/a}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("c"=>Dict{Any,Any}("three"=>3),"e"=>Dict{Any,Any}("five"=>5),"b"=>Dict{Any,Any}("two"=>2),"a"=>Dict{Any,Any}("one"=>1),"d"=>Dict{Any,Any}("four"=>4))) == """1
121
12321
1234321
123454321
1234321
12321
121
1
"""

	## Lists should be iterated; list items should visit the context stack.
tpl = """\"{{#list}}{{item}}{{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>Dict{Any,Any}[Dict("item"=>1), Dict("item"=>2), Dict("item"=>3)])) == """\"123\""""

	## Empty lists should behave like falsey values.
tpl = """\"{{#list}}Yay lists!{{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>Any[])) == """\"\""""

	## Multiple sections per template should be permitted.
tpl = """{{#bool}}
* first
{{/bool}}
* {{two}}
{{#bool}}
* third
{{/bool}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("two"=>"second","bool"=>true)) == """* first
* second
* third
"""

	## Nested truthy sections should have their contents rendered.
tpl = """| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |"""

	@test Mustache.render(tpl, Dict{Any,Any}("bool"=>true)) == """| A B C D E |"""

	## Nested falsey sections should be omitted.
tpl = """| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |"""

	@test Mustache.render(tpl, Dict{Any,Any}("bool"=>false)) == """| A  E |"""

	## Failed context lookups should be considered falsey.
tpl = """[{{#missing}}Found key 'missing'!{{/missing}}]"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """[]"""

	## Implicit iterators should directly interpolate strings.
tpl = """\"{{#list}}({{.}}){{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>["a", "b", "c", "d", "e"])) == """\"(a)(b)(c)(d)(e)\""""

	## Implicit iterators should cast integers to strings and interpolate.
tpl = """\"{{#list}}({{.}}){{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>[1, 2, 3, 4, 5])) == """\"(1)(2)(3)(4)(5)\""""

	## Implicit iterators should cast decimals to strings and interpolate.
tpl = """\"{{#list}}({{.}}){{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>[1.1, 2.2, 3.3, 4.4, 5.5])) == """\"(1.1)(2.2)(3.3)(4.4)(5.5)\""""

	## Dotted names should be valid for Section tags.
tpl = """\"{{#a.b.c}}Here{{/a.b.c}}\" == \"Here\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>true)))) == """\"Here\" == \"Here\""""

	## Dotted names should be valid for Section tags.
tpl = """\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>false)))) == """\"\" == \"\""""

	## Dotted names that cannot be resolved should be considered falsey.
tpl = """\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}())) == """\"\" == \"\""""

	## Sections should not alter surrounding whitespace.
tpl = """ | {{#boolean}}	|	{{/boolean}} | 
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """ | 	|	 | 
"""

	## Sections should not alter internal whitespace.
tpl = """ | {{#boolean}} {{! Important Whitespace }}
 {{/boolean}} | 
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """ |  
  | 
"""

	## Single-line sections should not alter surrounding whitespace.
tpl = """ {{#boolean}}YES{{/boolean}}
 {{#boolean}}GOOD{{/boolean}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """ YES
 GOOD
"""

	## Standalone lines should be removed from the template.
tpl = """| This Is
{{#boolean}}
|
{{/boolean}}
| A Line
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """| This Is
|
| A Line
"""

	## Indented standalone lines should be removed from the template.
tpl = """| This Is
  {{#boolean}}
|
  {{/boolean}}
| A Line
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """| This Is
|
| A Line
"""

	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{#boolean}}
{{/boolean}}
|"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """|
|"""

	## Standalone tags should not require a newline to precede them.
tpl = """  {{#boolean}}
#{{/boolean}}
/"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """#
/"""

	## Standalone tags should not require a newline to follow them.
tpl = """#{{#boolean}}
/
  {{/boolean}}"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """#
/
"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{# boolean }}={{/ boolean }}|"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """|=|"""
end


