module XPlot
using JLD2
using StatsBase
using HypothesisTests
using Bootstrap
using Plots
using FileWatching

export TimeSeriesData, load, group, agg, plot, plot!, NameConfig, rolling
export kruskal_wallis, wilcoxon, run_all_pairwise_wilcoxon, glass_delta, compute_all_glass_deltas
    

include("./name-inference.jl")
include("./timeseries.jl")
include("./metrics.jl")
include("./statests.jl")
end
