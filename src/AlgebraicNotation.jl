module AlgebraicNotation

using ..Pieces
using ..Squares

export 
    Move,
    parse_move

struct Move
    piece :: PieceType
    to :: Square
    promotion :: Union{PieceType, Nothing}
    capture :: Bool
    check :: Bool
    checkmate :: Bool
    disambiguation :: Union{Nothing, File, Rank}
end

# pawn take always has a disambiguation: e.g. exd5
# h5
# Qf3+
# Nxd3
# Rxa4+
# Bxf3#
# e8=Q
# exd8=Q+
const MOVE_REG = r"([a-h])?([RNBQK])?x?([a-h][1-8])(?:=([RNBQK]))?[+#]?"

function Move(move_str::AbstractString)
    # check if the move string is valid
    if move_str === nothing
        error("Invalid move string: $move")
    end

    move = match(MOVE_REG, move_str)

    # parse the move string
    disambiguation = nothing
    if !isnothing(move.captures[1]) 
        c = move.captures[1][1]
        disambiguation = isdigit(c) ? File(c) : Rank(c)
    end
    piece = isnothing(move.captures[2]) ? PAWN : PieceType(move.captures[2][1])
    dest = isnothing(move.captures[3]) ? 
        throw(ArgumentError("algebraic notation must include a destination square")) :
        Square(move.captures[3])
    promotion = contains(move_str, "=") && !isnothing(move.captures[4]) ? PieceType(move.captures[4][1]) : nothing

    # check if it's a capture move
    capture = contains(move_str, "x")

    # check if it's a check or checkmate move
    check = contains(move_str, "+")
    checkmate = contains(move_str, "#")

    # create and return the Move object
    return Move(piece, dest, promotion, capture, check, checkmate, disambiguation)
end

end
