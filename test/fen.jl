# Test parse_fen function
@testset "parse_fen" begin
    @testset "Valid FEN string" begin
        @testset "Only kings" begin
            fen = "k7/8/8/8/8/8/8/7K w - - 0 1"
            board, turn, castling, en_passant, halfmove_clock, fullmove_number = parse_fen(fen)
            @test board isa Board
            @test turn == WHITE
            @test isempty(castling)
            @test isempty(en_passant)
            @test halfmove_clock == 0
            @test fullmove_number == 1
        end

        @testset "Starting position" begin
            fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
            board, turn, castling, en_passant, halfmove_clock, fullmove_number = parse_fen(fen)
            @test board isa Board
            @test all(board.board .== new_board().board)
            @test board == new_board()
            @test turn == WHITE
            @test castling == Set([KING_W, QUEEN_W, KING_B, QUEEN_B])
            @test en_passant == Set()
            @test halfmove_clock == 0
            @test fullmove_number == 1
        end

        @testset "En passant" begin
            fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
            _b, _t, _c, en_passant, rest... = parse_fen(fen)
            @test en_passant == Set(sq_ix(3, 5))
        end
    end

    @testset "Invalid FEN string" begin
        @testset "Invalid board fen" begin
            fen = "8/8/8/8/8/8/8/8/8 w - - 0 1"
            @test_throws ArgumentError parse_fen(fen)
        end

        @testset "Invalid turn fen" begin
            fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1"
            @test_throws ArgumentError parse_fen(fen)
        end

        @testset "Invalid castling fen" begin
            fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w ABCD - 0 1"
            @test_throws ArgumentError parse_fen(fen)
        end

        @testset "Invalid en passant fen" begin
            fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq e9 0 1"
            @test_throws ArgumentError parse_fen(fen)
        end

        @testset "Invalid halfmove clock fen" begin
            fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - abc 1"
            @test_throws ArgumentError parse_fen(fen)
        end

        @testset "Invalid fullmove number fen" begin
            fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 abc"
            @test_throws ArgumentError parse_fen(fen)
        end
    end
end