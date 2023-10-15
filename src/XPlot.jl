module XPlot
using JLD2
using Plots
abstract type AbstractTimeSeriesDataPoint end
abstract type AbstractTimeSeries end

struct TimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
    upper_bound::Union{Float64, Nothing}
    lower_bound::Union{Float64, Nothing}
end

Base.show(io::IO, datapoint::TimeSeriesDataPoint) = print(io, "($(round(datapoint.x, digits=2)), $(round(datapoint.value, digits=2)))")

struct AggregatedTimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
    upper_bound::Union{Float64, Nothing}
    lower_bound::Union{Float64, Nothing}
    count::Int64
end

struct TimeSeriesData <: AbstractTimeSeries
    name::String
    data::Vector{AbstractTimeSeriesDataPoint}
end

function plot(p::AbstractTimeSeries)
    xs = [d.x for d in p.data]
    ys = [d.value for d in p.data]
    upper = [d.upper_bound - d.value for d in p.data]
    println(upper)
    lower = [d.value - d.lower_bound for d in p.data]
    println(lower)
    plot!(xs, ys, ribbon=(upper, lower), label=p.name)
end

struct TimeSeriesPlot
    name::String
    data::Vector{AbstractTimeSeries}
end

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
                    stats["upper_confidence"],
                    stats["lower_confidence"]
                )
                push!(datapoints[distance].data, datapoint)
            end
        end
    end
    datapoints = filter(x -> length(x[2].data) > 0, datapoints)
    return datapoints
end

function plot(p::TimeSeriesPlot)
    for series in p.data
        plot(series)
    end
end
end
