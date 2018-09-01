using Mustache
using Test
strip_rns(x) = replace(replace(replace(x, "\n"=>""), "\r"=>""), r"\s"=>"")

@testset " partials " begin


	## The greater-than operator should expand to the named partial.
tpl = """\"{{>text}}\""""


	## The empty string should be used when the named partial is not found.
tpl = """\"{{>text}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """\"\""""

	## The greater-than operator should operate within the current context.
tpl = """\"{{>partial}}\""""


	## The greater-than operator should properly recurse.
tpl = """{{>node}}"""


	## The greater-than operator should not alter surrounding whitespace.
tpl = """| {{>partial}} |"""


	## Whitespace should be left untouched.
tpl = """  {{data}}  {{> partial}}
"""


	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{>partial}}
|"""


	## Standalone tags should not require a newline to precede them.
tpl = """  {{>partial}}
>"""


	## Standalone tags should not require a newline to follow them.
tpl = """>
  {{>partial}}"""


	## Each line of the partial should be indented before rendering.
tpl = """\\
 {{>partial}}
/
"""


	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{> partial }}|"""

end


