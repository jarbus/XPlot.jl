using XPlot
using Test
# using HypothesisTests

nc = XPlot.NameConfig(relative_datapath="data/archive.h5", seed_suffix="/")

@testset "NameInference" begin
    paths = ["x/interaction-distance/1/data/archive.h5",
        "x/interaction-distance/2/data/archive.h5"]
    @test XPlot.compute_prefix(paths) == "x/"

    classname, xname, trial = XPlot.subdir_naming_scheme(nc, paths[1])
    @test classname == "x"
    @test xname == "interaction-distance"
    @test trial == "1"

    DIR = @__DIR__
    path = joinpath(@__DIR__,"x/interaction-distance/")
    paths = XPlot.find_datapath_recursively(nc, path)
    @test length(paths) == 2
    @test paths[1] == "$DIR/x/interaction-distance/1/data/archive.h5"
    @test paths[2] == "$DIR/x/interaction-distance/2/data/archive.h5"

    @test ""      == XPlot.remove_trailing_numbers("451")
    @test "seed-" == XPlot.remove_trailing_numbers("seed-4")
    @test ""      == XPlot.remove_trailing_numbers("")

    @test "hi" == XPlot.remove_seed(nc, "hi/3")
    @test "" == XPlot.remove_seed(nc, "/3")
    @test "hi" == XPlot.remove_seed(nc, "hi")
    @test "x/interaction-distance-1/" == XPlot.remove_relative_datapath(nc, "x/interaction-distance-1/data/archive.h5")
    @test "x/interaction-distance-1/" == XPlot.remove_relative_datapath(nc, "x/interaction-distance-1/")

    @test "interaction-distance-1" == XPlot.remove_prefix("x/", "x/interaction-distance-1")

    @test "interaction-distance-1" == XPlot.compute_name(nc, "x/", "x/interaction-distance-1/data/archive.h5")
end

@testset "DummyData" begin  
    dummyfigsdir = joinpath(@__DIR__, "dummy-figs")
    isdir(dummyfigsdir) || mkdir(dummyfigsdir)
    TSDP = XPlot.TimeSeriesDataPoint
    tsd1a = XPlot.TimeSeriesData("dummy-data-1", [TSDP(1, 1), TSDP(2, 2), TSDP(3,2)], "x", "y", "dummy-data",1)
    tsd1b = XPlot.TimeSeriesData("dummy-data-1", [TSDP(1, 5), TSDP(2, 6), TSDP(3,6)], "x", "y", "dummy-data",1)
    tsd2 = XPlot.TimeSeriesData("dummy-data-2", [TSDP(1, 5), TSDP(2, 6), TSDP(3,6)], "x", "y", "dummy-data-2",1)
    @testset "TimeSeriesPlot" begin
        # Plot two different time series
        plot([tsd1a, tsd2], title="test")
        figname = joinpath(@__DIR__, "dummy-figs/dummy-data-1a,2.png")
        savefig(figname)
        @test isfile(figname)
        # clear current plot
        XPlot.Plots.plot()
    end
    @testset "Aggregation" begin
        # Create aggregate time series data
        figname = joinpath(@__DIR__, "dummy-figs/agg-dummy-data-1a,1b.png")
        manual_agg_data = XPlot.AggregatedTimeSeriesData([tsd1a, tsd1b])
        n_samples = 10
        dd1 = repeat([tsd1a, tsd1b], Int(n_samples / 2))
        dd2 = repeat([tsd2], n_samples)
        auto_agg_data = XPlot.agg(vcat(dd1, dd2))
        @test length(auto_agg_data) == 2
        names = [d.name for d in auto_agg_data]
        @test "dummy-data-1" ∈ names
        @test "dummy-data-2" ∈ names
        agg_dd1 = auto_agg_data[findfirst(x -> x.name == "dummy-data-1", auto_agg_data)]
        agg_dd2 = auto_agg_data[findfirst(x -> x.name == "dummy-data-2", auto_agg_data)]
        # verify aggregate data for dummy-data-1
        @test length(agg_dd1.data) == 3
        @test agg_dd1.data[1].x == 1 && agg_dd1.data[1].value == 3 && agg_dd1.data[1].n_samples == n_samples
        @test agg_dd1.data[1].max == 5 && agg_dd1.data[1].min == 1
        @test agg_dd1.data[2].x == 2 && agg_dd1.data[2].value == 4 && agg_dd1.data[2].n_samples == n_samples
        @test agg_dd1.data[2].max == 6 && agg_dd1.data[2].min == 2
        @test agg_dd1.data[3].x == 3 && agg_dd1.data[3].value == 4 && agg_dd1.data[3].n_samples == n_samples
        @test agg_dd1.data[3].max == 6 && agg_dd1.data[3].min == 2
        @test agg_dd1.data[1].std ≈ 2.108 atol=0.01
        @test agg_dd1.data[2].std ≈ 2.108 atol=0.01
        @test agg_dd1.data[3].std ≈ 2.108 atol=0.01

        # verify aggregate data for dummy-data-2
        @test length(agg_dd2.data) == 3
        @test agg_dd2.data[1].x == 1 && agg_dd2.data[1].value == 5 && agg_dd2.data[1].n_samples == n_samples
        @test agg_dd2.data[1].max == 5 && agg_dd2.data[1].min == 5
        @test agg_dd2.data[2].x == 2 && agg_dd2.data[2].value == 6 && agg_dd2.data[2].n_samples == n_samples
        @test agg_dd2.data[2].max == 6 && agg_dd2.data[2].min == 6
        @test agg_dd2.data[3].x == 3 && agg_dd2.data[3].value == 6 && agg_dd2.data[3].n_samples == n_samples
        @test agg_dd2.data[3].max == 6 && agg_dd2.data[3].min == 6
        @test agg_dd2.data[1].std ≈ 0.0 atol=0.01
        @test agg_dd2.data[2].std ≈ 0.0 atol=0.01
        @test agg_dd2.data[3].std ≈ 0.0 atol=0.01
        XPlot.plot(agg_dd1, title="Agg")
        savefig(figname)
        @test isfile(figname)
        # clear current plot
        XPlot.Plots.plot()
        figname2 = joinpath(@__DIR__, "dummy-figs/agg-dummy-data-1a,1b,2.png")
        plot(XPlot.agg(vcat(dd1, dd2)), title="test")
        savefig(figname2)
        @test isfile(figname2)
        # if kitty command is defined, display the figure using icat
        if !isnothing(Sys.which("kitty"))
            run(`kitty +kitten icat $figname`)
            run(`kitty +kitten icat $figname2`)
        end
        # clear current plot
        XPlot.Plots.plot()
    end
