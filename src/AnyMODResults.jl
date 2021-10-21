module AnyMODResults

using CSV
using DataFrames
using Glob

include("postprocessing.jl")
include("AnymodResult.jl")

export AnymodResult

end # module
