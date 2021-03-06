using Mustache
using Test

mutable struct CallableFunction <: Function
  calls::Int
end
(F::CallableFunction)() = (F.calls += 1; string(F.calls))

@testset " lambdas " begin
# overview: |
#   Lambdas are a special-cased data type for use in interpolations and
#   sections.

#   When used as the data value for an Interpolation tag, the lambda MUST be
#   treatable as an arity 0 function, and invoked as such.  The returned value
#   MUST be rendered against the default delimiters, then interpolated in place
#   of the lambda.

#   When used as the data value for a Section tag, the lambda MUST be treatable
#   as an arity 1 function, and invoked as such (passing a String containing the
#   unprocessed section contents).  The returned value MUST be rendered against
#   the current delimiters, then interpolated in place of the section.
# tests:
#   - name: Interpolation
#     desc: A lambda's return value should be interpolated.
#     data:
#       lambda: !code
#         ruby:    'proc { "world" }'
#         perl:    'sub { "world" }'
#         js:      'function() { return "world" }'
#         php:     'return "world";'
#         python:  'lambda: "world"'
#         clojure: '(fn [] "world")'
#     template: "Hello, {{lambda}}!"
#     expected: "Hello, world!"

    template = "Hello, {{lambda}}!"
    expected = "Hello, world!"
    data = Dict("lambda"=> () -> "world")
    @test Mustache.render(template, data) == expected



#   - name: Interpolation - Expansion
#     desc: A lambda's return value should be parsed.
#     data:
#       planet: "world"
#       lambda: !code
#         ruby:    'proc { "{{planet}}" }'
#         perl:    'sub { "{{planet}}" }'
#         js:      'function() { return "{{planet}}" }'
#         php:     'return "{{planet}}";'
#         python:  'lambda: "{{planet}}"'
#         clojure: '(fn [] "{{planet}}")'
#     template: "Hello, {{lambda}}!"
#     expected: "Hello, world!"

    template = "Hello, {{lambda}}!"
    expected = "Hello, world!"
    data = Dict("lambda" => () -> "{{planet}}", "planet" => "world")
    @test Mustache.render(template, data) == expected
    
#   - name: Interpolation - Alternate Delimiters
#     desc: A lambda's return value should parse with the default delimiters.
#     data:
#       planet: "world"
#       lambda: !code
#         ruby:    'proc { "|planet| => {{planet}}" }'
#         perl:    'sub { "|planet| => {{planet}}" }'
#         js:      'function() { return "|planet| => {{planet}}" }'
#         php:     'return "|planet| => {{planet}}";'
#         python:  'lambda: "|planet| => {{planet}}"'
#         clojure: '(fn [] "|planet| => {{planet}}")'
#     template: "{{= | | =}}\nHello, (|&lambda|)!"
#     expected: "Hello, (|planet| => world)!"

    template = "{{= | | =}}\nHello, (|&lambda|)!"
    expected = "Hello, (|planet| => world)!"
    data = Dict("planet"=>"world", "lambda"=> () -> "|planet| => {{planet}}")
    @test Mustache.render(template, data) == expected
    
#   - name: Interpolation - Multiple Calls
#     desc: Interpolated lambdas should not be cached.
#     data:
#       lambda: !code
#         ruby:    'proc { $calls ||= 0; $calls += 1 }'
#         perl:    'sub { no strict; $calls += 1 }'
#         js:      'function() { return (g=(function(){return this})()).calls=(g.calls||0)+1 }'
#         php:     'global $calls; return ++$calls;'
#         python:  'lambda: globals().update(calls=globals().get("calls",0)+1) or calls'
#         clojure: '(def g (atom 0)) (fn [] (swap! g inc))'
#     template: '{{lambda}} == {{{lambda}}} == {{lambda}}'
#     expected: '1 == 2 == 3'

    template = "{{lambda}} == {{{lambda}}} == {{lambda}}"
    expected =  "1 == 2 == 3"
    data = Dict("lambda" => CallableFunction(0))
    @test Mustache.render(template, data) == expected
    
#   - name: Escaping
#     desc: Lambda results should be appropriately escaped.
#     data:
#       lambda: !code
#         ruby:    'proc { ">" }'
#         perl:    'sub { ">" }'
#         js:      'function() { return ">" }'
#         php:     'return ">";'
#         python:  'lambda: ">"'
#         clojure: '(fn [] ">")'
#     template: "<{{lambda}}{{{lambda}}}"
#     expected: "<&gt;>"


    template = "<{{lambda}}{{{lambda}}}"
    expected = "<&gt;>"
    data = Dict("lambda" => () -> ">")
    @test Mustache.render(template, data) == expected
    
