export GenotypeSum

struct GenotypeSum <: AbstractMetric end

function _load(
        gs::GenotypeSum,
        nc::NameConfig,
        path::String
    )
    general_load(gs, nc, path) do file, gs, xname, trial, timeseries
        species = get_species_matchups(file,"GenotypeSum", head="measurements")
        for sid in species
            push!(timeseries, TimeSeriesData(
                "GenotypeSum",
                 _load_datapoints(file, "GenotypeSum/$sid"; statistical=true,head="measurements"),
                xname,
                "GenotypeSum",
                xname,            # We dont label trials so we can aggregate, lines overlap
                parse(Int, trial) # for NG game so no point in plotting separately
            ))
        end
    end
end
