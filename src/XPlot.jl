module XPlot
using JLD2
using StatsBase
using HypothesisTests
using Plots

export TimeSeriesData, TimeSeriesPlot, load, agg, plot, NameConfig, rolling
    

include("./name-inference.jl")
include("./timeseries.jl")
include("./metrics.jl")
include("./metrics/iderrs.jl")
include("./metrics/sort.jl")
include("./metrics/phylogeneticestimator.jl")
end
