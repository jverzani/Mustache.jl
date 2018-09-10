using Mustache
using Test

@testset " delimiters " begin


	## The equals sign (used on both sides) should permit delimiter changes.
tpl = """{{=<% %>=}}(<%text%>)"""

	@test Mustache.render(tpl, Dict{Any,Any}("text"=>"Hey!")) == """(Hey!)"""

	## Characters with special meaning regexen should be valid delimiters.
tpl = """({{=[ ]=}}[text])"""

	@test Mustache.render(tpl, Dict{Any,Any}("text"=>"It worked!")) == """(It worked!)"""

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

	@test Mustache.render(tpl, Dict{Any,Any}("section"=>true,"data"=>"I got interpolated.")) == """[
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

	@test Mustache.render(tpl, Dict{Any,Any}("section"=>false,"data"=>"I got interpolated.")) == """[
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

	@test Mustache.render(tpl, Dict{Any,Any}("value"=>"yes","include"=>".{{value}}.")) == """[ .yes. ]
[ .yes. ]
"""

	## Delimiters set in a partial should not affect the parent template.
tpl = """[ {{>include}} ]
[ .{{value}}.  .|value|. ]
"""

	@test Mustache.render(tpl, Dict{Any,Any}("value"=>"yes","include"=>".{{value}}. {{= | | =}} .|value|.")) == """[ .yes.  .yes. ]
[ .yes.  .|value|. ]
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

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Begin.
End.
"""

	## Indented standalone lines should be removed from the template.
tpl = """Begin.
  {{=@ @=}}
End.
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Begin.
End.
"""

	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{= @ @ =}}
|"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """|
|"""

	## Standalone tags should not require a newline to precede them.
tpl = """  {{=@ @=}}
="""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """="""

	## Standalone tags should not require a newline to follow them.
tpl = """=
  {{=@ @=}}"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """=
"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{= @   @ =}}|"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """||"""
end


