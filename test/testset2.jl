


@testset "Testset 2 Read-in" begin
    
    data = joinpath("data", "testset2")
    result = @suppress_err AnymodResult(data)

    warn_msg = "No files matchin results_costs*.csv found in data\\testset2!"
    @test_logs (:warn, warn_msg) AnymodResult(data)
    @test typeof(result) == AnymodResult

    @test result.scenarios == [
        "ntc_11"
        "ntc_16"
        "ntc_1"
        "ntc_21"
        "ntc_26"
        "ntc_31"
        "ntc_6"
    ]
    @test size(result.summarytable) == (74690, 11)
    @test size(result.costtable) == (0, 0)
    @test size(result.exchangetable) == (22232, 10)

    summarytable_names = [
        "timestep_superordinate_dispatch",
        "variable",
        "value",
        "scenario",
        "region_dispatch_1",
        "region_dispatch_2",
        "technology_1",
        "technology_2",
        "technology_3",
        "carrier_1",
        "carrier_2"
    ]

    @test names(result.summarytable) == summarytable_names
    
    exchangetable_names = [
        "timestep_superordinate_dispatch",
        "value",
        "variable",
        "scenario",
        "region_from_1",
        "region_from_2",
        "region_to_1",
        "region_to_2",
        "carrier_1",
        "carrier_2"
    ]

    @test names(result.exchangetable) == exchangetable_names
end

