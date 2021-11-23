export Technology, 
Timestep, 
Variable, 
Carrier, 
Region,
Scenario
Mask,
PivotResult,
pivotresult

const colnames = (
    Region = "region_dispatch_",
    Technology = "technology_",
    Timestep = "timestep_superordinate_dispatch_",
    Carrier = "carrier_",
    Variable = "variable",
    Scenario = "scenario"
)

abstract type ResultDimension{T} end
abstract type ResultWithDimension{T} <: ResultDimension{T} end
abstract type ResultWithoutDimension{T} <: ResultDimension{T} end
const SuperType = Union{AbstractVector, AbstractString, Nothing}


for dimension = (:Technology, :Timestep, :Carrier, :Region)
    eval(quote
        struct $dimension{T<:SuperType} <: ResultWithDimension{T}
            vals::T
            mode::Symbol
            dim::Int
            colname::AbstractString
        
            function $dimension()
                colname = colnames.$dimension * "1"
                return new{Nothing}(nothing, :equal, 1, colname)
            end
            
            function $dimension(p::T; mode = :in) where T<:Pair{<:Int,<:AbstractVector}
                dim, val = p
                colname = colnames.$dimension * "$dim"
                return new{typeof(val)}(val, mode, dim, colname)
            end

            function $dimension(p::T; mode = :equal) where T<:Pair{<:Int,<:AbstractString}
                dim, val = p
                colname = colnames.$dimension * "$dim"
                return new{typeof(val)}(val, mode, dim, colname)
            end

            function $dimension(x::T; mode = :equal, dim=1) where T<:AbstractString
                colname = colnames.$dimension * "$dim"
                return new{T}(x, mode, dim, colname)
            end

            function $dimension(i::T; mode = :equal) where T<:Integer
                colname = colnames.$dimension * "$i"
                return new{Nothing}(nothing, mode, i, colname)
            end

            function $dimension(vec::T; mode = :in, dim=1) where T<:AbstractVector
                colname = colnames.$dimension * "$dim"
                return new{T}(vec, mode, dim, colname)
            end

            function $dimension(args::T...; mode = :in, dim=1) where T<:AbstractString
                colname = colnames.$dimension * "$dim"
                vec = [args...]
                return new{typeof(vec)}(vec, mode, dim, colname)
            end
        end
    end)
end

for dimension = (:Variable, :Scenario)
    eval(quote
        struct $dimension{T<:SuperType} <: ResultWithoutDimension{T}
            vals::T
            mode::Symbol
            colname::AbstractString
        
            $dimension() = new{Nothing}(nothing, :equal, nothing)
            
            function $dimension(x::T; mode = :equal) where T<:AbstractString
                colname = colnames.$dimension
                return new{T}(x, mode, colname)
            end

            function $dimension(vec::T; mode = :in) where T<:AbstractVector
                colname = colnames.$dimension
                return new{T}(vec, mode, colname)
            end

            function $dimension(args::T...; mode = :in) where T<:AbstractString
                colname = colnames.$dimension
                vec = [args...]
                return new{typeof(vec)}(vec, mode, colname)
            end
        end
    end)
end

struct Mask
    row::ResultDimension
    col::ResultDimension
    filters::Vector{ResultDimension}

    function Mask(row::ResultDimension, col::ResultDimension, filters::ResultDimension...)
        new(row, col, [filters...])
    end
end

function filter_df!(df::AbstractDataFrame, af::ResultDimension{Nothing})
    return df
end


function filter_df!(df::AbstractDataFrame, af::ResultDimension{T}) where T<:AbstractString

    if af.colname in names(df)
        if af.mode == :equal
            filter!(x-> isequal(af.vals, x[af.colname]), df)
        elseif af.mode == :occursin
            filter!(x-> occursin(af.vals, x[af.colname]), df)
        else 
            @warn "Mode $(af.mode) is not supported for filtering based on a string" af.vals
        end
    else
        @warn "Column $(af.colname) does not exists in DataFrame" names(df)
    end
    
    return df
end

function filter_df!(df::AbstractDataFrame, af::ResultDimension{T}) where T<:AbstractVector

    if af.colname in names(df)
        if af.mode == :in
            filter!(x-> x[af.colname] in af.vals, df)
        else 
            @warn "Mode $(af.mode) is not supported for filtering based on a vector" af.vals
        end
    else
        @warn "Column $(af.colname) does not exists in DataFrame" names(df)
    end
    
    return df
end

struct PivotResult
    result::AnymodResult
    mask::Mask
    df::AbstractDataFrame
    
    function PivotResult(ar::AnymodResult, m::Mask)

        df = copy(ar.summarytable)
        # filter summarytable
        for fil in m.filters
            filter_df!(df, fil)
        end

        filter_df!(df, m.row)
        filter_df!(df, m.col)

        groupkeys = [m.row.colname, m.col.colname]
        df = combine(groupby(df, groupkeys), "value" => sum => "value")
        df = unstack(df, m.row.colname, m.col.colname, "value")
        return new(ar, m, df)
    end
end

function pivotresult(ar::AnymodResult, m::Mask)
    return PivotResult(ar, m).df
end