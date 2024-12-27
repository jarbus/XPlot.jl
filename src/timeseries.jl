abstract type AbstractTimeSeriesDataPoint end
abstract type AbstractStatisticalTimeSeriesDataPoint <: AbstractTimeSeriesDataPoint end
abstract type AbstractTimeSeries end

struct TimeSeriesDataPoint <: AbstractTimeSeriesDataPoint
    x::Float64
    value::Float64
end

struct StatisticalTimeSeriesDataPoint <: AbstractStatisticalTimeSeriesDataPoint
    x::Float64
    min::Float64
    mean::Float64
    lower_bound::Float64
    upper_bound::Float64
    std::Float64
    max::Float64
    n_samples::Int64
end

struct AggregatedTimeSeriesDataPoint <: AbstractStatisticalTimeSeriesDataPoint
    x::Float64
    min::Float64
    mean::Float64
    lower_bound::Float64
    upper_bound::Float64
    std::Float64
    max::Float64
    n_samples::Int64
end

Base.@kwdef struct TimeSeriesData{P<:AbstractTimeSeriesDataPoint} <: AbstractTimeSeries
    name::String
    data::Vector{P}
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

Base.isnan(d::AbstractTimeSeriesDataPoint) = isnan(mean(d))
Base.show(io::IO, datapoint::AbstractTimeSeriesDataPoint) = print(io, "($(round(datapoint.x, digits=2)), $(round(datapoint.value, digits=2)))")
Base.show(io::IO, ts::AbstractTimeSeries) = print(io, "$(typeof(ts))($(ts.name),length=$(length(ts.data)) $(ts.xname), $(ts.yaxis), $(ts.label), $(ts.trial))")

StatsBase.mean(p::StatisticalTimeSeriesDataPoint) = p.mean
StatsBase.mean(p::TimeSeriesDataPoint) = p.value

function AggregatedTimeSeriesDataPoint(datapoints::Vector{TimeSeriesDataPoint})
    # check that all xs are the same
    @assert length(unique([d.x for d in datapoints])) == 1
    x = datapoints[1].x

    vs = [d.value for d in datapoints]
    _mean = mean(vs)
    upper_bound, lower_bound = nothing, nothing
    try
        test = bootstrap(mean, vs, BasicSampling(1000))
        ci = confint(test, PercentileConfInt(0.95))[1]
        _mean, lower_bound, upper_bound = ci
    catch
        println("Warning: could not compute confidence interval for $(datapoints)")
        upper_bound, lower_bound = _mean, _mean
    end
    count = length(datapoints)
    _min, _max = extrema(vs)
    _std = std(vs)
    return AggregatedTimeSeriesDataPoint(x, _min, _mean, lower_bound, upper_bound, _std, _max, count)
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
            if datapoint isa TimeSeriesDataPoint
                push!(agg_data[datapoint.x], datapoint)
            elseif datapoint isa StatisticalTimeSeriesDataPoint
                push!(agg_data[datapoint.x], TimeSeriesDataPoint(datapoint.x, datapoint.max))
            end
        end
    end
    # aggregate data over time points
    xs = sort!(collect(keys(agg_data)))
    # filter out all agg_data that are not of length data, i.e. all time points that are not present in all time series
    datapoints = [AggregatedTimeSeriesDataPoint(agg_data[x]) for x in xs if length(agg_data[x]) == length(data)]
    agg_data = AggregatedTimeSeriesData(name, datapoints, xname, yaxis, label)
    agg_data
end

function group(timeseriesdata::Vector{T}) where T <: AbstractTimeSeries
    group_data = Dict{String, Vector{T}}((tsd.xname * tsd.label) => T[] for tsd in timeseriesdata)
    for tsd in timeseriesdata
        push!(group_data[(tsd.xname * tsd.label)], tsd)
    end
    group_tsds = values(group_data) |> collect
    sort!(group_tsds, by=gtsd -> gtsd[1].label)
    group_tsds
end

function agg(timeseriesdata::Vector{T}) where T <: AbstractTimeSeries
    groups = group(timeseriesdata)
    agg_tsds = [AggregatedTimeSeriesData(g) for g in groups]
    sort!(agg_tsds, by=tsd -> tsd.label)
    agg_tsds
end

# rolling(timeseries::Vector{<:AbstractTimeSeries}; window_size=10) = [rolling(ts, window_size=window_size) for ts in timeseries]
#
# function rolling(timeseries::AggregatedTimeSeriesData; window_size=10)
#     data = timeseries.data
#     new_data = []
#     for i in window_size:length(data)
#
#         datapoints = data[i-window_size+1:i]
#         x = datapoints[end].x
#         vs = [d._mean for d in datapoints]
#         _mean = mean(vs)
#         _min, _max = extrema(vs)
#         count = sum([d.n_samples for d in datapoints])
#         _std = std(vs)
#         push!(new_data, AggregatedTimeSeriesDataPoint(x, _min, _mean, 0, 0, _std, _max, count))
#     end
#     return AggregatedTimeSeriesData(timeseries.name, new_data, timeseries.xname, timeseries.yaxis, timeseries.label)
#
# end
#
# function rolling(timeseries::TimeSeriesData; window_size=10) 
#     data = timeseries.data
#     new_data = []
#     for i in window_size:length(data)
#         datapoints = data[i-window_size+1:i]
#         x = datapoints[end].x
#         _mean = mean([mean(d) for d in datapoints])
#         push!(new_data, TimeSeriesDataPoint(x, _mean))
#     end
#     return TimeSeriesData(timeseries.name, new_data, timeseries.xname, timeseries.yaxis, timeseries.label, timeseries.trial)
# end

function Plots.plot!(p::TimeSeriesData{TimeSeriesDataPoint}; kwargs...)
    xs = [d.x for d in p.data]
    ys = [d.value for d in p.data]
    plot!(xs, ys, label=p.label; kwargs...)
end

function Plots.plot!(p::Union{AggregatedTimeSeriesData,
                              TimeSeriesData{StatisticalTimeSeriesDataPoint}};
                              kwargs...)
    xs = [d.x for d in p.data]
    ys = [d.mean for d in p.data]
    upper = [d.upper_bound isa Float64 ? d.upper_bound - d.mean : 0 for d in p.data]
    lower = [d.upper_bound isa Float64 ? d.mean - d.lower_bound : 0 for d in p.data]
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
        plot!(timeseries; kwargs...)
    end
end

function Plots.plot!(els::Vector, kwargs...)
    # Function to recursively plot elements, 
    # so we can plot vecs of vecs of time series
    for el in els
        plot!(el; kwargs...)
    end
end
