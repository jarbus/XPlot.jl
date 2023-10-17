# Code to infer the names of experiment data from the file names
# 
# We follow the convention that the file names are of the form:
# shared-path/class-name/experiment-name-{1,2,3,...}/path/archive.jld2

Base.@kwdef struct NameConfig
    seed_suffix = "-"
    relative_datapath = "data/archive.jld2"
end

function compute_prefix(paths::Vector{String})
    # Compute the shared path of a set of paths
    # We assume that the paths are all absolute paths
    # compute the longest common prefix
    prefix_end = 0
    for i in 1:length(paths[1])
        c = paths[1][i]
        for path in paths
            if i > length(path) || path[i] != c
                return dirname(paths[1][1:prefix_end])
            end
        end
        prefix_end += 1
    end
    prefix = dirname(paths[1][1:prefix_end])
    prefix
end

function remove_trailing_numbers(s::String)
    """Returns a string with all trailing numbers removed"""
    length(s) == 0 && return ""
    last_place = length(s)
    while last_place > 0 && '1' <= s[last_place]  <= '9'
        last_place -= 1
    end
    s[1:last_place]
end

function remove_seed(nc::NameConfig, s::String)
    s = remove_trailing_numbers(s)
    if endswith(s, nc.seed_suffix)
        return s[1:end-length(nc.seed_suffix)]
    end
    s
end


function remove_suffix(s::String, suffix::String)
    if endswith(s, suffix)
        return s[1:end-length(suffix)]
    end
    s
end

function remove_relative_datapath(nc::NameConfig, s::String)
    remove_suffix(s, nc.relative_datapath)
end

function remove_prefix(prefix::String, s::String)
    if startswith(s, prefix)
        return s[length(prefix)+1:end]
    end
    s
end

function compute_name(nc::NameConfig, prefix::String, s::String)
    s = remove_relative_datapath(nc, s)
    s = remove_prefix(prefix, s)
    s = remove_suffix(s, "/")
    s
end
