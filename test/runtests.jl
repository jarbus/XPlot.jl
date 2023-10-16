using XPlot
using Plots
using Test
@testset "InteractionDistanceErrors" begin
    jld2path = joinpath(@__DIR__, "x/interaction-distance-1/data/archive.jld2")
    figname = joinpath(@__DIR__, "x/interaction-distance-1/fig.png")
    # We probably want to move this into PhyloCoEvo at some point
    iderrs = XPlot.load(XPlot.InteractionDistanceErrors(1:3), jld2path)
    @test length(iderrs) == 3
    tsp = XPlot.TimeSeriesPlot(iderrs)
    XPlot.plot(tsp)
    savefig("$figname")
    # clear current plot
    plot()
end

@testset "DummyData" begin
    TSDP = XPlot.TimeSeriesDataPoint
    tsd1a = XPlot.TimeSeriesData("dummy-data-1", [TSDP(1, 1, 0.5, 1.5), TSDP(2, 2, 1, 3), TSDP(3,2,1,3)])
    tsd1b = XPlot.TimeSeriesData("dummy-data-1", [TSDP(1, 5, 4.5, 5.5), TSDP(2, 6, 5, 7), TSDP(3,6,5,7)])
    tsd2 = XPlot.TimeSeriesData("dummy-data-2", [TSDP(1, 5, 4.5, 5.5), TSDP(2, 6, 5, 7), TSDP(3,6,5,7)])
    @testset "TimeSeriesPlot" begin
        # Plot two different time series
        tsp = XPlot.TimeSeriesPlot("test", [tsd1a, tsd2])
        XPlot.plot(tsp)
        figname = joinpath(@__DIR__, "dummy-figs/dummy-data-1a,2.png")
        savefig(figname)
        @test length(tsp.data) == 2
        @test isfile(figname)
        # clear current plot
        plot()
    end
    @testset "Aggregation" begin
        # Create aggregate time series data
        figname = joinpath(@__DIR__, "dummy-figs/agg-dummy-data-1a,1b.png")
        manual_agg_data = XPlot.AggregatedTimeSeriesData("agg_dummy_data", [tsd1a, tsd1b])
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
        XPlot.plot(XPlot.TimeSeriesPlot("test", [agg_dd1]))
        savefig(figname)
        @test isfile(figname)
        # clear current plot
        plot()
        figname2 = joinpath(@__DIR__, "dummy-figs/agg-dummy-data-1a,1b,2.png")
        XPlot.plot(XPlot.TimeSeriesPlot("test", XPlot.agg(vcat(dd1, dd2))))
        savefig(figname2)
        @test isfile(figname2)
        # clear current plot
        plot()
    end
end
