module XPlot
using JLD2
using StatsBase
using HypothesisTests
using Bootstrap
using Plots

export TimeSeriesData, load, group, agg, plot, plot!, NameConfig, rolling
export kruskal_wallis, wilcoxon, run_all_pairwise_wilcoxon, glass_delta, compute_all_glass_deltas
    

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
