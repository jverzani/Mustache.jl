using Mustache
using Test

@testset " partials " begin


	## The greater-than operator should expand to the named partial.
tpl = """\"{{>text}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("text"=>"from partial")) == """\"from partial\""""

	## The empty string should be used when the named partial is not found.
tpl = """\"{{>text}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """\"\""""

	## The greater-than operator should operate within the current context.
tpl = """\"{{>partial}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>"*{{text}}*","text"=>"content")) == """\"*content*\""""

	## The greater-than operator should properly recurse.
tpl = """{{>node}}"""

	@test Mustache.render(tpl, Dict{Any,Any}("nodes"=>Dict{Any,Any}[Dict("nodes"=>Any[],"content"=>"Y")],"content"=>"X","node"=>"{{content}}<{{#nodes}}{{>node}}{{/nodes}}>")) == """X<Y<>>"""

	## The greater-than operator should not alter surrounding whitespace.
tpl = """| {{>partial}} |"""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>"\t|\t")) == """| 	|	 |"""

	## Whitespace should be left untouched.
tpl = """  {{data}}  {{> partial}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>">\n>","data"=>"|")) == """  |  >
>
"""

	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{>partial}}
|"""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>">")) == """|
>|"""

	## Standalone tags should not require a newline to precede them.
tpl = """  {{>partial}}
>"""

	@test_skip Mustache.render(tpl, Dict{Any,Any}("partial"=>">\n>")) == """  >
  >>"""

	## Standalone tags should not require a newline to follow them.
tpl = """>
  {{>partial}}"""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>">\n>")) == """>
  >
  >"""

	## Each line of the partial should be indented before rendering.
tpl = """\\
 {{>partial}}
/
"""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>"|\n{{{content}}}\n|\n","content"=>"<\n->")) == """\\
 |
 <
->
 |
/
"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{> partial }}|"""

	@test Mustache.render(tpl, Dict{Any,Any}("partial"=>"[]","boolean"=>true)) == """|[]|"""
end


