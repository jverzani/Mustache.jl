## Data frame test
## not run by default. Too time consuming and relies on external pacakgs
using Mustache, DataFrames
using Test
using Printf

#  simple usage
tpl = mt"""
{{:TITLE}}
{{#:D}}
{{:english}} <--> {{:spanish}}
{{/:D}}
"""

d = DataFrame(english=["hello", "good bye"], spanish=["hola", "adios"])

@test render(tpl, TITLE="translate",  D=d) == "translate\nhello <--> hola\ngood bye <--> adios\n"


## Issue with data frames as keyword arguments
tpl = """
{{#:fred}}{{:a}}--{{:b}}{{/:fred}}
{{:barney}}
"""
d = DataFrame(a=[1,2,3], b=[3,2,1])
@test render(tpl, fred=d, barney="123") == "1--32--23--1\n123\n"
