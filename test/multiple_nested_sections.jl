using Mustache

function test_data(str, iter)
    [[str => x] for x in iter]
end

failing_template = mt"{{#report}}[{{#times1}}{{x}},{{/times1}}],[{{#times2}}{{y}},{{/times2}}]{{/report}}"
test_func = () -> render(failing_template,
        ["report" => [["times1" => test_data("x", 1:4), "times2" => test_data("y",4:8)]]])

res = test_func()
@assert res == "[1,2,3,4,],[4,5,6,7,8,]" 


failing_template = mt"{{#report}}[{{#times1}}{{x}},[{{#times2}}{{y}},{{/times2}}],{{/times1}}]{{/report}}"
test_func = () -> render(failing_template,
        ["report" => [["times1" => test_data("x", 1:3), "times2" => test_data("y",4:8)]]])
res = test_func()
@assert res == "[1,[4,5,6,7,8,],2,[4,5,6,7,8,],3,[4,5,6,7,8,],]"


failing_template = mt"{{#report}}{{/report}}[{{#times1}}{{x}},[{{#times2}}{{x}},{{/times2}}],{{/times1}}]"
test_func = () -> render(failing_template,
        ["report" => [],
	 "times1" => test_data("x", 1:3),
	 "times2" => test_data("x", 4:8)])
res = test_func()
@assert res == "[1,[4,5,6,7,8,],2,[4,5,6,7,8,],3,[4,5,6,7,8,],]"
