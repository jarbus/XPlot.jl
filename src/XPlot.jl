module XPlot

using JLD2
abstract type AbstractTimeSeriesDataPoint end
abstract type AbstractTimeSeries end

struct TimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
    upper_bound::Union{Float64, Nothing}
    lower_bound::Union{Float64, Nothing}
end

struct AggregatedTimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
    upper_bound::Union{Float64, Nothing}
    lower_bound::Union{Float64, Nothing}
    count::Int64
end

struct TimeSeriesData <: AbstractTimeSeries
    name::String
    data::Vector{TimeSeriesDataPoint}
end

struct TimeSeriesPlot
    name::String
    data::Vector{TimeSeriesData}
end

struct InteractionDistanceError <: AbstractTimeSeries
    distance::Int
    data::Vector{TimeSeriesDataPoint}
end

function InteractionDistanceErrors(
        distances::Vector{Int},
        path::String
    )
    datapoints = Dict{Int, InteractionDistanceError}(
            d => InteractionDistanceError(d,[]) for d in distances)

    jldopen(path, "r") do file
        for gen in keys(file["gen"])
            for distance in distances
                stats = file["gen/$gen/tree_stats/dist_int_errors/$distance/"] 
                datapoint = TimeSeriesDataPoint(
                    parse(Int, gen),
                    stats["mean"],
                    stats["upper_confidence"],
                    stats["lower_confidence"]
                )
                push!(datapoints[distance].data, datapoint)
            end
        end
    end
end






end
