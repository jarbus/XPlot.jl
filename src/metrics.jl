export BestSortPercentage, InteractionDistanceErrors, SortFits
abstract type AbstractMetric end

function load(
        metric::AbstractMetric,
        nc::NameConfig,
        paths::Vector{String}
    )
    paths = find_datapath_recursively(nc, paths)
    @assert length(paths) > 0 "No paths found"

    vcat([_load(metric, nc, path) for path in paths]...)
end
load(metric::AbstractMetric, nc::NameConfig, path::String)= load(metric, nc, [path])

function subdir_naming_scheme(nc::NameConfig, path::String)
    # We assume that the path is an absolute
    s = remove_relative_datapath(nc, path) |> dirname
    trial = basename(s)
    s = dirname(s)
    xname = basename(s)
    s = dirname(s)
    classname = basename(s)
    classname, xname, trial
end

function _load_datapoints(file,path;statistical=false)
    dp = TimeSeriesDataPoint[]
    for gen in keys(file["gen"])

        full_path = joinpath("gen/$gen", path)
        if !haskey(file, full_path)
            #error("No key $full_path in file")
            continue
        end
        if statistical
            stats = file[full_path]
            datapoint = TimeSeriesDataPoint(
                parse(Int, gen),
                stats["mean"],
                stats["lower_confidence"],
                stats["upper_confidence"],
            )
        else
            datapoint = TimeSeriesDataPoint(parse(Int, gen),
                    file[full_path],
                    nothing, nothing)
        end
        push!(dp, datapoint)
    end
    @assert length(dp) > 0 "No datapoints found in $path"
    sort!(dp, by=x->x.x)
    dp
end

struct InteractionDistanceErrors <: AbstractMetric
    distances::Vector{Int}
end
InteractionDistanceErrors(r::UnitRange{Int}) = InteractionDistanceErrors(collect(r))

function general_load(
        f,
        metric::AbstractMetric,
        nc::NameConfig,
        path::String
    )
    classname, xname, trial = subdir_naming_scheme(nc, path)
    println("Loading cls=$classname x=$xname trial=$trial")
    timeseries = TimeSeriesData[]

    jldopen(path, "r") do file
        f(file, metric, xname, trial, timeseries)
    end
    timeseries = filter(x -> length(x.data) > 0, timeseries)
    return timeseries
end

function _load(
        iders::InteractionDistanceErrors,
        nc::NameConfig,
        path::String
    )
    general_load(iders, nc, path) do file, iders, xname, trial, timeseries
        for distance in iders.distances
            push!(timeseries, TimeSeriesData(
                "InteractionDistanceError",
                 _load_datapoints(file, "tree_stats/dist_int_errors/$distance"; statistical=true),
                xname,
                "EstimateError",
                "distance=$distance",
                parse(Int, trial)
            ))
        end
    end
end


struct SortFits <: AbstractMetric end
struct BestSortPercentage <: AbstractMetric end


function _load(
        met::SortFits,
        nc::NameConfig,
        path::String
    )
    general_load(met, nc, path) do file, met, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "SortingNetworkFitness",
                  _load_datapoints(file, "sorted/sn_fitnesses"; statistical=true),
                 xname,
                 "Fitness",
                 "SortingNetwork",
                 parse(Int, trial)
             )
         )

        push!(timeseries, TimeSeriesData(
                 "SortingNetworkTestCaseFitness",
                  _load_datapoints(file, "sorted/tc_fitnesses"; statistical=true),
                 xname,
                 "Fitness",
                 "TestCase",
                 parse(Int, trial)
             )
        )
    end
end



function _load(
        met::BestSortPercentage,
        nc::NameConfig,
        path::String
    )


    general_load(BestSortPercentage(), nc, path) do file, sf, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "BestSortPercentage",
                  _load_datapoints(file, "sorted/best_sorter_percent"),
                 xname,
                 "Percentage",
                 "",
                 parse(Int, trial)
             )
         )
    end
end
