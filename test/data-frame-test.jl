## Data frame test
## not run by default. Too time consuming and relies on external pacakgs
using Mustache, DataFrames
using Test

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
        mat[Symbol(nm)] = map(x -> @sprintf("%.2f", x), tbl.mat[:,j])
    end

    Mustache.render(glm_tpl,Dict("colnms"=>colnms, "mat"=>mat))
end



using GLM, RDatasets, DataFrames
LifeCycleSavings = dataset("datasets", "LifeCycleSavings")
fm2 = fit(LinearModel, SR ~ Pop15 + Pop75 + DPI + DDPI, LifeCycleSavings)
glm_table(fm2)


## Issue with data frames as keyword arguments
tpl = """
{{#:fred}}{{:a}}--{{:b}}{{/:fred}}
{{:barney}}
"""
d = DataFrame(a=[1,2,3], b=[3,2,1])
@test render(tpl, fred=d, barney="123") == "1--32--23--1\n123\n"
