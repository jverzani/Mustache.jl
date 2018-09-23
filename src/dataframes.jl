# on loading of DataFrames
# eventually this will be in DataFrames

Tables.istable(d::DataFrames.AbstractDataFrame) = true
Tables.rows(d::DataFrames.AbstractDataFrame) = DataFrameRowWrapper(d)

struct DataFrameRowWrapper
d
end

function Base.iterate(D::DataFrameRowWrapper, state=(1, size(D.d)...))
    i,m,n = state
    d = D.d
    i > m && return nothing
    cols = Tuple(d[i,j] for j in 1:n)
    (NamedTuple{Tuple(names(d)),typeof(cols)}(cols), (i+1, m, n))
end
