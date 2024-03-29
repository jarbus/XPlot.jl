using XPlot
using Plots
using Test
using HypothesisTests

nc = XPlot.NameConfig(relative_datapath="data/archive.jld2", seed_suffix="/")

@testset "NameInference" begin
    paths = ["x/interaction-distance/1/data/archive.jld2",
        "x/interaction-distance/2/data/archive.jld2"]
    @test XPlot.compute_prefix(paths) == "x/"

    classname, xname, trial = XPlot.subdir_naming_scheme(nc, paths[1])
    @test classname == "x"
    @test xname == "interaction-distance"
    @test trial == "1"

    DIR = @__DIR__
    path = joinpath(@__DIR__,"x/interaction-distance/")
    paths = XPlot.find_datapath_recursively(nc, path)
    @test length(paths) == 2
    @test paths[1] == "$DIR/x/interaction-distance/1/data/archive.jld2"
    @test paths[2] == "$DIR/x/interaction-distance/2/data/archive.jld2"

    @test ""      == XPlot.remove_trailing_numbers("451")
    @test "seed-" == XPlot.remove_trailing_numbers("seed-4")
    @test ""      == XPlot.remove_trailing_numbers("")

    @test "hi" == XPlot.remove_seed(nc, "hi/3")
    @test "" == XPlot.remove_seed(nc, "/3")
    @test "hi" == XPlot.remove_seed(nc, "hi")
    @test "x/interaction-distance-1/" == XPlot.remove_relative_datapath(nc, "x/interaction-distance-1/data/archive.jld2")
    @test "x/interaction-distance-1/" == XPlot.remove_relative_datapath(nc, "x/interaction-distance-1/")

    @test "interaction-distance-1" == XPlot.remove_prefix("x/", "x/interaction-distance-1")

    @test "interaction-distance-1" == XPlot.compute_name(nc, "x/", "x/interaction-distance-1/data/archive.jld2")
end
@testset "InteractionDistanceErrors" begin
    jld2path = joinpath(@__DIR__, "x/interaction-distance/")
    figname = joinpath(@__DIR__, "x/interaction-distance/fig.png")
    # We probably want to move this into PhyloCoEvo at some point
    iderrs = XPlot.load(XPlot.InteractionDistanceErrors(1:3), nc, [jld2path * "1"])
    @test length(iderrs) == 3
    plot(iderrs)
    savefig("$figname")
    # clear current plot
    Plots.plot()
    # Load two iderrs
    iderrs = XPlot.load(XPlot.InteractionDistanceErrors(1:3), nc, [jld2path])
    @test length(iderrs) == 6
    plot(iderrs)
    figname = joinpath(@__DIR__, "x/interaction-distance/fig2.png")
    savefig("$figname")
    # clear current plot
    Plots.plot()
    # Load and aggregate two iderrs
    paths = repeat([jld2path], 10)
    iderrs = XPlot.load(XPlot.InteractionDistanceErrors(1:3), nc, paths)
    agg_iderrs = XPlot.agg(iderrs)
    @test length(agg_iderrs) == 3
    plot(agg_iderrs, title="Two agg")
    figname = joinpath(@__DIR__, "x/interaction-distance/fig3.png")
    savefig("$figname")
    # clear current plot
    Plots.plot()
end

