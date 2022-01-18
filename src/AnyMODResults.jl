module AnyMODResults

using CSV
using DataFrames
using Glob
using PlotlyJS
using Pkg

include("postprocessing.jl")
include("AnymodResult.jl")
include("Mask.jl")
include("plots.jl")

end # module
