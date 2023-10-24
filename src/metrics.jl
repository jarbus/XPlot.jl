abstract type AbstractMetric end

function load(
        metric::AbstractMetric,
        nc::NameConfig,
        paths::Vector{String}
    )
    paths = find_datapath_recursively(nc, paths)

    vcat([_load(metric, nc, path) for path in paths]...)
end
load(metric::AbstractMetric, nc::NameConfig, path::String)= load(metric, nc, [path])

function subdir_naming_scheme(nc::NameConfig, path::String)
    # We assume that the path is an absolute
    s = remove_relative_datapath(nc, path) |> dirname
    trial = basename(s)
    s = dirname(s)
    xname = basename(s)
    s = dirname(s)
    classname = basename(s)
    classname, xname, trial
end

struct InteractionDistanceErrors <: AbstractMetric
    distances::Vector{Int}
end
InteractionDistanceErrors(r::UnitRange{Int}) = InteractionDistanceErrors(collect(r))

function _load_statistical_datapoints(file,path)
    dp = TimeSeriesDataPoint[]
    for gen in keys(file["gen"])

        full_path = joinpath("gen/$gen", path)
        if !haskey(file, full_path)
            #error("No key $full_path in file")
            continue
        end
        stats = file[full_path]
        datapoint = TimeSeriesDataPoint(
            parse(Int, gen),
            stats["mean"],
            stats["lower_confidence"],
            stats["upper_confidence"],
        )
        push!(dp, datapoint)
    end
    sort!(dp, by=x->x.x)
    dp
end

function _load(
        iders::InteractionDistanceErrors,
        nc::NameConfig,
        path::String
    )
    classname, xname, trial = subdir_naming_scheme(nc, path)
    println("Loading cls=$classname x=$xname trial=$trial")
    datapoints = Dict{Int, TimeSeriesData}()

    jldopen(path, "r") do file
        for distance in iders.distances
            datapoints[distance] = TimeSeriesData(
                "InteractionDistanceError",
                 _load_statistical_datapoints(file, "tree_stats/dist_int_errors/$distance"),
                xname,
                "EstimateError",
                "distance=$distance",
                parse(Int, trial)
            )
        end
    end
    datapoints = collect(values(datapoints))
    datapoints = filter(x -> length(x.data) > 0, datapoints)
    return datapoints
end
