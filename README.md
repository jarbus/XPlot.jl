# XPlot

An opinionated plotting program for plotting and comparing aggregate timeseries data in the terminal. Used in [Jevo](https://github.com/jarbus/Jevo.jl), inspired by [CoEvo](https://github.com/twillkens/CoEvo).

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jarbus.github.io/XPlot.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jarbus.github.io/XPlot.jl/dev)

[![Build Status](https://github.com/jarbus/XPlot.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/jarbus/XPlot.jl/actions/workflows/CI.yml?query=branch%3Amaster)

# Notes

XPlot is opinionated, and assumes the following:

1. Each experiment has multiple runs.
2. We want to plot the aggregate statistics across all runs of an experimental configuration.
3. We want to compare statistics of one experiment with statistics from a similar experiment.

XPlot makes the following design choices:

1. XPlot introduces the concept of an *"experiment class"* which is a collection of experiments that are similar in nature and typically want to be compared. For example, an experiment class could be "population size" and contain experiments with different population sizes.
2. XPlot does not allow arbitrary nesting of experiment classes--each experiment class is a top-level folder with experiments inside it. We do this to automatically infer the experiment names and plot titles from the folder structure for rapid prototyping, inferred names can be overridden manually. To include the same experiment in different classes, make new class folders with [sym-links](https://en.wikipedia.org/wiki/Symbolic_link) to desired experiments.
3. XPlot can recursively find all experiments matching a regular expression, allowing the user to easily compare different classes or experiments within classes easily.

XPlot thus assumes the following folder structure (names are arbitrary):

```
your-experiments-folder
├── experiment-class-1
│   ├── experiment-1
│   │   ├── trial-1
│   │   │   └── data/statistics.h5
│   │   ├── trial-2
│   │   │   └── data/statistics.h5
│   │   ├── ...
│   │   └── trial-n
│   ├── experiment-2
│   │   ├── trial-1
│   │   ├── trial-2
│   │   ├── ...
│   │   └── trial-n
│   └── ...
├── experiment-class-2
│   ├── experiment-1
│   │   ├── trial-1
│   │   ├── trial-2
│   │   ├── ...
│   │   └── trial-n
│   ├── experiment-2
│   │   └── ...
│   └── ...
├── ...
└── experiment-class-m
    ├── experiment-1
    │   └── ...
    ├── experiment-2
    │   └── ...
    └── ...
```

Where `n` is the number of runs for each experiment. Each run should contain a `timeseries.csv` file with the following structure:


# Installation

```julia
] add https://github.com/jarbus/XPlot
```

# Usage

XPlot introduces two types of measurements:

1. `Measurement`: A single value for a single metric at a given generation.
2. `StatisticalMeasurement`: A distribution for a single metric at a given generation.

XPlot also introduces three types of datapoints for plotting.
1. `TimeSeriesDataPoint`: A single value for a single metric at a given generation.
2. `StatisticalDataPoint`: A distribution for a single metric at a given generation.
3. `AggregatedDataPoint`: A distribution for a single metric aggregated over all trials.



# Example

```julia
# Log and write dummy measurements (statistical and non-statistical)
# over multiple trials
n_trials = 10
n_gens = 10
struct TestNonStatisticalMetric <: AbstractMetric end
struct TestStatisticalMetric <: AbstractMetric end
class_dir = "x/dummyset/"
nc = XPlot.NameConfig(relative_datapath="data/statistics.h5", seed_suffix="/")
for i in 1:n_trials
    stat_path = joinpath(class_dir, "dummyexperiment/$i/data")
    mkpath(stat_path)
    h5open(joinpath(stat_path, "statistics.h5"), "cw") do f
        for j in 1:n_gens
            m = XPlot.Measurement(TestNonStatisticalMetric, rand(), j)
            sm = XPlot.StatisticalMeasurement(TestStatisticalMetric, rand(100), j)
            XPlot.write(f, m)
            XPlot.write(f, sm)
        end
    end
end
# Load data
nonstatistical = XPlot.load(TestNonStatisticalMetric(), nc, class_dir)
statistical = XPlot.load(TestStatisticalMetric(), nc, class_dir)

# Plot non-statistical and statistical data
XPlot.plot(nonstatistical, title="Non-Statistical")
XPlot.plot(statistical, title="Statistical")

# Aggregate statistics over multiple trials and plot
agg_nonstatistical = XPlot.agg(nonstatistical)
XPlot.plot(agg_nonstatistical, title="Aggregated Non-Statistical")
```
