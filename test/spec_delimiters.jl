using Mustache
using Test
strip_rns(x) = replace(replace(replace(x, "\n"=>""), "\r"=>""), r"\s"=>"")

@testset " delimiters " begin


	## The equals sign (used on both sides) should permit delimiter changes.
tpl = """{{=<% %>=}}(<%text%>)"""


	## Characters with special meaning regexen should be valid delimiters.
tpl = """({{=[ ]=}}[text])"""


	## Delimiters set outside sections should persist.
tpl = """[
{{#section}}
  {{data}}
  |data|
{{/section}}

{{= | | =}}
|#section|
  {{data}}
  |data|
|/section|
]
"""

	@test_skip Mustache.render(tpl, Dict{Any,Any}("section"=>true,"data"=>"I got interpolated.")) == """[
  I got interpolated.
  |data|

  {{data}}
  I got interpolated.
]
"""

	## Delimiters set outside inverted sections should persist.
tpl = """[
{{^section}}
  {{data}}
  |data|
{{/section}}

{{= | | =}}
|^section|
  {{data}}
  |data|
|/section|
]
"""

	@test_skip Mustache.render(tpl, Dict{Any,Any}("section"=>false,"data"=>"I got interpolated.")) == """[
  I got interpolated.
  |data|

  {{data}}
  I got interpolated.
]
"""

	## Delimiters set in a parent template should not affect a partial.
tpl = """[ {{>include}} ]
{{= | | =}}
[ |>include| ]
"""

	@test_skip Mustache.render(tpl, Dict{Any,Any}("value"=>"yes")) == """[ .yes. ]
[ .yes. ]
"""

	## Delimiters set in a partial should not affect the parent template.
tpl = """[ {{>include}} ]
[ .{{value}}.  .|value|. ]
"""


	## Surrounding whitespace should be left untouched.
tpl = """| {{=@ @=}} |"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """|  |"""

	## Whitespace should be left untouched.
tpl = """ | {{=@ @=}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """ | 
"""

	## Standalone lines should be removed from the template.
tpl = """Begin.
{{=@ @=}}
End.
"""

	## XXX space issue
	val = strip_rns(Mustache.render(tpl, Dict{Any,Any}()))
	expected = strip_rns("""Begin.
End.
""")
	@test val == expected

	## Indented standalone lines should be removed from the template.
tpl = """Begin.
  {{=@ @=}}
End.
"""

	## XXX space issue
	val = strip_rns(Mustache.render(tpl, Dict{Any,Any}()))
	expected = strip_rns("""Begin.
End.
""")
	@test val == expected

	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{= @ @ =}}
|"""

	@test_skip Mustache.render(tpl, Dict{Any,Any}()) == """|
|"""

	## Standalone tags should not require a newline to precede them.
tpl = """  {{=@ @=}}
="""

	## XXX space issue
	val = strip_rns(Mustache.render(tpl, Dict{Any,Any}()))
	expected = strip_rns("""=""")
	@test val == expected

	## Standalone tags should not require a newline to follow them.
tpl = """=
  {{=@ @=}}"""

	## XXX space issue
	val = strip_rns(Mustache.render(tpl, Dict{Any,Any}()))
	expected = strip_rns("""=
""")
	@test val == expected

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{= @   @ =}}|"""

	@test_skip Mustache.render(tpl, Dict{Any,Any}()) == """||"""
end


