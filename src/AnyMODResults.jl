module AnyMODResults

using CSV
using DataFrames
using Glob

include("postprocessing.jl")
include("AnymodResult.jl")
include("Mask.jl")

export AnymodResult

end # module
