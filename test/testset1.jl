data = joinpath("data", "testset1")
result = AnymodResult(data)

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

    @testset "Pivot" begin
        file_path = joinpath("data", "testset1_results")

        mask1 = Mask(
            Scenario(),
            Technology(1 => ["wind_offshore","wind_onshore","pv"]),
            Region(2 => "DE", mode=:occursin),
            Variable("capaConv")
        )
        
        mask1_result = CSV.read(
            joinpath(file_path, "mask1_result.csv"),
            DataFrame
        )

        @test pivotresult(result, mask1) == mask1_result

        mask2 = Mask(
            Technology(2),
            Region(1 => ["AT", "DE", "CH", "FR", "NL", "DK"]),
            Variable(["capaConv", "capaStOut"]),
            Scenario("integriert")
        )

        mask2_result = CSV.read(
            joinpath(file_path, "mask2_result.csv"),
            DataFrame
        )

        df2 = pivotresult(result, mask2)

        for x in eachindex(mask2_result[:,1]), y in names(mask2_result)[2:end]
            if ismissing(mask2_result[x,y])
                @test ismissing(df2[x,y])
            else
                @test mask2_result[x,y] ≈ df2[x,y]
            end
        end

        mask3 = Mask(
            Carrier(1),
            Variable(["demand", "use","gen","export","import","trdBuy"]),
            Scenario("integriert"),
            Region(2 => "DE", mode = :occursin)
        )

        mask3_result = CSV.read(
            joinpath(file_path, "mask3_result.csv"),
            DataFrame
        )

        df3 = pivotresult(result, mask3)

        for x in eachindex(mask3_result[:,1]), y in names(mask3_result)[2:end]
            if ismissing(mask3_result[x,y])
                @test ismissing(df3[x,y])
            else
                @test mask3_result[x,y] ≈ df3[x,y]
            end
        end

    end
end
