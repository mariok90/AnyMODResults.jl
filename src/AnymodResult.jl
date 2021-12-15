function extract_result_files(path, identifier="")
    filenames = glob("results_$(identifier)*.csv", path)
    extracted_filenames =  map(filenames) do fp
        splitted_paths = splitpath(fp)
        if length(splitted_paths) > 1
            return last(splitted_paths)
        else
            return first(splitted_paths)
        end
    end
    return extracted_filenames
end


function detect_scenarios(path)
    filenames = extract_result_files(path)
    array_of_strings = map(x -> split(x, "_"), filenames)
    scenario_list = map(array_of_strings) do arr
        subarr = arr[3:(end - 1)]
        if length(subarr) > 1
            return join(subarr, "_")
        else
            return first(subarr)
        end
    end

    return Vector{String}(unique(scenario_list))
end


function get_pkg_version(name::AbstractString)
    vals = Pkg.dependencies() |> values
    pkg_info = [x for x in vals if x.name == name] |> only
    return pkg_info.version
end

function read_csv(x::AbstractString)
    if get_pkg_version("CSV") >= v"0.7"
        return CSV.read(x, DataFrame)
    else
        return CSV.read(x)
    end
end

function join_table_by_type(path, identifier)
    # get filenames of the relevant csv files
    filepaths = glob("results_$(identifier)*.csv", path)
    filenames = extract_result_files(path, identifier)

    # check if any files exists
    if isempty(filepaths)
        str = "results_$(identifier)*.csv"
        @warn "No files matching $str found in $(path)!"
        return DataFrame()
    end

    # iterate over each file and process it
    dfs = map(zip(filenames,filepaths)) do (filename, filepath)
        df = read_csv(filepath)
        splitted_filename = split(filename, "_")

        # split of the head and the tail
        scen_name = splitted_filename[3:(end - 1)]

        # if the scenario name contains a _ the name should be remerged
        if length(scen_name) > 1
            scen_name = join(scen_name, "_")
        else
            scen_name = first(scen_name)
        end

        # add scenario as column
        df[!, "scenario"] .= scen_name

        # expand the index columns
        identifier == "summary" && expand_col!(df, "region_dispatch")
        identifier == "costs" && expand_col!(df, "region")
        identifier == "exchange" && expand_col!(df, "region_from")
        identifier == "exchange" && expand_col!(df, "region_to")
        identifier == "exchange" || expand_col!(df, "technology")
        expand_col!(df, "carrier")
        expand_col!(df, "timestep_superordinate_dispatch")

        # drop the expanded columns based on filetype
        if identifier == "summary"
            drop_cols = [:region_dispatch, :technology]
        elseif identifier == "costs"
            drop_cols = [:region, :technology]
        elseif identifier == "exchange"
            drop_cols = [:region_from, :region_to]
        end
        append!(drop_cols, [:timestep_superordinate_dispatch, :carrier])
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
    # elseif isempty(dfs)
    #     @warn "DataFrame ist empty!"
    #     return dfs
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

    function AnymodResult(path; threaded=true)
        if threaded
            scenario_task = Threads.@spawn detect_scenarios(path)
            tables = ["summary", "costs", "exchange"]
            table_tasks = [Threads.@spawn join_table_by_type(path, x) for x in tables]

            return new(fetch(scenario_task), fetch.(table_tasks)...)
        else
            scenarios = detect_scenarios(path)
            tables = ["summary", "costs", "exchange"]

            return new(
                scenarios,
                [join_table_by_type(path, x) for x in tables]...
            )
        end
    end
end
