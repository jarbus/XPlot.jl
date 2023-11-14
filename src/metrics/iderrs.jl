export InteractionDistanceErrors

struct InteractionDistanceErrors <: AbstractMetric
    distances::Vector{Int}
end
InteractionDistanceErrors(r::UnitRange{Int}) = InteractionDistanceErrors(collect(r))

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
