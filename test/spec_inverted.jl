using Mustache
using Test

@testset " inverted " begin


	## Falsey sections should have their contents rendered.
tpl = """\"{{^boolean}}This should be rendered.{{/boolean}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """\"This should be rendered.\""""

	## Truthy sections should have their contents omitted.
tpl = """\"{{^boolean}}This should not be rendered.{{/boolean}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>true)) == """\"\""""

	## Objects and hashes should behave like truthy values.
tpl = """\"{{^context}}Hi {{name}}.{{/context}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("context"=>Dict{Any,Any}("name"=>"Joe"))) == """\"\""""

	## Lists should behave like truthy values.
tpl = """\"{{^list}}{{n}}{{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>Dict{Any,Any}[Dict("n"=>1), Dict("n"=>2), Dict("n"=>3)])) == """\"\""""

	## Empty lists should behave like falsey values.
tpl = """\"{{^list}}Yay lists!{{/list}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("list"=>Any[])) == """\"Yay lists!\""""

	## Multiple inverted sections per template should be permitted.
tpl = """{{^bool}}
* first
{{/bool}}
* {{two}}
{{^bool}}
* third
{{/bool}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("two"=>"second","bool"=>false)) == """* first
* second
* third
"""

	## Nested falsey sections should have their contents rendered.
tpl = """| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"""

	@test Mustache.render(tpl, Dict{Any,Any}("bool"=>false)) == """| A B C D E |"""

	## Nested truthy sections should be omitted.
tpl = """| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"""

	@test Mustache.render(tpl, Dict{Any,Any}("bool"=>true)) == """| A  E |"""

	## Failed context lookups should be considered falsey.
tpl = """[{{^missing}}Cannot find key 'missing'!{{/missing}}]"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """[Cannot find key 'missing'!]"""

	## Dotted names should be valid for Inverted Section tags.
tpl = """\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>true)))) == """\"\" == \"\""""

	## Dotted names should be valid for Inverted Section tags.
tpl = """\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>false)))) == """\"Not Here\" == \"Not Here\""""

	## Dotted names that cannot be resolved should be considered falsey.
tpl = """\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}())) == """\"Not Here\" == \"Not Here\""""

	## Inverted sections should not alter surrounding whitespace.
tpl = """ | {{^boolean}}	|	{{/boolean}} |
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """ | 	|	 |
"""

	## Inverted should not alter internal whitespace.
tpl = """ | {{^boolean}} {{! Important Whitespace }}
 {{/boolean}} |
"""

        @test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == " |  \n  |\n"
#""" |\\s
#  |
#"""

	## Single-line sections should not alter surrounding whitespace.
tpl = """ {{^boolean}}NO{{/boolean}}
 {{^boolean}}WAY{{/boolean}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """ NO
 WAY
"""

	## Standalone lines should be removed from the template.
tpl = """| This Is
{{^boolean}}
|
{{/boolean}}
| A Line
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """| This Is
|
| A Line
"""

	## Standalone indented lines should be removed from the template.
tpl = """| This Is
  {{^boolean}}
|
  {{/boolean}}
| A Line
"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """| This Is
|
| A Line
"""

	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{^boolean}}
{{/boolean}}
|"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """|
|"""

	## Standalone tags should not require a newline to precede them.
tpl = """  {{^boolean}}
^{{/boolean}}
/"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """^
/"""

	## Standalone tags should not require a newline to follow them.
tpl = """^{{^boolean}}
/
  {{/boolean}}"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """^
/
"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{^ boolean }}={{/ boolean }}|"""

	@test Mustache.render(tpl, Dict{Any,Any}("boolean"=>false)) == """|=|"""
end
