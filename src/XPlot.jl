module XPlot
using HDF5
using StatsBase
using HypothesisTests
using Bootstrap
using Plots
using FileWatching

export TimeSeriesData, load, group, agg, plot, plot!, NameConfig 
export kruskal_wallis, wilcoxon, run_all_pairwise_wilcoxon, glass_delta, compute_all_glass_deltas
export savefig, h5open, read
    
HEAD="iter"

include("./name-inference.jl")
include("./measurements.jl")
include("./timeseries.jl")
include("./metrics.jl")
include("./statests.jl")
end
