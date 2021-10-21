


function detect_scenarios(path)
    filenames = glob("results_*.csv", path)
    array_of_strings = map(x-> split(x, "_"), filenames)
    scenario_list = getindex.(array_of_strings, 3)
    return unique(scenario_list) |> Vector{String}
end

function join_table_by_type(path, identifier)
    # get filenames of the relevant csv files
    filenames = glob("results_$(identifier)*.csv", path)
    
    # iterate over each file and process it
    dfs = map(filenames) do file
        df = CSV.read(file, DataFrame)
        splitted_filename = split(file, "_")

        # third positions should contain the scenario name
        df[!, "scenario"] .= splitted_filename[3] 

        # expand the index columns
        identifier == "summary" && expand_col!(df, "region_dispatch")
        identifier == "costs" && expand_col!(df, "region")
        identifier == "exchange" && expand_col!(df, "region_from")
        identifier == "exchange" && expand_col!(df, "region_to")
        identifier == "exchange" || expand_col!(df, "technology")
        expand_col!(df, "carrier")

        # drop the expanded columns based on filetype
        if identifier == "summary"
            drop_cols = [:region_dispatch, :technology, :carrier]
        elseif identifier == "costs"
            drop_cols = [:region, :technology, :carrier]
        elseif identifier == "exchange"
            drop_cols = [:region_from, :region_to, :carrier]
        end
        select!(df, Not(drop_cols))

        return df
    end

    # checking if the columns are the same
    if length(dfs) > 1 # only check if there is more than one scenario
        for df in dfs[2:end]
            # are the column names equal?
            first_df_cols = names(dfs[1])
            other_cols = names(df)
            if !(isequal(first_df_cols, other_cols))
                error("The column headers of the loaded files are not identical")
            end
        end

        # append the dataframes if columns fit and return
        return reduce(vcat, dfs)
    else
        # return if only one scenario exists
        return dfs[1]
    end
end

struct AnymodResult
    scenarios
    summarytable
    costtable
    exchangetable

    function AnymodResult(path)
        scenario_task = Threads.@spawn detect_scenarios(path)
        tables = ["summary", "costs", "exchange"]
        table_tasks = [
            Threads.@spawn join_table_by_type(path, x) for x in tables
        ]

    return new(
        fetch(scenario_task),
        fetch.(table_tasks)...,
    )
    end
end