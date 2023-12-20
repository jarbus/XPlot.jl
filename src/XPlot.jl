module XPlot
using JLD2
using StatsBase
using HypothesisTests
using Plots

export TimeSeriesData, load, agg, plot, plot!, NameConfig, rolling
    

include("./name-inference.jl")
include("./timeseries.jl")
include("./metrics.jl")
include("./metrics/iderrs.jl")
include("./metrics/sort.jl")
include("./metrics/phylogeneticestimator.jl")
include("./metrics/genotypesum.jl")
include("./metrics/genotypesize.jl")
include("./metrics/estimatecacheevalsample.jl")
end
