abstract type AbstractTimeSeriesDataPoint end
abstract type AbstractTimeSeries end

struct TimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
    lower_bound::Union{Float64, Nothing}
    upper_bound::Union{Float64, Nothing}
end

struct AggregatedTimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
    lower_bound::Float64
    upper_bound::Float64
    count::Int64
end

Base.@kwdef struct TimeSeriesData <: AbstractTimeSeries
    name::String
    data::Vector{AbstractTimeSeriesDataPoint}
    xname::String = ""
    yaxis::String = ""
    label::String = ""
    trial::Union{Int64, Nothing} = nothing
end

Base.@kwdef struct AggregatedTimeSeriesData <: AbstractTimeSeries
    name::String
    data::Vector{AggregatedTimeSeriesDataPoint}
    xname::String = ""
    yaxis::String = ""
    label::String = ""
end

struct TimeSeriesPlot
    name::String
    data::Vector{AbstractTimeSeries}
end
TimeSeriesPlot(data::Vector{<:AbstractTimeSeries}) = TimeSeriesPlot("",data)


Base.show(io::IO, datapoint::AbstractTimeSeriesDataPoint) = print(io, "($(round(datapoint.x, digits=2)), $(round(datapoint.value, digits=2)))")
Base.show(io::IO, ts::AbstractTimeSeries) = print(io, "TimeSeriesData($(ts.name), $(ts.xname), $(ts.yaxis), $(ts.label), $(ts.trial))")

function AggregatedTimeSeriesDataPoint(datapoints::Vector{TimeSeriesDataPoint})
    # check that all xs are the same
    @assert length(unique([d.x for d in datapoints])) == 1
    x = datapoints[1].x

    vs = [d.value for d in datapoints]
    value = mean(vs)
    test = OneSampleTTest(vs)
    upper_bound, lower_bound = confint(test)
    count = length(datapoints)
    return AggregatedTimeSeriesDataPoint(x, value, lower_bound, upper_bound, count)
end



function AggregatedTimeSeriesData(
    data::Vector{<:AbstractTimeSeries}
)
    # assert all time series data have the same name
    @assert length(unique([d.name for d in data])) == 1
    @assert length(unique([d.xname for d in data])) == 1
    @assert length(unique([d.yaxis for d in data])) == 1
    @assert length(unique([d.label for d in data])) == 1
    name = data[1].name
    xname = data[1].xname
    yaxis = data[1].yaxis
    label = data[1].label
    agg_data = Dict{Float64, Vector{TimeSeriesDataPoint}}()
    # aggregate data over time series
    for tsd in data
        for datapoint in tsd.data
            if !haskey(agg_data, datapoint.x)
                agg_data[datapoint.x] = []
            end
            push!(agg_data[datapoint.x], datapoint)
        end
    end
    # aggregate data over time points
    xs = sort!(collect(keys(agg_data)))
    datapoints = [AggregatedTimeSeriesDataPoint(agg_data[x]) for x in xs]
    agg_data = AggregatedTimeSeriesData(name, datapoints, xname, yaxis, label)
    agg_data
end

function agg(timeseriesdata::Vector{T}) where T <: AbstractTimeSeries
    agg_data = Dict{String, Vector{T}}((tsd.xname * tsd.label) => T[] for tsd in timeseriesdata)
    for tsd in timeseriesdata
        push!(agg_data[(tsd.xname * tsd.label)], tsd)
    end
    return [AggregatedTimeSeriesData(data) for data in values(agg_data)]
end


function Plots.plot(p::AbstractTimeSeries; kwargs...)
    xs = [d.x for d in p.data]
    ys = [d.value for d in p.data]
    upper = [d.upper_bound - d.value for d in p.data]
    lower = [d.value - d.lower_bound for d in p.data]
    plot!(xs, ys, ribbon=(upper, lower), label=p.label; kwargs...)
end
function Plots.plot(timeseriess::Vector{<:AbstractTimeSeries}; kwargs...)
    p = plot(;kwargs...)
    for timeseries in timeseriess
        p = plot(timeseries; kwargs...)
    end
    p
end

function Plots.plot(p::TimeSeriesPlot; kwargs...)
    Plots.plot(p.data; title=p.name, kwargs...)
end

