export @metric

macro metric(name)
    quote
    
        struct $name <: AbstractMetric end

        function XPlot._load(
                metric::$name,
                nc::NameConfig,
                path::String
            )
            general_load(gs, nc, path) do file, gs, xname, trial, timeseries
                push!(timeseries, TimeSeriesData(
                    "$name",
                     _load_datapoints(file, "$name"; statistical=true,head="measurements"),
                    xname,
                    "$name",
                    xname,            # We dont label trials so we can aggregate, lines overlap
                    parse(Int, trial) # for NG game so no point in plotting separately
                ))
            end
        end
    end
end
