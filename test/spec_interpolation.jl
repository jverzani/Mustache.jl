using Mustache
using Test

@testset " interpolation " begin


	## Mustache-free templates should render as-is.
tpl = """Hello from {Mustache}!
"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """Hello from {Mustache}!
"""

	## Unadorned tags should interpolate content into the template.
tpl = """Hello, {{subject}}!
"""

	@test Mustache.render(tpl, Dict{Any,Any}("subject"=>"world")) == """Hello, world!
"""

	## Basic interpolation should be HTML escaped.
tpl = """These characters should be HTML escaped: {{forbidden}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("forbidden"=>"& \" < >")) == """These characters should be HTML escaped: &amp; &quot; &lt; &gt;
"""

	## Triple mustaches should interpolate without HTML escaping.
tpl = """These characters should not be HTML escaped: {{{forbidden}}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("forbidden"=>"& \" < >")) == """These characters should not be HTML escaped: & \" < >
"""

	## Ampersand should interpolate without HTML escaping.
tpl = """These characters should not be HTML escaped: {{&forbidden}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("forbidden"=>"& \" < >")) == """These characters should not be HTML escaped: & \" < >
"""

	## Integers should interpolate seamlessly.
tpl = """\"{{mph}} miles an hour!\""""

	@test Mustache.render(tpl, Dict{Any,Any}("mph"=>85)) == """\"85 miles an hour!\""""

	## Integers should interpolate seamlessly.
tpl = """\"{{{mph}}} miles an hour!\""""

	@test Mustache.render(tpl, Dict{Any,Any}("mph"=>85)) == """\"85 miles an hour!\""""

	## Integers should interpolate seamlessly.
tpl = """\"{{&mph}} miles an hour!\""""

	@test Mustache.render(tpl, Dict{Any,Any}("mph"=>85)) == """\"85 miles an hour!\""""

	## Decimals should interpolate seamlessly with proper significance.
tpl = """\"{{power}} jiggawatts!\""""

	@test Mustache.render(tpl, Dict{Any,Any}("power"=>1.21)) == """\"1.21 jiggawatts!\""""

	## Decimals should interpolate seamlessly with proper significance.
tpl = """\"{{{power}}} jiggawatts!\""""

	@test Mustache.render(tpl, Dict{Any,Any}("power"=>1.21)) == """\"1.21 jiggawatts!\""""

	## Decimals should interpolate seamlessly with proper significance.
tpl = """\"{{&power}} jiggawatts!\""""

	@test Mustache.render(tpl, Dict{Any,Any}("power"=>1.21)) == """\"1.21 jiggawatts!\""""

	## Failed context lookups should default to empty strings.
tpl = """I ({{cannot}}) be seen!"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """I () be seen!"""

	## Failed context lookups should default to empty strings.
tpl = """I ({{{cannot}}}) be seen!"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """I () be seen!"""

	## Failed context lookups should default to empty strings.
tpl = """I ({{&cannot}}) be seen!"""

	@test Mustache.render(tpl, Dict{Any,Any}()) == """I () be seen!"""

	## Dotted names should be considered a form of shorthand for sections.
tpl = """\"{{person.name}}\" == \"{{#person}}{{name}}{{/person}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("person"=>Dict{Any,Any}("name"=>"Joe"))) == """\"Joe\" == \"Joe\""""

	## Dotted names should be considered a form of shorthand for sections.
tpl = """\"{{{person.name}}}\" == \"{{#person}}{{{name}}}{{/person}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("person"=>Dict{Any,Any}("name"=>"Joe"))) == """\"Joe\" == \"Joe\""""

	## Dotted names should be considered a form of shorthand for sections.
tpl = """\"{{&person.name}}\" == \"{{#person}}{{&name}}{{/person}}\""""

	@test Mustache.render(tpl, Dict{Any,Any}("person"=>Dict{Any,Any}("name"=>"Joe"))) == """\"Joe\" == \"Joe\""""

	## Dotted names should be functional to any level of nesting.
tpl = """\"{{a.b.c.d.e.name}}\" == \"Phil\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>Dict{Any,Any}("d"=>Dict{Any,Any}("e"=>Dict{Any,Any}("name"=>"Phil"))))))) == """\"Phil\" == \"Phil\""""

	## Any falsey value prior to the last part of the name should yield ''.
tpl = """\"{{a.b.c}}\" == \"\""""

	@test Mustache.render(tpl, Dict{Any,Any}("a"=>Dict{Any,Any}())) == """\"\" == \"\""""

	## Each part of a dotted name should resolve only against its parent.
tpl = """\"{{a.b.c.name}}\" == \"\""""

	@test Mustache.render(tpl, Dict{Any,Any}("c"=>Dict{Any,Any}("name"=>"Jim"),"a"=>Dict{Any,Any}("b"=>Dict{Any,Any}()))) == """\"\" == \"\""""

	## The first part of a dotted name should resolve as any other name.
tpl = """\"{{#a}}{{b.c.d.e.name}}{{/a}}\" == \"Phil\""""

	@test Mustache.render(tpl, Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>Dict{Any,Any}("d"=>Dict{Any,Any}("e"=>Dict{Any,Any}("name"=>"Wrong")))),"a"=>Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>Dict{Any,Any}("d"=>Dict{Any,Any}("e"=>Dict{Any,Any}("name"=>"Phil"))))))) == """\"Phil\" == \"Phil\""""

	## Dotted names should be resolved against former resolutions.
tpl = """{{#a}}{{b.c}}{{/a}}"""

	@test Mustache.render(tpl, Dict{Any,Any}("b"=>Dict{Any,Any}("c"=>"ERROR"),"a"=>Dict{Any,Any}("b"=>Dict{Any,Any}()))) == """"""

	## Interpolation should not alter surrounding whitespace.
tpl = """| {{string}} |"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """| --- |"""

	## Interpolation should not alter surrounding whitespace.
tpl = """| {{{string}}} |"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """| --- |"""

	## Interpolation should not alter surrounding whitespace.
tpl = """| {{&string}} |"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """| --- |"""

	## Standalone interpolation should not alter surrounding whitespace.
tpl = """  {{string}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """  ---
"""

	## Standalone interpolation should not alter surrounding whitespace.
tpl = """  {{{string}}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """  ---
"""

	## Standalone interpolation should not alter surrounding whitespace.
tpl = """  {{&string}}
"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """  ---
"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{ string }}|"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """|---|"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{{ string }}}|"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """|---|"""

	## Superfluous in-tag whitespace should be ignored.
tpl = """|{{& string }}|"""

	@test Mustache.render(tpl, Dict{Any,Any}("string"=>"---")) == """|---|"""
end


