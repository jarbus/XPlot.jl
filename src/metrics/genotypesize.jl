export GenotypeSize

struct GenotypeSize <: AbstractMetric 
    species_ids::Vector{String}
end

function _load(
        gs::GenotypeSize,
        nc::NameConfig,
        path::String
    )
    general_load(gs, nc, path) do file, gs, xname, trial, timeseries
        for sid in gs.species_ids
            push!(timeseries, TimeSeriesData(
                "GenotypeSize",
                 _load_datapoints(file, "GenotypeSize/$sid"; statistical=true,head="measurements"),
                xname,
                "GenotypeSize",
                xname,            # We dont label trials so we can aggregate, lines overlap
                parse(Int, trial) # for NG game so no point in plotting separately
            ))
        end
    end
end
