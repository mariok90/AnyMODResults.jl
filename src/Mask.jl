export Technology, 
Timestep, 
Variable, 
Carrier, 
Region,
Scenario,
Mask,
PivotResult,
pivotresult,
StackedResult,
stackedresult

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
const SuperType = Union{AbstractVector, AbstractString, Nothing, Int}


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
                int_val = tryparse(Int, val)                
                if isnothing(int_val)
                    return new{typeof(val)}(val, mode, dim, colname)
                else
                    return new{typeof(int_val)}(int_val, mode, dim, colname)
                end
            end

            function $dimension(p::T; mode = :equal) where T<:Pair{<:Int,<:Int}
                dim, val = p
                colname = colnames.$dimension * "$dim"
                return new{typeof(val)}(val, mode, dim, colname)
            end

            function $dimension(x::T; mode = :equal, dim=1) where T<:AbstractString
                colname = colnames.$dimension * "$dim"
                int_val = tryparse(Int, x)
                if isnothing(int_val)
                    return new{T}(x, mode, dim, colname)
                else
                    return new{typeof(int_val)}(int_val, mode, dim, colname)
                end
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
                args_int = tryparse.(Int, args)
                @show args_int
                if eltype(args_int) <: Int
                    vec = [args_int...]
                else
                    vec = [args...]
                end
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
        
            $dimension() = new{Nothing}(nothing, :equal, colnames.$dimension)
            
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
    row
    col::ResultDimension
    filters::Vector{ResultDimension}

    function Mask(row, col::ResultDimension, filters::ResultDimension...)
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

function filter_df!(df::AbstractDataFrame, af::ResultDimension{T}) where T<:Int

    if af.colname in names(df)
        if af.mode == :equal
            coltype = eltype(df[:,af.colname])
            if coltype <: Int
                filter!(x-> isequal(af.vals, x[af.colname]), df)
            elseif coltype <: AbstractString
                filter!(x-> string(af.vals) == x[af.colname], df)
            else
                @warn "Type $coltype in column $(af.colname) could not be filtered!"
            end
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



function filter_df!(df::AbstractDataFrame, vec::T) where T<:AbstractVector
    for fil in vec
        filter_df!(df, fil)
    end
    return df
end

function filter_results(ar::AnymodResult, m::Mask)
    df = copy(ar.summarytable)
    # filter summarytable
    filter_df!(df, m.filters)
    filter_df!(df, m.row)
    filter_df!(df, m.col)

    return df
end



struct PivotResult
    result::AnymodResult
    mask::Mask
    df::AbstractDataFrame
    
    function PivotResult(ar::AnymodResult, m::Mask)

        df = filter_results(ar, m)

        # to do: handle case when df is empty

        if m.row isa Array
            colnames = [rt.colname for rt in m.row]
            groupkeys = [colnames..., m.col.colname]
        else
            groupkeys = [m.row.colname, m.col.colname]
            colnames = m.row.colname
        end
        df = combine(groupby(df, groupkeys), "value" => sum => "value")
        df = unstack(df, colnames, m.col.colname, "value")
        return new(ar, m, df)
    end
end

function pivotresult(ar::AnymodResult, m::Mask)
    return PivotResult(ar, m).df
end

struct StackedResult
    result::AnymodResult
    mask::Mask
    df::AbstractDataFrame
    
    function StackedResult(ar::AnymodResult, m::Mask)

        df = filter_results(ar, m)

        # to do: handle case when df is empty

        if m.row isa Array
            colnames = [rt.colname for rt in m.row]
            groupkeys = [colnames..., m.col.colname]
        else
            groupkeys = [m.row.colname, m.col.colname]
            colnames = m.row.colname
        end
        df = combine(groupby(df, groupkeys), "value" => sum => "value")
        return new(ar, m, df)
    end
end

function stackedresult(ar::AnymodResult, m::Mask)
    return StackedResult(ar, m).df
end