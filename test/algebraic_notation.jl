import Chess.AlgebraicNotation: Move
using Chess.Squares

@testset "AlgebraicNotation" begin

@testset "Move" begin
    @testset "pawn moves" begin
        @test Move("e5") == Move(PAWN, Square("e5"), nothing, false, false, false, nothing)
        @test Move("exd5") == Move(PAWN, Square("d5"), nothing, true, false, false, Rank('e'))
        @test Move("e8=Q") == Move(PAWN, Square("e8"), QUEEN, false, false, false, nothing)
        @test Move("exd8=Q+") == Move(PAWN, Square("d8"), QUEEN, true, true, false, Rank('e'))
    end

    @testset "piece moves" begin
        @test Move("Qf3") == Move(QUEEN, Square("f3"), nothing, false, false, false, nothing)
        @test Move("Nxd3") == Move(KNIGHT, Square("d3"), nothing, true, false, false, nothing)
        @test Move("Rxa4") == Move(ROOK, Square("a4"), nothing, true, false, false, nothing)
        @test Move("Bxf3#") == Move(BISHOP, Square("f3"), nothing, true, false, true, nothing)
    end

    @testset "invalid moves" begin
        @test_throws ErrorException Move("invalid")
        @test_throws ErrorException Move("e9")
        @test_throws ErrorException Move("i1")
    end
end

end
