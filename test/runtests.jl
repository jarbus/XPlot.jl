using XPlot
using Plots
using Test
@testset "InteractionDistanceErrors" begin
    data = joinpath(@__DIR__, "x/interaction-distance-1/data")
    # We probably want to move this into PhyloCoEvo at some point
    iderrs = XPlot.InteractionDistanceErrors([1,2,3], joinpath(data, "archive.jld2"))
    @test length(iderrs) == 3
    tsp = XPlot.TimeSeriesPlot("test", collect(values(iderrs)))
    XPlot.plot(tsp)
    savefig("test.png")
    # clear current plot
    plot()
    run(`rm test.png`)
end

end
