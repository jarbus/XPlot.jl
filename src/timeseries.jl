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

struct TimeSeriesData <: AbstractTimeSeries
    name::String
    data::Vector{AbstractTimeSeriesDataPoint}
end

struct AggregatedTimeSeriesData <: AbstractTimeSeries
    name::String
    data::Vector{AggregatedTimeSeriesDataPoint}
end

struct TimeSeriesPlot
    name::String
    data::Vector{AbstractTimeSeries}
end
TimeSeriesPlot(data::Vector{<:AbstractTimeSeries}) = TimeSeriesPlot("",data)


Base.show(io::IO, datapoint::AbstractTimeSeriesDataPoint) = print(io, "($(round(datapoint.x, digits=2)), $(round(datapoint.value, digits=2)))")

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
    name::String,
    data::Vector{TimeSeriesData}
)
    # assert all time series data have the same name
    @assert length(unique([d.name for d in data])) == 1
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
    agg_data = AggregatedTimeSeriesData(name, datapoints)
    agg_data
end

function agg(timeseriesdata::Vector{TimeSeriesData})
    agg_data = Dict{String, Vector{TimeSeriesData}}(tsd.name => [] for tsd in timeseriesdata)
    for tsd in timeseriesdata
        push!(agg_data[tsd.name], tsd)
    end
    return [AggregatedTimeSeriesData(name, data) for (name, data) in agg_data]
end


function plot(p::AbstractTimeSeries)
    xs = [d.x for d in p.data]
    ys = [d.value for d in p.data]
    upper = [d.upper_bound - d.value for d in p.data]
    lower = [d.value - d.lower_bound for d in p.data]
    plot!(xs, ys, ribbon=(upper, lower), label=p.name)
end

function plot(p::TimeSeriesPlot)
    Plots.plot(title=p.name)
    for series in p.data
        plot(series)
    end
end

