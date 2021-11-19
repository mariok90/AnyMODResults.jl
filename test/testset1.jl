
@testset "Testset 1 Read-in" begin
    data = joinpath("data", "testset1")
    result = AnymodResult(data)

    @test typeof(result) == AnymodResult
    @test result.scenarios == ["desintegriert", "integriert"]
    @test size(result.summarytable) == (21340, 11)
    @test size(result.costtable) == (6116, 11)
    @test size(result.exchangetable) == (6338, 10)

    summarytable_names = [
        "variable",
        "value",
        "scenario",
        "region_dispatch_1",
        "region_dispatch_2",
        "technology_1",
        "technology_2",
        "technology_3",
        "carrier_1",
        "carrier_2",
        "timestep_superordinate_dispatch_1"
    ]

    @test names(result.summarytable) == summarytable_names

    costtable_names = [
        "variable",
        "value",
        "scenario",
        "region_1",
        "region_2",
        "technology_1",
        "technology_2",
        "technology_3",
        "carrier_1",
        "carrier_2",
        "timestep_superordinate_dispatch_1"
    ] 

    @test names(result.costtable) == costtable_names

    exchangetable_names = [
        "value",
        "variable",
        "scenario",
        "region_from_1",
        "region_from_2",
        "region_to_1",
        "region_to_2",
        "carrier_1",
        "carrier_2",
        "timestep_superordinate_dispatch_1"
    ]

    @test names(result.exchangetable) == exchangetable_names
end