@testset "DummyData" begin  
    dummyfigsdir = joinpath(@__DIR__, "dummy-figs")
    isdir(dummyfigsdir) || mkdir(dummyfigsdir)
    TSDP = XPlot.TimeSeriesDataPoint
    tsd1a = XPlot.TimeSeriesData("dummy-data-1", [TSDP(1, 1, 0.5, 1.5), TSDP(2, 2, 1, 3), TSDP(3,2,1,3)], "x", "y", "dummy-data",1)
    tsd1b = XPlot.TimeSeriesData("dummy-data-1", [TSDP(1, 5, 4.5, 5.5), TSDP(2, 6, 5, 7), TSDP(3,6,5,7)], "x", "y", "dummy-data",1)
    tsd2 = XPlot.TimeSeriesData("dummy-data-2", [TSDP(1, 5, 4.5, 5.5), TSDP(2, 6, 5, 7), TSDP(3,6,5,7)], "x", "y", "dummy-data-2",1)
    @testset "TimeSeriesPlot" begin
        # Plot two different time series
        plot([tsd1a, tsd2], title="test")
        figname = joinpath(@__DIR__, "dummy-figs/dummy-data-1a,2.png")
        savefig(figname)
        @test isfile(figname)
        # clear current plot
        Plots.plot()
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
        @test agg_dd1.data[1].x == 1 && agg_dd1.data[1].value == 3 && agg_dd1.data[1].count == n_samples
        @test agg_dd1.data[2].x == 2 && agg_dd1.data[2].value == 4 && agg_dd1.data[2].count == n_samples
        @test agg_dd1.data[3].x == 3 && agg_dd1.data[3].value == 4 && agg_dd1.data[3].count == n_samples

        # verify aggregate data for dummy-data-2
        @test length(agg_dd2.data) == 3
        @test agg_dd2.data[1].x == 1 && agg_dd2.data[1].value == 5 && agg_dd2.data[1].count == n_samples
        @test agg_dd2.data[2].x == 2 && agg_dd2.data[2].value == 6 && agg_dd2.data[2].count == n_samples
        @test agg_dd2.data[3].x == 3 && agg_dd2.data[3].value == 6 && agg_dd2.data[3].count == n_samples
        XPlot.plot(agg_dd1, title="Agg")
        savefig(figname)
        @test isfile(figname)
        # clear current plot
        Plots.plot()
        figname2 = joinpath(@__DIR__, "dummy-figs/agg-dummy-data-1a,1b,2.png")
        plot(XPlot.agg(vcat(dd1, dd2)), title="test")
        savefig(figname2)
        @test isfile(figname2)
        # clear current plot
        Plots.plot()
    end
end

@testset "Kruskall-Wallis" begin
    # Test to ensure that data is getting extracted correctly
    # from TimeSeriesDataPoints for the wilcoxon test

    # example from
    # https://www.statology.org/kruskal-wallis-test/

    # slight difference in the p-value compared to the
    # example on the website, but I trust the
    # HypothesisTests.jl 
    data = [78 71 57; 65 66 88; 63 56 58; 44 40 78; 50 55 65; 78 31 61; 70 45 62; 61 66 44; 50 47 48; 44 42 77]
    # convert each column to a vector
    cols = [data[:,i] for i in 1:size(data, 2)]
    # convert each column to a vector of vectors
    # of TimeSeriesDataPoints with x=1 and a value
    # equal to the value in the column
    datapoints = [[XPlot.TimeSeriesDataPoint(1, v, 0, 0) for v in col] for col in cols]
    vvts = [[XPlot.TimeSeriesData("dummy-data",
                                  [dist[i], XPlot.TimeSeriesDataPoint(3, 1, 0, 0)],
                                         "x", "y", "dummy-data", 1) 
                        for i in eachindex(dist)]
                        for dist in datapoints]


    # perform kruskal-wallis test
    p1 = XPlot.kruskal_wallis(vvts, 1)
    p2 = KruskalWallisTest(cols...) |> pvalue
    @test p1 ≈ p2 
    @test p1 ≈ 0.21 atol=0.01
end

@testset "Wilcoxon" begin
    # Test to ensure that data is getting extracted correctly
    # from TimeSeriesDataPoints for the wilcoxon test
    # https://en.wikipedia.org/wiki/Wilcoxon_signed-rank_test
    data = [
        125 115 130 140 140 115 140 125 140 135;
        110 122 125 120 140 124 123 137 135 145
    ]
    # create two vectors of TimeSeriesDataPoints
    # with x=1 and a value equal to the value in the column
    vvts = [[XPlot.TimeSeriesData("dummy-data",
                    [XPlot.TimeSeriesDataPoint(1, v, 0, 0)
                        XPlot.TimeSeriesDataPoint(2, v+1, 0, 0) ],
                        "x", "y", "dummy-data", 1) 
                    for v in row]
                    for row in eachrow(data)]


    p1 = XPlot.wilcoxon(vvts[1], vvts[2], 1)
    p2 = SignedRankTest(data[1,:], data[2,:]) |> pvalue
    @test p1 ≈ p2
    @test p1 ≈ 0.61 atol=0.1 # slightly different from the wikipedia example,
                             # but I'm not going to question HypothesisTests.jl
end
