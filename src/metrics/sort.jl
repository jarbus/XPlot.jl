export BestSortPercentage, InteractionDistanceErrors, SortFits, BestSortSize

struct SortFits <: AbstractMetric end
struct BestSortPercentage <: AbstractMetric end
struct BestSortSize <: AbstractMetric end


function _load(
        met::SortFits,
        nc::NameConfig,
        path::String
    )
    general_load(met, nc, path) do file, met, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "SortingNetworkFitness",
                  _load_datapoints(file, "sorted/sn_fitnesses"; statistical=true),
                 xname,
                 "Fitness",
                 "SortingNetwork",
                 parse(Int, trial)
             )
         )

        push!(timeseries, TimeSeriesData(
                 "SortingNetworkTestCaseFitness",
                  _load_datapoints(file, "sorted/tc_fitnesses"; statistical=true),
                 xname,
                 "Fitness",
                 "TestCase",
                 parse(Int, trial)
             )
        )
    end
end



function _load(
        met::BestSortPercentage,
        nc::NameConfig,
        path::String
    )
    general_load(BestSortPercentage(), nc, path) do file, sf, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "BestSortPercentage",
                  _load_datapoints(file, "sorted/best_sorter_percent"),
                 xname,
                 "Percentage",
                 "",
                 parse(Int, trial)
             )
         )
    end
end

function _load(
        met::BestSortSize,
        nc::NameConfig,
        path::String
    )
    general_load(BestSortSize(), nc, path) do file, met, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "BestSortSize",
                  _load_datapoints(file, "sorted/best_sorter_size"),
                 xname,
                 "Number of swaps",
                 "",
                 parse(Int, trial)
             )
         )
    end
end
