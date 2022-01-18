using AnyMODResults
using Test
using Suppressor
using CSV
using DataFrames
using JSON

function compare_table_values(loaded_Result, test_result)

    error_flag = false

    for x in eachindex(loaded_Result[:,1]), y in names(loaded_Result)[2:end]
        target = loaded_Result[x,y]
        result = test_result[x,y]
        if ismissing(target)
            ismissing(result) || (error_flag = true)
        elseif target isa AbstractString
            String(target) == String(result) || (error_flag = true)
        elseif target isa Number && result isa Number
            target ≈ result || (error_flag = true)
        else
            error_flag = true
        end

        if error_flag
            @warn "Test failed" target=target actual_result=result
            return false
        end
    end

    return true
end


include("testset1.jl")
include("testset2.jl")
include("testset3.jl")
