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


Base.show(io::IO, datapoint::AbstractTimeSeriesDataPoint) = print(io, "($(round(datapoint.x, digits=2)), $(round(datapoint.value, digits=2)))")
Base.show(io::IO, ts::AbstractTimeSeries) = print(io, "TimeSeriesData($(ts.name), $(ts.xname), $(ts.yaxis), $(ts.label), $(ts.trial))")

function AggregatedTimeSeriesDataPoint(datapoints::Vector{TimeSeriesDataPoint})
    # check that all xs are the same
    @assert length(unique([d.x for d in datapoints])) == 1
    x = datapoints[1].x

    vs = [d.value for d in datapoints]
    value = mean(vs)
    upper_bound, lower_bound = nothing, nothing
    try
        test = OneSampleTTest(vs)
        upper_bound, lower_bound = confint(test)
    catch
        println("Warning: could not compute confidence interval for $(datapoints)")
        upper_bound, lower_bound = value, value
    end
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
    # filter out all agg_data that are not of length data
    datapoints = [AggregatedTimeSeriesDataPoint(agg_data[x]) for x in xs if length(agg_data[x]) == length(data)]
    agg_data = AggregatedTimeSeriesData(name, datapoints, xname, yaxis, label)
    agg_data
end

function agg(timeseriesdata::Vector{T}) where T <: AbstractTimeSeries
    agg_data = Dict{String, Vector{T}}((tsd.xname * tsd.label) => T[] for tsd in timeseriesdata)
    for tsd in timeseriesdata
        push!(agg_data[(tsd.xname * tsd.label)], tsd)
    end
    agg_tsds = [AggregatedTimeSeriesData(data) for data in values(agg_data)]
    sort!(agg_tsds, by=tsd -> tsd.label)
    agg_tsds
end


rolling(timeseries::Vector{<:AbstractTimeSeries}; window_size=10) = [rolling(ts, window_size=window_size) for ts in timeseries]

function rolling(timeseries::AggregatedTimeSeriesData; window_size=10)
    data = timeseries.data
    new_data = []
    for i in window_size:length(data)

        datapoints = data[i-window_size+1:i]
        x = datapoints[end].x
        value = mean([d.value for d in datapoints])
        count = sum([d.count for d in datapoints])
        push!(new_data, AggregatedTimeSeriesDataPoint(x, value, 0, 0, count))
    end
    return AggregatedTimeSeriesData(timeseries.name, new_data, timeseries.xname, timeseries.yaxis, timeseries.label)

end

function rolling(timeseries::TimeSeriesData; window_size=10) 
    data = timeseries.data
    new_data = []
    for i in window_size:length(data)
        datapoints = data[i-window_size+1:i]
        x = datapoints[end].x
        value = mean([d.value for d in datapoints])
        push!(new_data, TimeSeriesDataPoint(x, value, nothing, nothing))
    end
    return TimeSeriesData(timeseries.name, new_data, timeseries.xname, timeseries.yaxis, timeseries.label, timeseries.trial)
end



function Plots.plot!(p::AbstractTimeSeries; kwargs...)
    xs = [d.x for d in p.data]
    ys = [d.value for d in p.data]
    upper = [d.upper_bound isa Float64 ? d.upper_bound - d.value : 0 for d in p.data]
    lower = [d.upper_bound isa Float64 ? d.value - d.lower_bound : 0 for d in p.data]
    plot!(xs, ys, ribbon=(upper, lower), label=p.label; kwargs...)
end
function Plots.plot(timeseries::AbstractTimeSeries; kwargs...)
    p = plot(;kwargs...)
    p = plot!(timeseries; kwargs...)
    p
end
function Plots.plot(timeseriess::Vector{<:AbstractTimeSeries}; kwargs...)
    p = plot(;kwargs...)
    for timeseries in timeseriess
        p = plot!(timeseries; kwargs...)
    end
    p
end

function Plots.plot!(timeseriess::Vector{<:AbstractTimeSeries}; kwargs...)
    for timeseries in timeseriess
        p = plot(timeseries; kwargs...)
    end
    p
end
