abstract type AbstractMetric end

function load(
        metric::AbstractMetric,
        nc::NameConfig,
        paths::Vector{String}
    )
    paths = find_datapath_recursively(nc, paths)

    vcat([load(metric, nc, path) for path in paths]...)
end
load(metric::AbstractMetric, nc::NameConfig, path::String)= load(metric, nc, [path])
load(metric::AbstractMetric, path::String) = load(metric, "", path)


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

struct InteractionDistanceErrors <: AbstractMetric
    distances::Vector{Int}
end
InteractionDistanceErrors(r::UnitRange{Int}) = InteractionDistanceErrors(collect(r))

function load(
        iders::InteractionDistanceErrors,
        nc::NameConfig,
        path::String
    )
    classname, xname, trial = subdir_naming_scheme(nc, path)
    datapoints = Dict{Int, TimeSeriesData}(
        d => TimeSeriesData("InteractionDistanceError",[], xname, "EstimateError", "distance=$d", parse(Int, trial)) for d in iders.distances)

    jldopen(path, "r") do file
        for gen in keys(file["gen"])
            for distance in iders.distances
                if !haskey(file["gen/$gen/tree_stats/dist_int_errors"], string(distance))
                    continue
                end
                stats = file["gen/$gen/tree_stats/dist_int_errors/$distance"] 
                datapoint = TimeSeriesDataPoint(
                    parse(Int, gen),
                    stats["mean"],
                    stats["lower_confidence"],
                    stats["upper_confidence"],
                )
                push!(datapoints[distance].data, datapoint)
            end
        end
    end
    datapoints = collect(values(datapoints))
    datapoints = filter(x -> length(x.data) > 0, datapoints)
    # sort datapoints by x
    for iderr in datapoints
        sort!(iderr.data, by=x->x.x)
    end
    return datapoints
end
