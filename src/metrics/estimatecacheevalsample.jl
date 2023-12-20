export Evaluated

struct Evaluated <: AbstractMetric end

function _load(
        evaluated::Evaluated,
        nc::NameConfig,
        path::String
    )
    general_load(evaluated, nc, path) do file, _, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
            "Evaluated",
             _load_datapoints(file, "estimatecacheevalsample/numevaluated"; statistical=false),
            xname,
            "Number of Evaluations",
            xname,
            parse(Int, trial)
        ))
    end
end
