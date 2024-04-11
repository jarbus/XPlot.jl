export BestSortPercentage, InteractionDistanceErrors, SortFits, BestSortSize, AllPassPercentage, PerfectPercentage

struct SortFits <: AbstractMetric end
struct BestSortPercentage <: AbstractMetric end
struct BestSortSize <: AbstractMetric end
struct AllPassPercentage <: AbstractMetric end
struct PerfectPercentage <: AbstractMetric end


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
    general_load(met, nc, path) do file, sf, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "BestSortPercentage",
                 _load_datapoints(file, "sorted/best_percent"),
                 xname,
                 "Percentage",
                 xname,
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
    general_load(met, nc, path) do file, met, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "BestSortSize",
                  _load_datapoints(file, "sorted/best_size"),
                 xname,
                 "Number of swaps",
                 xname,
                 parse(Int, trial)
             )
         )
    end
end

function _load(
        met::AllPassPercentage,
        nc::NameConfig,
        path::String
    )
    general_load(met, nc, path) do file, met, xname, trial, timeseries
        push!(timeseries, TimeSeriesData(
                 "AllPassPercentage",
                  _load_datapoints(file, "sorted/allpass_percent"),
                 xname,
                 "Percentage",
                 xname,
                 parse(Int, trial)
             )
         )
    end
end


function _load(
        met::PerfectPercentage,
        nc::NameConfig,
        path::String
    )
    general_load(met, nc, path) do file, met, xname, trial, timeseries
        datapoints = _load_datapoints(file, "sorted/perfect_percent")
        datapointsx100 = [TimeSeriesDataPoint(dp.x, dp.value*100, dp.lower_bound, dp.upper_bound) for dp in datapoints]
        push!(timeseries, TimeSeriesData(
                 "PerfectPercentage",
                 datapointsx100,
                 xname,
                 "Perfect Percentage",
                 xname,
                 parse(Int, trial)
             )
         )
    end
end
