export plot_anymod_result

pjs_rgb(r::Int,g::Int,b::Int) = "rgb($r, $g, $b))"
rand_rgb() = pjs_rgb(rand(1:255), rand(1:255), rand(1:255))


function get_x_axis(row::AbstractArray)
    return map(x-> x.colname |> Symbol, row)
end

get_x_axis(row) = row.colname |> Symbol

xval(df, x::AbstractArray) = [df[!,x[1]], df[!,x[2]]]
xval(df, x::Symbol) = df[!,x]

function grouped_plot(df::AbstractDataFrame, x, col; colors::Dict=Dict())
    g = col.colname |> Symbol
    g_vals = unique(df[:,g])
    traces = map(g_vals) do g_key
        df_g = filter(y-> y[g] == g_key, df)
        t = GenericTrace(
            xval(df_g, x),
            df_g[!, :value],
            kind = "bar",
            name = g_key,
            color = get(colors, g_key, rand_rgb())
        )
        return t
    end

    return traces
end


function grouped_plot(df::AbstractDataFrame, x, col::Nothing;
    colors::Dict=Dict()
)
    trace = GenericTrace(
        xval(df, x),
        df[!, :value],
        kind = "bar"
    )

    return trace
end

function plot_anymod_result(ar::AnymodResult, m::Mask)
    df = stackedresult(ar, m)
    x = get_x_axis(m.row)
    traces = grouped_plot(df, x, m.col)
    layout = Layout(;barmode="relative")
    return Plot(traces, layout)
end