#   - name: Section
#     desc: Lambdas used for sections should receive the raw section string.
#     data:
#       x: 'Error!'
#       lambda: !code
#         ruby:    'proc { |text| text == "{{x}}" ? "yes" : "no" }'
#         perl:    'sub { $_[0] eq "{{x}}" ? "yes" : "no" }'
#         js:      'function(txt) { return (txt == "{{x}}" ? "yes" : "no") }'
#         php:     'return ($text == "{{x}}") ? "yes" : "no";'
#         python:  'lambda text: text == "{{x}}" and "yes" or "no"'
#         clojure: '(fn [text] (if (= text "{{x}}") "yes" "no"))'
#     template: "<{{#lambda}}{{x}}{{/lambda}}>"
#     expected: "<yes>"

    template = "<{{#lambda}}{{x}}{{/lambda}}>"
    expected = "<yes>"
    data = Dict("x" => "Error!", "lambda" => (txt) ->  txt == "{{x}}" ? "yes" : "no")
    @test Mustache.render(template, data) == expected
    
#   - name: Section - Expansion
#     desc: Lambdas used for sections should have their results parsed.
#     data:
#       planet: "Earth"
#       lambda: !code
#         ruby:    'proc { |text| "#{text}{{planet}}#{text}" }'
#         perl:    'sub { $_[0] . "{{planet}}" . $_[0] }'
#         js:      'function(txt) { return txt + "{{planet}}" + txt }'
#         php:     'return $text . "{{planet}}" . $text;'
#         python:  'lambda text: "%s{{planet}}%s" % (text, text)'
#         clojure: '(fn [text] (str text "{{planet}}" text))'
#     template: "<{{#lambda}}-{{/lambda}}>"
#     expected: "<-Earth->"

    template = "<{{#lambda}}-{{/lambda}}>"
    expected = "<-Earth->"
    data = Dict("planet"=> "Earth", "lambda" => (txt) -> txt * "{{planet}}" * txt)
    @test Mustache.render(template, data) == expected

#   - name: Section - Alternate Delimiters
#     desc: Lambdas used for sections should parse with the current delimiters.
#     data:
#       planet: "Earth"
#       lambda: !code
#         ruby:    'proc { |text| "#{text}{{planet}} => |planet|#{text}" }'
#         perl:    'sub { $_[0] . "{{planet}} => |planet|" . $_[0] }'
#         js:      'function(txt) { return txt + "{{planet}} => |planet|" + txt }'
#         php:     'return $text . "{{planet}} => |planet|" . $text;'
#         python:  'lambda text: "%s{{planet}} => |planet|%s" % (text, text)'
#         clojure: '(fn [text] (str text "{{planet}} => |planet|" text))'
#     template: "{{= | | =}}<|#lambda|-|/lambda|>"
#     expected: "<-{{planet}} => Earth->"

template = "{{= | | =}}<|#lambda|-|/lambda|>"
expected =  "<-{{planet}} => Earth->"
data = Dict("planet"=>"Earth", "lambda"=> (txt) -> txt * "{{planet}} => |planet|" * txt)
@test Mustache.render(template, data) == expected

#   - name: Section - Multiple Calls
#     desc: Lambdas used for sections should not be cached.
#     data:
#       lambda: !code
#         ruby:    'proc { |text| "__#{text}__" }'
#         perl:    'sub { "__" . $_[0] . "__" }'
#         js:      'function(txt) { return "__" + txt + "__" }'
#         php:     'return "__" . $text . "__";'
#         python:  'lambda text: "__%s__" % (text)'
#         clojure: '(fn [text] (str "__" text "__"))'
#     template: '{{#lambda}}FILE{{/lambda}} != {{#lambda}}LINE{{/lambda}}'
#     expected: '__FILE__ != __LINE__'

 template = "{{#lambda}}FILE{{/lambda}} != {{#lambda}}LINE{{/lambda}}"
expected = "__FILE__ != __LINE__"
data = Dict("lambda" => (txt) ->  "__" * txt * "__")
@test Mustache.render(template, data) == expected
            

#   - name: Inverted Section
#     desc: Lambdas used for inverted sections should be considered truthy.
#     data:
#       static: 'static'
#       lambda: !code
#         ruby:    'proc { |text| false }'
#         perl:    'sub { 0 }'
#         js:      'function(txt) { return false }'
#         php:     'return false;'
#         python:  'lambda text: 0'
#         clojure: '(fn [text] false)'
#     template: "<{{^lambda}}{{static}}{{/lambda}}>"
#     expected: "<>"

 template = "<{{^lambda}}{{static}}{{/lambda}}>"
expected = "<>"
data = Dict("static" => "static", "lambda" => (txt) -> false)
@test Mustache.render(template, data) == expected

end
