using Mustache
using Base.Test

tpl = mt"a:{{x}} b:{{{y}}}"

x, y = "ex", "why"
d = {"x"=>"ex", "y"=>"why"}
type ThrowAway
    x
    y
end

@test render(tpl, Main) == "a:ex b:why"
@test render(tpl, d) == "a:ex b:why"
@test render(tpl, ThrowAway(x,y)) == "a:ex b:why"


## triple quoted
tpl = mt"""a:{{x}} b:{{y}}"""


@test render(tpl, Main) == "a:ex b:why"
@test render(tpl, d) == "a:ex b:why"
@test render(tpl, ThrowAway(x,y)) == "a:ex b:why"

## conditional
tpl = "{{#b}}this doesn't show{{/b}}{{#a}}this does show{{/a}}"
@test render(tpl, {"a" => 1}) == "this does show"

## dict using symbols
d = { :a => x, :b => y}
tpl = "a:{{:a}} b:{{:b}}"
@test render(tpl, d) == "a:ex b:why"


## Data frame test
glm_tpl = mt"""
\begin{table}
\begin{tabular}{l @{\quad} rrrr}
{{#colnms}}
&\verb+{{{colnm}}}+
{{/colnms}}\\
{{#mat}}
{{variable}} & {{col1}} & {{col2}} & {{col3}} & {{col4}}\\
{{/mat}}
\end{tabular}
\end{table}
"""

function glm_table(mod)
    tbl = coeftable(mod)

    colnms = DataFrame(colnm=tbl.colnms)
    mat = DataFrame(variable=tbl.rownms)
    for j in 1:size(tbl.mat)[2]
        nm = "col$j"
        mat[symbol(nm)] = map(x -> @sprintf("%.2f", x), tbl.mat[:,j])
    end
    
    Mustache.render(glm_tpl,{"colnms"=>colnms, "mat"=>mat})
end



using GLM, RDatasets, DataFrames
LifeCycleSavings = dataset("datasets", "LifeCycleSavings")
fm2 = fit(LinearModel, SR ~ Pop15 + Pop75 + DPI + DDPI, LifeCycleSavings)
print(glm_table(fm2))
