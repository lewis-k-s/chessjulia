module Fen

using ..Pieces
using ..Squares
import ..Boards: new_board

export parse_fen

"NOT exhaustive"
validate_board_fen(board_fen::S) where {S <: AbstractString} = 
    # must always have 2 kings
    length(findall(r"k"i, board_fen)) == 2 &&
    # must have 0-8 pawns
    length(findall(r"p"i, board_fen)) <= 16 &&
    # board has 8 ranks
    length(findall("/", board_fen)) == 7 &&
    # ranks have 8 squares
    isempty(findall(r"9|\d{2,}", board_fen)) ||
    throw(ArgumentError("Invalid board FEN"))


function parse_board_fen(board_fen::S) where {S <: AbstractString}
    @assert validate_board_fen(board_fen)

    board = new_board()
    rank = 8
    file = 1
    for c in board_fen
        if c == '/'
            rank -= 1
            file = 1
        elseif isdigit(c)
            file += parse(Int, c)
        else
            piece = Piece(c)
            board.board[sq_ix(rank, file)] = piece
            file += 1
        end
    end
    return board
end

function parse_turn_fen(turn_fen::S) where {S <: AbstractString}
    if turn_fen == "w"
        return WHITE
    elseif turn_fen == "b"
        return BLACK
    else
        throw(ArgumentError("Invalid turn FEN"))
    end
end

function parse_castling_fen(castling_fen::S) where {S <: AbstractString}
    castling = Set{Piece}()
    if castling_fen == "-"
        return castling
    end

    for c in castling_fen
        if c == 'K' push!(castling, KING_W)
        elseif c == 'Q' push!(castling, QUEEN_W)
        elseif c == 'k' push!(castling, KING_B)
        elseif c == 'q' push!(castling, QUEEN_B)
        else throw(ArgumentError("Invalid castling FEN"))
        end
    end
    return castling
end

parse_en_passant_fen(en_passant_fen::S) where {S <: AbstractString} =
    en_passant_fen == "-" ?  Set{Int}() : Set{Int}(parse_sq_sequence(en_passant_fen))

"Parse FEN string and return the components needed to build a Game"
function parse_fen(fen::String)
    parts = split(fen, ' ')
    length(parts) == 6 || throw(ArgumentError("Invalid FEN string"))
    board_fen = parts[1]
    turn_fen = parts[2]
    castling_fen = parts[3]
    en_passant_fen = parts[4]
    halfmove_clock = parse(Int, parts[5])
    fullmove_number = parse(Int, parts[6])

    board = parse_board_fen(board_fen)
    turn = parse_turn_fen(turn_fen)
    castling = parse_castling_fen(castling_fen)
    en_passant = parse_en_passant_fen(en_passant_fen)

    return board, turn, castling, en_passant, halfmove_clock, fullmove_number
end

end
