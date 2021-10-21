
@testset "Testset 3 Read-in" begin
    data = joinpath("data", "testset3")
    result = AnymodResult(data)

    @test typeof(result) == AnymodResult
    @test result.scenarios == ["integriert"]
    @test size(result.summarytable) == (10670, 11)
    @test size(result.costtable) == (3058, 11)
    @test size(result.exchangetable) == (3162, 10)
end

