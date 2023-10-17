module XPlot
using JLD2
using StatsBase
using HypothesisTests
using Plots

export InteractionDistanceErrors, TimeSeriesData, TimeSeriesPlot, load, agg, plot

include("./timeseries.jl")
include("./metrics.jl")
end
