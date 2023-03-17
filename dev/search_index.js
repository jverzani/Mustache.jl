var documenterSearchIndex = {"docs":
[{"location":"#Mustache.jl","page":"Mustache.jl","title":"Mustache.jl","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Documentation for Mustache.jl.","category":"page"},{"location":"#Examples","page":"Mustache.jl","title":"Examples","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Following the main documentation for Mustache.js we have a \"typical Mustache template\" defined by:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"using Mustache\n\ntpl = mt\"\"\"\nHello {{name}}\nYou have just won {{value}} dollars!\n{{#in_ca}}\nWell, {{taxed_value}} dollars, after taxes.\n{{/in_ca}}\n\"\"\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The values with braces (mustaches on their side) are looked up in a view, such as a dictionary or module. For example,","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"d = Dict(\n\"name\" => \"Chris\",\n\"value\" => 10000,\n\"taxed_value\" => 10000 - (10000 * 0.4),\n\"in_ca\" => true)\n\nMustache.render(tpl, d)","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Yielding","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Hello Chris\nYou have just won 10000 dollars!\nWell, 6000.0 dollars, after taxes.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The render function pieces things together. Like print, the first argument is for an optional IO instance. In the above example, where one is not provided, a string is returned.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The flow is","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"a template is parsed into tokens by Mustache.parse. This can be called directly, indirectly through the non-standard string literal mt, or when loading a file with Mustache.load. The templates use tags comprised of matching mustaches ({}), either two or three, to indicate a value to be substituted for. These tags may be adjusted when parse is called.\nThe tokens and a view are rendered. The render function takes tokens as its second argument. If this argument is a string, parse is called internally. The render function than reassambles the template, substituting values, as appropriate, from the \"view\" passed to it and writes the output to the specified io argument.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"There are only 4 exports: mt and jmt, string literals to specify a template, render, and render_from_file.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The view used to provide values to substitute into the template can be specified in a variety of ways. The above example used a dictionary. A Module may also be used, such as Main:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"name, value, taxed_value, in_ca = \"Christine\", 10000, 10000 - (10000 * 0.4), false\nMustache.render(tpl, Main) |> print","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Which yields:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Hello Christine\nYou have just won 10000 dollars!","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Further, keyword arguments can be used when the variables in the templates are symbols:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"goes_together = mt\"{{{:x}}} and {{{:y}}}.\"\nMustache.render(goes_together, x=\"Salt\", y=\"pepper\")\nMustache.render(goes_together, x=\"Bread\", y=\"butter\")","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Tokens objects are functors; keyword arguments can also be passed to a Tokens object directly (bypassing the use of render):","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"goes_together = mt\"{{{:x}}} and {{{:y}}}.\"\ngoes_together(x=\"Fish\", y=\"chips\")","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Similarly, a named tuple may be used as a view.  As well, one can use Composite Kinds. This may make writing show methods easier:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"using Distributions\ntpl = \"Beta distribution with alpha={{α}}, beta={{β}}\"\nMustache.render(tpl, Beta(1, 2))","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"gives","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"\"Beta distribution with alpha=1.0, beta=2.0\"","category":"page"},{"location":"#Rendering","page":"Mustache.jl","title":"Rendering","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The render function combines tokens and a view to fill in the template. The basic call is render([io::IO], tokens, view), however there are variants:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"render(tokens; kwargs...)\nrender(string, view)  (string is parsed into tokens)\nrender(string; kwargs...)","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Finally, tokens are callable, so there are these variants to call render:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tokens([io::IO], view)\ntokens([io::IO]; kwargs...)","category":"page"},{"location":"#Views","page":"Mustache.jl","title":"Views","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Views are used to hold values for the templates variables. There are many possible objects that can be used for views:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"a dictionary\na named tuple\nkeyword arguments to render\na module","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"For templates which iterate over a variable, these can be","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"a Tables.jl compatible object with row iteration support (e.g., A DataFrame, a tuple of named tuples, ...)\na vector or tuple (in which case \".\" is used to match","category":"page"},{"location":"#Templates-and-tokens","page":"Mustache.jl","title":"Templates and tokens","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"A template is parsed into tokens. The render function combines the tokens with the view to create the output.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Parsing is done at compile time, if the mt string literal is used to define the template. If re-using a template, this is encouraged, as it will be more performant.\nIf string interpolation is desired prior to the parsing into tokens, the jmt string literal can be used.\nAs well, a string can be used to define a template. When parse is called, the string will be parsed into tokens. This is the flow if render is called on a string (and not tokens).","category":"page"},{"location":"#Variables","page":"Mustache.jl","title":"Variables","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Tags representing variables for substitution have the form {{varname}}, {{:symbol}}, or their triple-braced versions {{{varname}}} or {{{:symbol}}}.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The varname version will match variables in a view such as a dictionary or a module.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The :symbol version will match variables passed in via named tuple or keyword arguments.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"b = \"be\"\nMustache.render(mt\"a {{b}} c\", Main)  # \"a be c\"\nMustache.render(mt\"a {{:b}} c\", b=\"bee\") # \"a bee c\"\nMustache.render(mt\"a {{:b}} c\", (b=\"bee\", c=\"sea\")) # \"a bee c\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The triple brace prevents HTML substitution for entities such as <. The following are escaped when only double braces are used: \"&\", \"<\", \">\", \"'\", \"\\\", and \"/\".","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Mustache.render(mt\"a {{:b}} c\", b = \"%< bee >%\")   # \"a %&lt; bee &gt;% c\"\nMustache.render(mt\"a {{{:b}}} c\", b = \"%< bee >%\") # \"a %< bee >% c\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"If different tags are specified to parse, say << or >>, then <<{ and }>> indicate the prevention of substitution.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tokens = Mustache.parse(\"a <<:b>> c\", (\"<<\", \">>\"))\nMustache.render(tokens, b = \"%< B >%\")  # a %&lt; B &gt;% c\"\n\ntokens = Mustache.parse(\"a <<{:b}>> c\", (\"<<\", \">>\"))\nMustache.render(tokens, b = \"%< B >%\")  # \"a %< B >% c\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"If the variable refers to a function, the value will be the result of calling the function with no arguments passed in.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Mustache.render(mt\"a {{:b}} c\", b = () -> \"Bea\")  # \"a Bea c\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"using Dates\nMustache.render(mt\"Written in the year {{:yr}}.\"; yr = year∘now) # \"Written in the year 2023.\"","category":"page"},{"location":"#Sections","page":"Mustache.jl","title":"Sections","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"In the main example, the template included:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"{{#in_ca}}\nWell, {{taxed_value}} dollars, after taxes.\n{{/in_ca}}","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Tags beginning with #varname and closed with /varname create \"sections.\"  These have different behaviors depending on the value of the variable. When the variable is not a function or a container the part between them is used only if the variable is defined and not \"falsy:\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"a = mt\"{{#:b}}Hi{{/:b}}\";\na(; b=true) # \"Hi\"\na(; c=true) # \"\"\na(; b=false) # \"\" also, as `b` is \"falsy\" (e.g., false, nothing, \"\")","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"If the variable name refers to a function that function will be passed the unevaluated string within the section, as expected by the Mustache specification:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Mustache.render(\"{{#:a}}one{{/:a}}\", a=length)  # \"3\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The specification has been widened to accept functions of two arguments, the string and a render function:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tpl = mt\"{{#:bold}}Hi {{:name}}.{{/:bold}}\"\nfunction bold(text, render)\n    \"<b>\" * render(text) * \"</b>\"\nend\ntpl(; name=\"Tater\", bold=bold) # \"<b>Hi Tater.</b>\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"If the tag \"|\" is used, the section value will be rendered first, an enhancement to the specification.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"fmt(txt) = \"<b>\" * string(round(parse(Float64, txt), digits=2)) * \"</b>\";\ntpl = \"\"\"{{|:lambda}}{{:value}}{{/:lambda}} dollars.\"\"\";\nMustache.render(tpl, value=1.23456789, lambda=fmt)  # \"<b>1.23</b> dollars.\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"(Without the | in the tag, an error, ERROR: ArgumentError: cannot parse \"{{:value}}\" as Float64, will be thrown.)","category":"page"},{"location":"#Inverted","page":"Mustache.jl","title":"Inverted","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Related, if the tag begins with ^varname and ends with /varname the text between these tags is included only if the variable is not defined or is falsy.","category":"page"},{"location":"#Iteration","page":"Mustache.jl","title":"Iteration","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"If the section variable, {{#varname}}, binds to an iterable collection, then the text in the section is repeated for each item in the collection with the view used for the context of the template given by the item.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"This is useful for collections of named objects, such as DataFrames (where the collection is comprised of rows) or arrays of dictionaries. For Tables.jl objects the rows are iterated over.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"For data frames, the variable names are specified as symbols or strings. Here is a template for making a web page:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tpl = mt\"\"\"\n<html>\n<head>\n<title>{{:TITLE}}</title>\n</head>\n<body>\n<table>\n<tr><th>name</th><th>summary</th></tr>\n{{#:D}}\n<tr><td>{{:names}}</td><td>{{:summs}}</td></tr>\n{{/:D}}\n</body>\n</html>\n\"\"\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"This can be used to generate a web page for whos-like values:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"_names = String[]\n_summaries = String[]\nfor s in sort(map(string, names(Main)))\n    v = Symbol(s)\n    if isdefined(Main,v)\n        push!(_names, s)\n        push!(_summaries, summary(eval(v)))\n    end\nend\n\nusing DataFrames\nd = DataFrame(names=_names, summs=_summaries)\n\nout = Mustache.render(tpl, TITLE=\"A quick table\", D=d)\nprint(out)","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"This can be compared to using an array of Dicts, convenient if you have data by the row:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"A = [Dict(\"a\" => \"eh\", \"b\" => \"bee\"),\n     Dict(\"a\" => \"ah\", \"b\" => \"buh\")]\ntpl = mt\"{{#:A}}Pronounce a as {{a}} and b as {{b}}. {{/:A}}\"\nMustache.render(tpl, A=A) |> print","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"yielding","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Pronounce a as eh and b as bee. Pronounce a as ah and b as buh.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The same approach can be made to make a LaTeX table from a data frame:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"\nfunction df_to_table(df, label=\"label\", caption=\"caption\")\n    fmt = repeat(\"c\", size(df,2))\n    header = join(string.(names(df)), \" & \")\n    row = join([\"{{:$x}}\" for x in map(string, names(df))], \" & \")\n\ntpl=\"\"\"\n\\\\begin{table}\n  \\\\centering\n  \\\\begin{tabular}{$fmt}\n  $header\\\\\\\\\n{{#:DF}}    $row\\\\\\\\\n{{/:DF}}  \\\\end{tabular}\n  \\\\caption{$caption}\n  \\\\label{tab:$label}\n\\\\end{table}\n\"\"\"\n\n    Mustache.render(tpl, DF=df)\nend","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"In the above, a string is used above – and not a mt macro – so that string interpolation can happen. The jmt_str string macro allows for substitution, so the above template could also have been more simply written as:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"function df_to_table(df, label=\"label\", caption=\"caption\")\n    fmt = repeat(\"c\", size(df,2))\n    header = join(string.(names(df)), \" & \")\n    row = join([\"{{:$x}}\" for x in map(string, names(df))], \" & \")\n\ntpl = jmt\"\"\"\n\\begin{table}\n  \\centering\n  \\begin{tabular}{$fmt}\n  $header\\\\\n{{#:DF}}    $row\\\\\n{{/:DF}}  \\end{tabular}\n  \\caption{$caption}\n  \\label{tab:$label}\n\\end{table}\n\"\"\"\n\n    Mustache.render(tpl, DF=df)\nend","category":"page"},{"location":"#Iterating-over-vectors","page":"Mustache.jl","title":"Iterating over vectors","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Though it isn't part of the Mustache specification, when iterating over an unnamed vector or tuple, Mustache.jl uses {{.}} to refer to the item:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tpl = mt\"{{#:vec}}{{.}} {{/:vec}}\"\nMustache.render(tpl, vec = [\"A1\", \"B2\", \"C3\"])  # \"A1 B2 C3 \"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Note the extra space after C3.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"There is also limited support for indexing with the iteration of a vector that allows one to treat the last element differently. The syntax .[ind] refers to the value vec[ind]. (There is no support for the usual arithmetic on indices.)","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"To print commas one can use this pattern:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tpl = mt\"{{#:vec}}{{.}}{{^.[end]}}, {{/.[end]}}{{/:vec}}\"\nMustache.render(tpl, vec = [\"A1\", \"B2\", \"C3\"])  # \"A1, B2, C3\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"To put the first value in bold, but no others, say:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tpl = mt\"\"\"\n{{#:vec}}\n{{#.[1]}}<bold>{{.}}</bold>{{/.[1]}}\n{{^.[1]}}{{.}}{{/.[1]}}\n{{/:vec}}\n\"\"\"\nMustache.render(tpl, vec = [\"A1\", \"B2\", \"C3\"])  # basically \"<bold>A1</bold>B2 C3\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"This was inspired by this question, but the syntax chosen was more Julian. This syntax – as implemented for now – does not allow for iteration. That is constructs like {{#.[1]}} don't introduce iteration, but only offer a conditional check.","category":"page"},{"location":"#Iterating-when-the-value-of-a-section-variable-is-a-function","page":"Mustache.jl","title":"Iterating when the value of a section variable is a function","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"From the Mustache documentation, consider the template","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"tpl = mt\"{{#:beatles}}\n* {{:name}}\n{{/:beatles}}\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"when beatles is a vector of named tuples (or some other Tables.jl object) and name is a function.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"When iterating over beatles, name can reference the rows of the beatles object by name. In JavaScript, this is done with this.XXX. In Julia, the values are stored in the task_local_storage object (with symbols as keys) allowing the access. The Mustache.get_this function allows JavaScript-like usage:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"function name()\n    this = Mustache.get_this()\n    this.first * \" \" * this.last\nend\nbeatles = [(first=\"John\", last=\"Lennon\"), (first=\"Paul\", last=\"McCartney\")]\n\ntpl(; beatles, name) # \"* John Lennon\\n* Paul McCartney\\n\"","category":"page"},{"location":"#Conditional-checking-without-iteration","page":"Mustache.jl","title":"Conditional checking without iteration","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The section tag, #, check for existence; pushes the object into the view; and then iterates over the object. For cases where iteration is not desirable; the tag type @ can be used.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Compare these:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"julia> struct RANGE\n  range\nend\n\njulia> tpl = mt\"\"\"\n<input type=\"range\" {{@:range}} min=\"{{start}}\" step=\"{{step}}\" max=\"{{stop}}\" {{/:range}}>\n\"\"\";\n\njulia> Mustache.render(tpl, RANGE(1:1:2))\n\"<input type=\\\"range\\\"  min=\\\"1\\\" step=\\\"1\\\" max=\\\"2\\\" >\\n\"\n\njulia> tpl = mt\"\"\"\n<input type=\"range\" {{#:range}} min=\"{{start}}\" step=\"{{step}}\" max=\"{{stop}}\" {{/:range}}>\n\"\"\";\n\njulia> Mustache.render(tpl, RANGE(1:1:2)) # iterates over Range.range\n\"<input type=\\\"range\\\"  min=\\\"1\\\" step=\\\"1\\\" max=\\\"2\\\"  min=\\\"1\\\" step=\\\"1\\\" max=\\\"2\\\" >\\n\"","category":"page"},{"location":"#Non-eager-finding-of-values","page":"Mustache.jl","title":"Non-eager finding of values","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"A view might have more than one variable bound to a symbol. The first one found is replaced in the template unless the variable is prefaced with ~. This example illustrates:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"d = Dict(:two=>Dict(:x=>3), :x=>2)\ntpl = mt\"\"\"\n{{#:one}}\n{{#:two}}\n{{~:x}}\n{{/:two}}\n{{/:one}}\n\"\"\"\nMustache.render(tpl, one=d) # \"2\\n\"\nMustache.render(tpl, one=d, x=1) # \"1\\n\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Were {{:x}} used, the value 3 would have been found within the dictionary Dict(:x=>3); however, the presence of {{~:x}} is an instruction to keep looking up in the specified view to find other values, and use the last one found to substitute in. (This is hinted at in this issue)","category":"page"},{"location":"#Partials","page":"Mustache.jl","title":"Partials","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Partials are used to include partial templates into a template.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Partials begin with a greater than sign, like {{> box.tpl }}. In this example, the file box.tpl is opened and inserted into the template, then populated. A full path may be specified.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"They also inherit the calling context.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"In this way you may want to think of partials as includes, imports, template expansion, nested templates, or subtemplates, even though those aren't literally the case here.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The partial specified by {{< box.tpl }} is not parsed, rather included as is into the file. This can be faster.","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The variable can be a filename, as indicated above, or if not a variable. For example","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"julia> tpl = \"\"\"\\\"{{>partial}}\\\"\"\"\"\n\"\\\"{{>partial}}\\\"\"\n\njulia> Mustache.render(tpl, Dict(\"partial\"=>\"*{{text}}*\",\"text\"=>\"content\"))\n\"\\\"*content*\\\"\"","category":"page"},{"location":"#Summary-of-tags","page":"Mustache.jl","title":"Summary of tags","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"To summarize the different tags marking a variable:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"{{variable}} does substitution of the value held in variable in the current view; escapes HTML characters\n{{{variable}}} does substitution of the value held in variable in the current view; does not escape HTML characters. The outer pair of mustache braces can be adjusted using Mustache.parse.\n{{&variable}} is an alternative syntax for triple braces (useful with custom braces)\n{{~variable}} does substitution of the value held in variable in the outmost view\n{{#variable}} depending on the type of variable, does the following:\nif variable is not a functions container and is not absent or nothing will use the text between the matching tags, marked with {{/variable}}; otherwise that text will be skipped. (Like an if/end block.)\nif variable is a function, it will be applied to contents of the section. Use of | instead of # will instruct the rendering of the contents before applying the function. The spec allows for a function to have signature (x, render) where render is used internally to convert. This implementation allows rendering when (x) is the single argument.\nif variable is a Tables.jl compatible object (row wise, with named rows), will iterate over the values, pushing the named tuple to be the top-most view for the part of the template up to {{\\variable}}.\nif variable is a vector or tuple – for the part of the template up to {{\\variable}} – will iterate over the values. Use {{.}} to refer to the (unnamed) values. The values .[end] and .[i], for a numeric literal, will refer to values in the vector or tuple.\n{{^variable}}/{{.variable}} tags will show the values when variable is not defined, or is nothing.\n{{>partial}} will include the partial value into the template, filling in the template using the current view. The partial can be a variable or a filename (checked with isfile).\n{{<partial}} directly include partial value into template without filling in with the current view.\n{{!comment}} comments begin with a bang, !","category":"page"},{"location":"#Alternatives","page":"Mustache.jl","title":"Alternatives","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Julia provides some alternatives to this package which are better suited for many jobs:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"For simple substitution inside a string there is string interpolation.\nFor piecing together pieces of text either the string function or string concatenation (the * operator) are useful. (Also an IOBuffer is useful for larger tasks of this type.)\nFor formatting numbers and text, the Formatting.jl package, the Format package, and the StringLiterals package are available.\nThe HypertextLiteral package is useful when interpolating HTML, SVG, or SGML tagged content.","category":"page"},{"location":"#Differences-from-Mustache.js","page":"Mustache.jl","title":"Differences from Mustache.js","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"This project deviates from Mustache.js in a few significant ways:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Julia structures are used, not JavaScript objects. As illustrated, one can use Dicts, Modules, DataFrames, functions, ...\nIn the Mustache spec, when lambdas are used as section names, the function is passed the unevaluated section:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"template = \"<{{#lambda}}{{x}}{{/lambda}}>\"\ndata = Dict(\"x\" => \"Error!\", \"lambda\" => (txt) ->  txt == \"{{x}}\" ? \"yes\" : \"no\")\nMustache.render(template, data) ## \"<yes>\", as txt == \"{{x}}\"","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"The tag \"|\" is similar to the section tag \"#\", but will receive the evaluated section:","category":"page"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"template = \"<{{|lambda}}{{x}}{{/lambda}}>\"\ndata = Dict(\"x\" => \"Error!\", \"lambda\" => (txt) ->  txt == \"{{x}}\" ? \"yes\" : \"no\")\nMustache.render(template, data) ## \"<no>\", as \"Error!\" != \"{{x}}\"","category":"page"},{"location":"#API","page":"Mustache.jl","title":"API","text":"","category":"section"},{"location":"","page":"Mustache.jl","title":"Mustache.jl","text":"Modules = [Mustache]","category":"page"},{"location":"#Mustache.Mustache","page":"Mustache.jl","title":"Mustache.Mustache","text":"Mustache\n\nMustache is a templating package for Julia based on Mustache.js. [ Docs ]\n\n\n\n\n\n","category":"module"},{"location":"#Mustache.load-Tuple{Any, Vararg{Any}}","page":"Mustache.jl","title":"Mustache.load","text":"Mustache.load(filepath, args...)\n\nLoad file specified through  filepath and return the compiled tokens. Tokens are memoized for efficiency,\n\nAdditional arguments are passed to Mustache.parse (for adjusting the tags).\n\n\n\n\n\n","category":"method"},{"location":"#Mustache.parse","page":"Mustache.jl","title":"Mustache.parse","text":"Mustache.parse(template, tags = (\"{{\", \"}}\"))\n\nParse a template into tokens.\n\ntemplate: a string containing a template\ntags: the tags used to indicate a variable. Adding interior braces ({,}) around the  variable will prevent HTML escaping. (That is for the default tags, {{{varname}}} is used; for tags like (\"<<\",\">>\") then <<{varname}>> is used.)\n\nExtended\n\nThe template interprets tags in different ways. The string macro mt is used below to both parse (on construction) and render (when called).\n\nVariable substitution.\n\nLike basic string interpolation, variable subsitution can be performed using a non-prefixed tag:\n\njulia> using Mustache\n\njulia> a = mt\"Some {{:variable}}.\";\n\njulia> a(; variable=\"pig\")\n\"Some pig.\"\n\njulia> a = mt\"Cut: {{{:scissors}}}\";\n\njulia> a(; scissors = \"8< ... >8\")\n\"Cut: 8< ... >8\"\n\nBoth using a symbol, as the values to subsitute are passed through keyword arguments. The latter uses triple braces to inhibit the escaping of HTML entities.\n\nTags can be given special meanings through prefixes. For example, to avoid the HTML escaping an & can be used:\n\njulia> a = mt\"Cut: {{&:scissors}}\";\n\njulia> a(; scissors = \"8< ... >8\")\n\"Cut: 8< ... >8\"\n\nSections\n\nTags can create \"sections\" which can be used to conditionally include text, apply a function to text, or iterate over the values passed to render.\n\nInclude text\n\nTo include text, the # prefix can open a section followed by a / to close the section:\n\njulia> a = mt\"I see a {{#:ghost}}ghost{{/:ghost}}\";\n\njulia> a(; ghost=true)\n\"I see a ghost\"\n\njulia> a(; ghost=false)\n\"I see a \"\n\nThe latter is to illustrate that if the variable does not exist or is \"falsy\", the section text will not display.\n\nThe ^ prefix shows text when the variable is not present.\n\njulia> a = mt\"I see {{#:ghost}}a ghost{{/:ghost}}{{^:ghost}}nothing{{/:ghost}}\";\n\njulia> a(; ghost=false)\n\"I see nothing\"\n\nApply a function to the text\n\nIf the variable refers to a function, it will be applied to the text within the section:\n\njulia> a = mt\"{{#:fn}}How many letters{{/:fn}}\";\n\njulia> a(; fn=length)\n\"16\"\n\nThe use of the prefix ! will first render the text in the section, then apply the function:\n\njulia> a = mt\"The word '{{:variable}}' has {{|:fn}}{{:variable}}{{/:fn}} letters.\";\n\njulia> a(; variable=\"length\", fn=length)\n\"The word 'length' has 6 letters.\"\n\nIterate over values\n\nIf the variable in a section is an iterable container, the values will be iterated over. Tables.jl compatible values are iterated in a row by row manner, such as this view, which is a tuple of named tuples:\n\njulia> a = mt\"{{#:data}}x={{:x}}, y={{:y}} ... {{/:data}}\";\n\njulia> a(; data=((x=1,y=2), (x=2, y=4)))\n\"x=1, y=2 ... x=2, y=4 ... \"\n\nIterables like vectors, tuples, or ranges – which have no named values – can have their values referenced by a {{.}} tag:\n\njulia> a = mt\"{{#:countdown}}{{.}} ... {{/:countdown}} blastoff\";\n\njulia> a(; countdown = 5:-1:1)\n\"5 ... 4 ... 3 ... 2 ... 1 ...  blastoff\"\n\nPartials\n\nPartials allow subsitution. The use of the tag prefex > includes either a file or a string and renders it accordingly:\n\njulia> a = mt\"{{>:partial}}\";\n\njulia> a(; partial=\"variable is {{:variable}}\", variable=42)\n\"variable is 42\"\n\nThe use of the tag prefix < just includes the partial (a file in this case) without rendering.\n\nComments\n\nUsing the tag-prefix ! will comment out the text:\n\njulia> a = mt\"{{! ignore this comment}}This is rendered\";\n\njulia> a()\n\"This is rendered\"\n\nMulti-lne comments are permitted.\n\n\n\n\n\n","category":"function"},{"location":"#Mustache.render-Tuple{IO, Mustache.MustacheTokens, Any}","page":"Mustache.jl","title":"Mustache.render","text":"render([io], tokens, view)\nrender([io], tokens; kwargs...)\n(tokens::MustacheTokens)([io]; kwargs...)\n\nRender a set of tokens with a view, using optional io object to print or store.\n\nArguments\n\nio::IO: Optional IO object.\ntokens: Either Mustache tokens, or a string to parse into tokens\nview: A view provides a context to look up unresolved symbols demarcated by mustache braces. A view may be specified by a dictionary, a module, a composite type, a vector, a named tuple, a data frame, a Tables object, or keyword arguments.\n\nnote: Note\nThe render method is currently exported, but this export may be deprecated in the future.\n\n\n\n\n\n","category":"method"},{"location":"#Mustache.render_from_file-Tuple{Any, Any}","page":"Mustache.jl","title":"Mustache.render_from_file","text":"render_from_file(filepath, view)\nrender_from_file(filepath; kwargs...)\n\nRenders a template from filepath and view.\n\nnote: Note\nThis function simply combines Mustache.render and Mustache.load and may be deprecated in the future.\n\n\n\n\n\n","category":"method"},{"location":"#Mustache.@jmt_str-Tuple{String}","page":"Mustache.jl","title":"Mustache.@jmt_str","text":"jmt\"string\"\n\nString macro that interpolates values escaped by dollar signs, then parses strings.\n\nNote: modified from a macro in HypertextLiteral.\n\nExample:\n\nx = 1\ntoks = jmt\"$(2x) by {{:a}}\"\ntoks(; a=2) # \"2 by 2\"\n\n\n\n\n\n","category":"macro"},{"location":"#Mustache.@mt_str-Tuple{Any}","page":"Mustache.jl","title":"Mustache.@mt_str","text":"mt\"string\"\n\nString macro to parse tokens from a string. See parse.\n\n\n\n\n\n","category":"macro"}]
}
