function get_species_matchups(file, metric="phylogeneticestimatorstats"; head="gen")
    # get the largest number string
    gens = keys(file[head]) |> collect |> x->sort(x, by=y->parse(Int, y), rev=true)
    # from the end of the list to the beginning, find the first generation
    # that has the key "$head/$gen/$metric"
    max_gen = 1
    for gen in gens
        if haskey(file, "$head/$gen/$metric")
            max_gen = gen
            break
        end
    end
    # get all species in the last generation
    species = keys(file["$head/$max_gen/$metric"]) |> collect
    species
end

include("./estimatecacheevalsample.jl")
include("./genotypesize.jl")
include("./genotypesum.jl")
include("./iderrs.jl")
include("./phylogeneticestimator.jl")
include("./sort.jl")
