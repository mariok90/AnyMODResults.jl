data = joinpath("data", "testset1")
result = AnymodResult(data; threaded=false)

@testset "Testset 1" begin
    @testset "Read-in" begin
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

    file_path = joinpath("data", "testset1_results")
    @testset "Tables" begin

        mask1 = Mask(
            Scenario(),
            Technology(1 => ["wind_offshore","wind_onshore","pv"]),
            Region(2 => "DE", mode=:occursin),
            Variable("capaConv"),
            Timestep("2050")
        )
        
        mask1_result = CSV.read(
            joinpath(file_path, "mask1_result.csv"),
            DataFrame
        )

        @test pivotresult(result, mask1) == mask1_result

        mask2 = Mask(
            Technology(2),
            Region(1 => ["AT", "DE", "CH", "FR", "NL", "DK"]),
            Variable("capaConv", "capaStOut"),
            Scenario("integriert")
        )

        mask2_result = CSV.read(
            joinpath(file_path, "mask2_result.csv"),
            DataFrame
        )

        df2 = pivotresult(result, mask2)
        @test compare_table_values(mask2_result, df2)

        mask3 = Mask(
            Carrier(),
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Scenario("integriert"),
            Region(2 => "DE", mode = :occursin),
            Timestep(["2050"])
        )

        mask3_result = CSV.read(
            joinpath(file_path, "mask3_result.csv"),
            DataFrame
        )

        df3 = pivotresult(result, mask3)
        @test compare_table_values(mask3_result, df3)

        mask_warn = Mask(
            Carrier(4 => ["asdf"]),
            Region(5 => "DE", mode = :occursin)
        )

        @suppress @test_throws ArgumentError pivotresult(result, mask_warn)

        result_mask1 = Mask(
            [Scenario(), Carrier()],
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Region(2 => "DE", mode = :occursin)
        )

        stacked_result1 = CSV.read(
            joinpath(file_path, "stacked_result_1.csv"),
            DataFrame
        )

        df_stacked = stackedresult(result, result_mask1)
        @test compare_table_values(stacked_result1, df_stacked)
    end

    @testset "Plots" begin

        ### Plot 1 ###
        result_mask1 = Mask(
            [Scenario(), Carrier()],
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Region(2 => "DE", mode = :occursin)
        )

        p1 = json(plot_anymod_result(result, result_mask1))
        p1_result = JSON.read(joinpath(file_path, "plot1.json"), String)

        @test p1[1:1000] == p1_result[1:1000]

        ### Plot 2 ###
        result_mask2 = Mask(
            Scenario(),
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Region(2 => "DE", mode = :occursin),
            Carrier("electricity")
        )
        
        p2 = plot_anymod_result(result, result_mask2) |> json
        p2_result = JSON.read(joinpath(file_path, "plot2.json"), String)
        @test p2[1:1000] == p2_result[1:1000]


        ### Plot 3 ###
        result_mask3 = Mask(
            Scenario(),
            nothing,
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Region(2 => "DE", mode = :occursin),
            Carrier("electricity")
        )
        
        p3 = plot_anymod_result(result, result_mask3) |> json
        p3_result = JSON.read(joinpath(file_path, "plot3.json"), String)
        @test p3[1:1000] == p3_result[1:1000]


        ### Plot 4 ###
        result_mask4 = Mask(
            [Scenario(), Carrier()],
            nothing,
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Region(2 => "DE", mode = :occursin)
        )
        
        p4 = plot_anymod_result(result, result_mask4) |> json
        p4_result = JSON.read(joinpath(file_path, "plot4.json"), String)
        @test p4[1:1000] == p4_result[1:1000]

    end
end
