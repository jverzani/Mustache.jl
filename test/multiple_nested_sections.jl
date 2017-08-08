using Mustache

function test_data(str, iter)
    [Dict(str => x) for x in iter]
end

failing_template = mt"{{#report}}[{{#times1}}{{x}},{{/times1}}],[{{#times2}}{{y}},{{/times2}}]{{/report}}"
test_func = () -> render(failing_template,
                         Dict("report" => [ Dict("times1" => test_data("x", 1:4), "times2" => test_data("y",4:8))]))

res = test_func()
@assert res == "[1,2,3,4,],[4,5,6,7,8,]"


failing_template = mt"{{#report}}[{{#times1}}{{x}},[{{#times2}}{{y}},{{/times2}}],{{/times1}}]{{/report}}"
test_func = () -> render(failing_template,
        Dict("report" => [Dict("times1" => test_data("x", 1:3), "times2" => test_data("y",4:8))]))
res = test_func()
@assert res == "[1,[4,5,6,7,8,],2,[4,5,6,7,8,],3,[4,5,6,7,8,],]"


failing_template = mt"{{#report}}{{/report}}[{{#times1}}{{x}},[{{#times2}}{{x}},{{/times2}}],{{/times1}}]"
test_func = () -> render(failing_template,
                          Dict("report" => [],
	                              "times1" => test_data("x", 1:3),
	                              "times2" => test_data("x", 4:8)))
                                      res = test_func()
@assert res == "[1,[4,5,6,7,8,],2,[4,5,6,7,8,],3,[4,5,6,7,8,],]"


## issue #31 -- nested sections
mutable struct Location
  lat::Float64
  lon::Float64
end
mutable struct Thing
  location::Location
  name::AbstractString
end
x = [Thing(Location(1.,2.), "name"), Thing(Location(3.,4.), "nombre")]


tpl = """
{{#:x}}
{{#.}}
{{#location}}
{{lat}}--{{lon}}
{{/location}}
{{name}}
{{/.}}
{{/:x}}
"""

Mustache.render(tpl, x=x)  == "\n\n\n1.0--2.0\n\nname\n\n\n\n\n3.0--4.0\n\nnombre\n\n\n"
