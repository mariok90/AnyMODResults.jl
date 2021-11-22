export Technology, 
Timestep, 
Variable, 
Carrier, 
Region,
Mask,
PivotResult

abstract type ResultDimension end

for dim = (:Technology, :Timestep, :Variable, :Carrier, :Region, :Scenario)
    eval(quote
        struct $dim <: ResultDimension
            pairs
            mode::Symbol
            dim::Int
        
            $dim() = new(nothing, :filter, 1)
            function $dim(args::Pair...; mode = :equal, dim=0)
                if dim == 0
                    dim = getindex.(args, 1) |> first |> maximum
                end

                return new([args...], mode, dim)
            end

            function $dim(args::T...; mode = :equal, dim=1) where T<:AbstractString
                return new([args...], mode, dim)
            end

            function $dim(i::T; mode = :equal, dim=1) where T<:Integer
                return new(nothing, mode, i)
            end
        end
    end)
end

struct Mask
    row
    col
    filters

    function Mask(row, col, filters...)
        new(row, col, [filters...])
    end
end

const colname_dict = Dict(
    :Region => "region_dispatch_",
    :Technology => "technology_",
    :Timestep => "timestep_superordinate_dispatch_",
    :Carrier => "carrier_",
    :Variable => "variable",
    :Scenario => "scenario"
)

function get_col_name_sceleton(af::ResultDimension, p::Pair)
    dim_type = typeof(af) |> Symbol
    dim = p[1]
    return  colname_dict[dim_type]*"$dim"
end

function get_col_name_sceleton(af::ResultDimension, x::AbstractString)
    dim_type = typeof(af) |> Symbol
    return  colname_dict[dim_type]
end

function get_col_name_sceleton(af::ResultDimension, i::Int)
    dim_type = typeof(af) |> Symbol
    return colname_dict[dim_type]*"$i"
end


function anyfilter!(df::AbstractDataFrame, af::ResultDimension)

    isnothing(af.pairs) && return df
    # check if column exists
    cols = names(df)
    for p in af.pairs
        colname = get_col_name_sceleton(af, p)
        if colname in cols
            typeof(p) <: Pair ? (y = p[2]) : (y = p)   
            if af.mode == :equal
                filter!(x-> isequal(y, x[colname]), df)
            elseif af.mode == :occursin
                filter!(x-> occursin(y, x[colname]), df)
            elseif af.mode == :in
                filter!(x-> x[colname] in y, df)
            else
                @error "Mode '$(af.mode)' is not supported!"
            end
        else
            @warn "Column $colname does not exists in DataFrame" cols
        end
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
            anyfilter!(df, fil)
        end

        anyfilter!(df, m.row)
        anyfilter!(df, m.col)
        rowkeys = get_col_name_sceleton(m.row, m.row.dim)
        colkey = get_col_name_sceleton(m.col, m.col.dim)
        df = combine(groupby(df, [rowkeys, colkey]), "value" => sum => "value")
        df = unstack(df, rowkeys, colkey, "value")
        return new(ar, m, df)
    end
end