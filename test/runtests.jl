using XPlot
using Plots
using Test
data = joinpath(@__DIR__, "data")
@testset "XPlot.jl" begin
    # Write your tests here.
    iderrs = XPlot.InteractionDistanceErrors([1,2,3], joinpath(data, "archive.jld2"))
    @test length(iderrs) == 3
    tsp = XPlot.TimeSeriesPlot("test", collect(values(iderrs)))
    XPlot.plot(tsp)
    savefig("test.png")
    run(`kitten icat test.png`)
    # clear current plot
    plot()
    # run(`rm test.png`)
end
