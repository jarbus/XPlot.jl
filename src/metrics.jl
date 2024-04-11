export AbstractMetric
abstract type AbstractMetric end

_load(args...) = error("No load function defined for $(args...)")

function _load(
                metric::AbstractMetric,
                nc::NameConfig,
                path::String
            )
            general_load(metric, nc, path) do file, metric, xname, trial, timeseries
                push!(timeseries, TimeSeriesData(
                    string(metric),
                    _load_datapoints(file, string(metric)[1:end-2]),
                    xname,
                    string(metric),
                    xname,            # We dont label trials so we can aggregate, lines overlap
                    parse(Int, trial) # for NG game so no point in plotting separately
                ))
            end
        end

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

isstatistical(f, path) = haskey(f, joinpath(path, "mean"))

function load_datapoint(file, path, gen::Int)
    isstatistical(file, path) ?
        TimeSeriesDataPoint(
                            gen,
            file[joinpath(path, "mean")],
        ) :
        TimeSeriesDataPoint(
                            gen,
            file[path],
        )
end

function _load_datapoints(file, path)
    dp = TimeSeriesDataPoint[]
    for step in keys(file[HEAD])
        println("Loading step $step")

        full_path = joinpath(HEAD, step, path)
        if !haskey(file, full_path)
            #error("No key $full_path in file")
            println("No key $full_path in file")
            continue
        end
        datapoint = load_datapoint(file, full_path, parse(Int, step))
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

    pidpath = path*".pid"
    monitor = FileWatching.Pidfile.mkpidlock(pidpath, wait=true)
    jldopen(path, "r") do file
        f(file, metric, xname, trial, timeseries)
    end
    close(monitor)
    timeseries = filter(x -> length(x.data) > 0, timeseries)
    return timeseries
end


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

