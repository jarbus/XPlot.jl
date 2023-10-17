module XPlot
using JLD2
using StatsBase
using HypothesisTests
using Plots

export InteractionDistanceErrors, TimeSeriesData, TimeSeriesPlot, load, agg, plot, NameConfig

include("./name-inference.jl")
include("./timeseries.jl")
include("./metrics.jl")
end
