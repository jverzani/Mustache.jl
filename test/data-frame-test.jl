## Data frame test
## not run by default. Too time consuming and relies on external pacakgs
using Mustache, DataFrames

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