end

struct DummyMetric <: AbstractMetric end
struct DummyStatisticalMetric <: AbstractMetric end

@testset "Measurements" begin
    m = XPlot.Measurement(DummyMetric, 1.0, 1)
    data = [1,2,3]
    sm = XPlot.StatisticalMeasurement(DummyStatisticalMetric, data, 1)
    @assert dirname(nc.relative_datapath) == "data"
    data_dir = "x/dummyset/dummyexperiment/1/data"
    mkpath(data_dir)
    archive_path = joinpath(data_dir, "archive.h5")

    @testset "Writing" begin
        h5open(archive_path, "cw") do f
            XPlot.write(f, m)
            XPlot.write(f, sm)
        end
        h5open(archive_path, "r") do f
            @test f["$(XPlot.HEAD)/1/DummyMetric"] |> read == 1.0
            @test f["$(XPlot.HEAD)/1/DummyStatisticalMetric/min"] |> read == 1.0
            @test f["$(XPlot.HEAD)/1/DummyStatisticalMetric/mean"] |> read == 2.0
            @test haskey(f, "$(XPlot.HEAD)/1")
        end
    end
    @testset "Loading" begin
        ts = XPlot.load(DummyMetric(), nc, "x/dummyset")
        sts = XPlot.load(DummyStatisticalMetric(), nc, "x/dummyset")
        @test ts[1].data[1].value == 1.0
        @test sts[1].data[1].mean == 2.0
    end
    rm("x/dummyset", recursive=true)
end

#
# @testset "Kruskall-Wallis" begin
#     # Test to ensure that data is getting extracted correctly
#     # from TimeSeriesDataPoints for the wilcoxon test
#
#     # example from
#     # https://www.statology.org/kruskal-wallis-test/
#
#     # slight difference in the p-value compared to the
#     # example on the website, but I trust the
#     # HypothesisTests.jl 
#     data = [78 71 57; 65 66 88; 63 56 58; 44 40 78; 50 55 65; 78 31 61; 70 45 62; 61 66 44; 50 47 48; 44 42 77]
#     # convert each column to a vector
#     cols = [data[:,i] for i in 1:size(data, 2)]
#     # convert each column to a vector of vectors
#     # of TimeSeriesDataPoints with x=1 and a value
#     # equal to the value in the column
#     datapoints = [[XPlot.TimeSeriesDataPoint(1, v, 0, 0) for v in col] for col in cols]
#     vvts = [[XPlot.TimeSeriesData("dummy-data",
#                                   [dist[i], XPlot.TimeSeriesDataPoint(3, 1, 0, 0)],
#                                          "x", "y", "dummy-data", 1) 
#                         for i in eachindex(dist)]
#                         for dist in datapoints]
#
#
#     # perform kruskal-wallis test
#     p1 = XPlot.kruskal_wallis(vvts, 1)
#     p2 = KruskalWallisTest(cols...) |> pvalue
#     @test p1 ≈ p2 
#     @test p1 ≈ 0.21 atol=0.01
# end
#
# @testset "Wilcoxon" begin
#     # Test to ensure that data is getting extracted correctly
#     # from TimeSeriesDataPoints for the wilcoxon test
#     # https://en.wikipedia.org/wiki/Wilcoxon_signed-rank_test
#     data = [
#         125 115 130 140 140 115 140 125 140 135;
#         110 122 125 120 140 124 123 137 135 145
#     ]
#     # create two vectors of TimeSeriesDataPoints
#     # with x=1 and a value equal to the value in the column
#     vvts = [[XPlot.TimeSeriesData("dummy-data",
#                     [XPlot.TimeSeriesDataPoint(1, v, 0, 0)
#                         XPlot.TimeSeriesDataPoint(2, v+1, 0, 0) ],
#                         "x", "y", "dummy-data", 1) 
#                     for v in row]
#                     for row in eachrow(data)]
#
#
#     p1 = XPlot.wilcoxon(vvts[1], vvts[2], 1)
#     p2 = SignedRankTest(data[1,:], data[2,:]) |> pvalue
#     @test p1 ≈ p2
#     @test p1 ≈ 0.61 atol=0.1 # slightly different from the wikipedia example,
#                              # but I'm not going to question HypothesisTests.jl
# end
