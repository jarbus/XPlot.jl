export Measurement, StatisticalMeasurement
# Measurements are created when writing, datapoints are read when 
abstract type AbstractMeasurement end
abstract type AbstractMetric end
struct Measurement <: AbstractMeasurement
    metric::Type{<:AbstractMetric}
    value::Any
    iteration::Int
end
struct StatisticalMeasurement <: AbstractMeasurement
    metric::Type{<:AbstractMetric}
    min::Float64
    mean::Float64
    lower_bound::Float64
    upper_bound::Float64
    std::Float64
    max::Float64
    n_samples::Int
    iteration::Int
end

function StatisticalMeasurement(type::Type{<:AbstractMetric}, data::Vector{<:Real}, iteration::Int)
    _min, _max = extrema(data)
    _mean = mean(data)
    upper_bound, lower_bound = nothing, nothing
    try
        test = bootstrap(mean, data, BasicSampling(1000))
        ci = confint(test, PercentileConfInt(0.95))[1]
        _mean, lower_bound, upper_bound = ci
    catch
        println("Warning: could not compute confidence interval for $(data)")
        upper_bound, lower_bound = _mean, _mean
    end
    StatisticalMeasurement(type, _min,  _mean, lower_bound, upper_bound, std(data), _max, length(data), iteration)
end

Base.show(io::IO, m::Measurement; digits::Int=3) = print(io, "iter=$(m.iteration) $(m.metric)=$(round(m.value, digits=digits))")
Base.show(io::IO, m::StatisticalMeasurement; digits::Int=3) = print(io, 
    "gen=$(m.iteration) $(m.metric): |$(round(m.min, digits=digits)), $(round(m.mean, digits=digits)) ± $(round(m.std, digits=digits)), $(round(m.max, digits=digits))|, $(m.n_samples) samples")

write(f, m::Measurement) = f[joinpath(HEAD,"$(m.iteration)/$(m.metric)")] = m.value
function write(f, m::StatisticalMeasurement)
    head = joinpath(HEAD, "$(m.iteration)/$(m.metric)")
    f[joinpath(head, "min")] = m.min
    f[joinpath(head, "mean")] = m.mean
    f[joinpath(head, "lower_bound")] = m.lower_bound
    f[joinpath(head, "upper_bound")] = m.upper_bound
    f[joinpath(head, "std")] = m.std
    f[joinpath(head, "max")] = m.max
    f[joinpath(head, "n_samples")] = m.n_samples
end
