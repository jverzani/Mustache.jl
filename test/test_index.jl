## Experimental syntax for indexing within vectors:
using Test

## use # to include
tpl = mt"{{#:vec}}{{#.[1]}}{{.}}{{/.[1]}}{{/:vec}}"
out = Mustache.render(tpl, vec=["A1","B2","C3"])
@test out == "A1"

## use ^ to exclude
tpl = mt"{{#:vec}}{{.}}{{^.[end]}}, {{/.[end]}}{{/:vec}}"
out = Mustache.render(tpl, vec=["A1","B2","C3"])
@test out == "A1, B2, C3"

tpl = mt"{{#:vec}}{{#.}}{{..}}{{/.}}{{/:vec}}"
out = Mustache.render(tpl, vec=[["A1","A2"],["B1","B2"]])
@test out == "A1A2B1B2"

tpl = mt"{{#:vec}}{{#.}}<{{..}}>{{/.}}{{/:vec}}"
out = Mustache.render(tpl, vec=[["A1","A2"],["B1","B2"]])
@test out == "<A1><A2><B1><B2>"

tpl = mt"{{#:vec}}{{#.}}{{..a}}{{/.}}{{/:vec}}"
out = Mustache.render(tpl, vec=[(a=["A1","A2"],), (a=["B1","B2"],)])
@test out == "A1A2B1B2"
