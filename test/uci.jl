using Chess: Uci

@testset "UCI" begin
    @testset "go" begin
        # test parse_go
        @test Uci.UCIGo("go") == Uci.UCIGo()
        @test Uci.UCIGo("go infinite") == Uci.UCIGo(infinite=true)
        @test Uci.UCIGo("go infinite ponder") == Uci.UCIGo(infinite=true, ponder=true)
        @test Uci.UCIGo("go depth 10") == Uci.UCIGo(depth=10)
        @test Uci.UCIGo("go depth 10") != Uci.UCIGo(depth=10, infinite=true)
    end
end