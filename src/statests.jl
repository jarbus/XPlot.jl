
function find_nearest_x(ts::AbstractTimeSeries, x::Real)
    idx = findmin(abs.(x .- [d.x for d in ts.data]))[2]
    ts.data[idx].x
end

function get_nearest_value_around_x(ts::AbstractTimeSeries, x::Real)
    # We need this function to compare distributions at the same time point
    # when the x values are not exactly the same
    nearest_x = find_nearest_x(ts, x)
    for d in ts.data
        if d.x == nearest_x
           return d.value
        end
    end
    error("Could not find nearest value around x=$(x) in $(ts)")
end
get_nearest_value_around_x(ts::Vector{<:AbstractTimeSeries}, x::Real) = [get_nearest_value_around_x(t, x) for t in ts]


function kruskal_wallis(vvts::Vector{<:Vector{<:AbstractTimeSeries}}, x::Real)
    """Arguments:
    vvts: vector of vectors of time series data, where each element of the outer vector
    is a datapoint from the same time series, but from different trials
    x: the time point at which to perform the test
    correction: the correction to use for multiple comparisons
    """
    # create a vector of vectors of values around time x
    vs = [get_nearest_value_around_x(vts, x) for vts in vvts]
    # assert all lengths are the same and greater than 1
    @assert length(unique(length.(vs))) == 1 "All vectors must be of the same length, got vectors of length $(length.(vs))"
    @assert length(vs[1]) > 1
    KruskalWallisTest(vs...) |> pvalue
end

function run_all_pairwise_wilcoxon(vvts::Vector{<:Vector{<:AbstractTimeSeries}}, x::Real; correction=:bonferroni, α=0.05)
    """Arguments:
    vvts: vector of vectors of time series data, where each element of the outer vector
    is a datapoint from the same time series, but from different trials
    x: the time point at which to perform the test
    correction: the correction to use for multiple comparisons
    """
    num_comparisons = length(vvts) * (length(vvts) - 1) / 2
    corrected_α = correction == :bonferroni ? α / num_comparisons : α
    for i in 1:length(vvts)
        for j in i+1:length(vvts)
            p = wilcoxon(vvts[i], vvts[j], x)
            if p < corrected_α
                println("$(vvts[i][1].label) vs $(vvts[j][1].label) at x=$(x) is significant (p=$(p)) < $corrected_α")
            else
                println("$(vvts[i][1].label) vs $(vvts[j][1].label) at x=$(x) is not significant (p=$(p)) < $corrected_α")
            end
        end
    end
end

function wilcoxon(ts1::Vector{<:AbstractTimeSeries},
                  ts2::Vector{<:AbstractTimeSeries},
                  x::Real)
    values1 = get_nearest_value_around_x(ts1, x)
    values2 = get_nearest_value_around_x(ts2, x)
    # print values
    println("$(ts1[1].label) values: $(values1)")
    println("$(ts2[1].label) values: $(values2)")
    # print means and medians
    println("$(ts1[1].label) mean: $(mean(values1))")
    println("$(ts2[1].label) mean: $(mean(values2))")
    println("$(ts1[1].label) median: $(median(values1))")
    println("$(ts2[1].label) median: $(median(values2))")
    # print stds
    println("$(ts1[1].label) std: $(std(values1))")
    println("$(ts2[1].label) std: $(std(values2))")
    # perform wilcoxon test (aka mann-whitney u test)
    pvalue(MannWhitneyUTest(values1, values2))
end

function compute_all_glass_deltas(control::Vector{<:AbstractTimeSeries},
                                  groups::Vector{<:Vector{<:AbstractTimeSeries}},
                                  x::Real; correction=:bonferroni, α=0.05)
    for i in 1:length(groups)
        glass_delta(control, groups[i], x=x)
    end
end

function compute_all_glass_deltas(groups::Vector{<:Vector{<:AbstractTimeSeries}},
                                  x::Real; correction=:bonferroni, α=0.05)
    for i in 1:length(groups)
        for j in 1:length(groups)
            i == j && continue
            glass_delta(groups[i], groups[j], x=x)
        end
    end
end

function glass_delta(control::Vector{<:AbstractTimeSeries}, group::Vector{<:AbstractTimeSeries}; x=1)
    control_values = get_nearest_value_around_x(control, x)
    group_values = get_nearest_value_around_x(group, x)
    d = glass_delta(control_values, group_values)
    println("Glass delta at x=$x when comparing treatment $(group[1].label) to control $(control[1].label): $(d)")
    d
end

function glass_delta(control::Vector{<:Real}, group::Vector{<:Real})
    mean_diff = mean(group) - mean(control)
    sd_control = std(control)
    mean_diff / sd_control
end


