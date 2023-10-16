struct InteractionDistanceError <: AbstractTimeSeries
    name::String
    distance::Int
    data::Vector{TimeSeriesDataPoint}
end

function InteractionDistanceErrors(
        distances::Vector{Int},
        path::String
    )
    datapoints = Dict{Int, InteractionDistanceError}(
        d => InteractionDistanceError(string(d), d,[]) for d in distances)

    jldopen(path, "r") do file
        for gen in keys(file["gen"])
            for distance in distances
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
    datapoints = filter(x -> length(x[2].data) > 0, datapoints)
    # sort datapoints by x
    for (distance, iderr) in datapoints
        sort!(iderr.data, by=x->x.x)
    end
    return datapoints
end
