export EstimatorDistanceStatistics, EstimatorErrorStatistics, DistanceErrorCorrelation

struct EstimatorDistanceStatistics <: AbstractMetric end
struct EstimatorErrorStatistics <: AbstractMetric end
struct DistanceErrorCorrelation <: AbstractMetric end

function get_species_matchups(file)
    # get the largest number string
    max_gen = keys(file["gen"]) |> collect |> x->sort(x, by=y->parse(Int, y)) |> last
    # get all species in the last generation
    species = keys(file["gen/$max_gen/phylogeneticestimatorstats"]) |> collect
    species
end

function _load(dists::EstimatorDistanceStatistics,
        nc::NameConfig,
        path::String)
    general_load(dists, nc, path) do file, iders, xname, trial, timeseries
        # get all keys
        estimators = get_species_matchups(file)
        for estimator in estimators
            push!(timeseries, TimeSeriesData(
                "DistanceStatistics",
                 _load_datapoints(file, "phylogeneticestimatorstats/$estimator/dist_stats"; statistical=true),
                xname,
                "Distances",
                xname,
                parse(Int, trial)
            ))
        end
    end
end

function _load(errs::EstimatorErrorStatistics,
        nc::NameConfig,
        path::String)
    general_load(errs, nc, path) do file, errs, xname, trial, timeseries
        # get all keys
        estimators = get_species_matchups(file)
        for estimator in estimators
            push!(timeseries, TimeSeriesData(
                "ErrorStatistics",
                 _load_datapoints(file, "phylogeneticestimatorstats/$estimator/error_stats"; statistical=true),
                xname,
                "Distances",
                xname,
                parse(Int, trial)
            ))
        end
    end
end

function _load(decorr::DistanceErrorCorrelation,
        nc::NameConfig,
        path::String)
    general_load(decorr, nc, path) do file, decorr, xname, trial, timeseries
        # get all keys
        estimators = get_species_matchups(file)
        for estimator in estimators
            push!(timeseries, TimeSeriesData(
                "DistanceErrorCorrelation",
                 _load_datapoints(file, "phylogeneticestimatorstats/$estimator/decorr";),
                xname,
                "DistanceErrorCorrelation",
                xname,
                parse(Int, trial)
            ))
        end
    end
end
