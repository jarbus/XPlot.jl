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
        test = bootstrap(mean, vs, BasicSampling(1000))
        ci = confint(test, PercentileConfInt(0.95))[1]
        value, lower_bound, upper_bound = ci
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

function find_nearest_x(ts::AbstractTimeSeries, x::Real)
    idx = findmin(abs.(x .- [d.x for d in ts.data]))[2]
    ts.data[idx].x
end

function get_nearest_value_around_x(ts::AbstractTimeSeries, x::Real)
    # We need this function to compare distributions at the same time point
    # when the x values are not exactly the same
    nearest_x = find_nearest_x(ts, x)
    for d in ts.data
        if d.x == nearest_x
           return d.value
        end
    end
    error("Could not find nearest value around x=$(x) in $(ts)")
end
get_nearest_value_around_x(ts::Vector{<:AbstractTimeSeries}, x::Real) = [get_nearest_value_around_x(t, x) for t in ts]


function kruskal_wallis(vvts::Vector{<:Vector{<:AbstractTimeSeries}}, x::Real)
    """Arguments:
    vvts: vector of vectors of time series data, where each element of the outer vector
    is a datapoint from the same time series, but from different trials
    x: the time point at which to perform the test
    correction: the correction to use for multiple comparisons
    """
    # create a vector of vectors of values around time x
    vs = [get_nearest_value_around_x(vts, x) for vts in vvts]
    # assert all lengths are the same and greater than 1
    @assert length(unique(length.(vs))) == 1 "All vectors must be of the same length, got vectors of length $(length.(vs))"
    @assert length(vs[1]) > 1
    KruskalWallisTest(vs...) |> pvalue
end

function run_all_pairwise_wilcoxon(vvts::Vector{<:Vector{<:AbstractTimeSeries}}, x::Real; correction=:bonferroni, α=0.05)
    """Arguments:
    vvts: vector of vectors of time series data, where each element of the outer vector
    is a datapoint from the same time series, but from different trials
    x: the time point at which to perform the test
    correction: the correction to use for multiple comparisons
    """
    num_comparisons = length(vvts) * (length(vvts) - 1) / 2
    corrected_α = correction == :bonferroni ? α / num_comparisons : α
    for i in 1:length(vvts)
        for j in i+1:length(vvts)
            p = wilcoxon(vvts[i], vvts[j], x)
            if p < corrected_α
                println("$(vvts[i][1].label) vs $(vvts[j][1].label) at x=$(x) is significant (p=$(p)) < $corrected_α")
            else
                println("$(vvts[i][1].label) vs $(vvts[j][1].label) at x=$(x) is not significant (p=$(p)) < $corrected_α")
            end
        end
    end
end

function wilcoxon(ts1::Vector{<:AbstractTimeSeries},
                  ts2::Vector{<:AbstractTimeSeries},
                  x::Real)
    values1 = get_nearest_value_around_x(ts1, x)
    values2 = get_nearest_value_around_x(ts2, x)
    # print values
    println("$(ts1[1].label) values: $(values1)")
    println("$(ts2[1].label) values: $(values2)")
    # print means and medians
    println("$(ts1[1].label) mean: $(mean(values1))")
    println("$(ts2[1].label) mean: $(mean(values2))")
    println("$(ts1[1].label) median: $(median(values1))")
    println("$(ts2[1].label) median: $(median(values2))")
    # print stds
    println("$(ts1[1].label) std: $(std(values1))")
    println("$(ts2[1].label) std: $(std(values2))")
    # perform wilcoxon test (aka mann-whitney u test)
    pvalue(MannWhitneyUTest(values1, values2))
end

function compute_all_glass_deltas(control::Vector{<:AbstractTimeSeries},
                                  groups::Vector{<:Vector{<:AbstractTimeSeries}},
                                  x::Real; correction=:bonferroni, α=0.05)
    for i in 1:length(groups)
        glass_delta(control, groups[i], x=x)
    end
end

function compute_all_glass_deltas(groups::Vector{<:Vector{<:AbstractTimeSeries}},
                                  x::Real; correction=:bonferroni, α=0.05)
    for i in 1:length(groups)
        for j in 1:length(groups)
            i == j && continue
            glass_delta(groups[i], groups[j], x=x)
        end
    end
end

function glass_delta(control::Vector{<:AbstractTimeSeries}, group::Vector{<:AbstractTimeSeries}; x=1)
    control_values = get_nearest_value_around_x(control, x)
    group_values = get_nearest_value_around_x(group, x)
    d = glass_delta(control_values, group_values)
    println("Glass delta at x=$x when comparing treatment $(group[1].label) to control $(control[1].label): $(d)")
    d
end

function glass_delta(control::Vector{<:Real}, group::Vector{<:Real})
    mean_diff = mean(group) - mean(control)
    sd_control = std(control)
    mean_diff / sd_control
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
