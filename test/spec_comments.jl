using Mustache
using Test

@testset " comments " begin


	## Comment blocks should be removed from the template.
tpl = """12345{{! Comment Block! }}67890"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """1234567890"""

	## Multiline comments should be permitted.
tpl = """12345{{!
  This is a
  multi-line comment...
}}67890
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """1234567890
"""

	## All standalone comment lines should be removed.
tpl = """Begin.
{{! Comment Block! }}
End.
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Begin.
End.
"""

	## All standalone comment lines should be removed.
tpl = """Begin.
  {{! Indented Comment Block! }}
End.
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Begin.
End.
"""

	## "\r\n" should be considered a newline for standalone tags.
tpl = """|
{{! Standalone Comment }}
|"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """|
|"""

	## Standalone tags should not require a newline to precede them.
tpl = """  {{! I'm Still Standalone }}
!"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """!"""

	## Standalone tags should not require a newline to follow them.
tpl = """!
  {{! I'm Still Standalone }}"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """!
"""

	## All standalone comment lines should be removed.
tpl = """Begin.
{{!
Something's going on here...
}}
End.
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Begin.
End.
"""

	## All standalone comment lines should be removed.
tpl = """Begin.
  {{!s
    Something's going on here...
  }}
End.
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Begin.
End.
"""

	## Inline comments should not strip whitespace
tpl = """  12 {{! 34 }}
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """  12 
"""

	## Comment removal should preserve surrounding whitespace.
tpl = """12345 {{! Comment Block! }} 67890"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """12345  67890"""
end


