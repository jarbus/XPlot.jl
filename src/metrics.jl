abstract type AbstractMetric end

function load(
        metric::AbstractMetric,
        paths::Vector{String}
    )
    vcat([load(metric, path) for path in paths])
end

struct InteractionDistanceErrors <: AbstractMetric
    distances::Vector{Int}
end
InteractionDistanceErrors(r::UnitRange{Int}) = InteractionDistanceErrors(collect(r))


struct InteractionDistanceError <: AbstractTimeSeries
    name::String
    distance::Int
    data::Vector{TimeSeriesDataPoint}
end

function load(
        iders::InteractionDistanceErrors,
        path::String
    )
    datapoints = Dict{Int, InteractionDistanceError}(
        d => InteractionDistanceError(string(d), d,[]) for d in iders.distances)

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
