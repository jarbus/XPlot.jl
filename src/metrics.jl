abstract type AbstractMetric end

function load(
        metric::AbstractMetric,
        nc::NameConfig,
        paths::Vector{String}
    )
    paths = find_datapath_recursively(nc, paths)
    @assert length(paths) > 0 "No paths found"

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

function _load_datapoints(file,path;statistical=false, head="gen")
    dp = TimeSeriesDataPoint[]
    for step in keys(file[head])

        full_path = joinpath(head, step, path)
        if !haskey(file, full_path)
            #error("No key $full_path in file")
            continue
        end
        if statistical
            stats = file[full_path]
            datapoint = TimeSeriesDataPoint(
                parse(Int, step),
                stats["mean"],
                stats["lower_confidence"],
                stats["upper_confidence"],
            )
        else
            datapoint = TimeSeriesDataPoint(parse(Int, step),
                    file[full_path],
                    nothing, nothing)
        end
        isnan(datapoint.value) && continue
        push!(dp, datapoint)
    end
    length(dp) == 0 && @warn("No datapoints found in $path")
    sort!(dp, by=x->x.x)
    dp
end

function general_load(
        f,
        metric::AbstractMetric,
        nc::NameConfig,
        path::String
    )
    classname, xname, trial = subdir_naming_scheme(nc, path)
    println("Loading cls=$classname x=$xname trial=$trial")
    timeseries = TimeSeriesData[]

    jldopen(path, "r") do file
        f(file, metric, xname, trial, timeseries)
    end
    timeseries = filter(x -> length(x.data) > 0, timeseries)
    return timeseries
end
