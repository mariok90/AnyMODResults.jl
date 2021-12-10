module AnyMODResults

using CSV
using DataFrames
using Glob
using Pkg

include("postprocessing.jl")
include("AnymodResult.jl")
include("Mask.jl")

export AnymodResult

end # module
