module Pieces
import Base.:(==)

export 
    AbstractPiece,
    Piece,
    PieceType,
    Empty

export
    WHITE,
    BLACK,
    PAWN,
    KNIGHT,
    BISHOP,
    ROOK,
    QUEEN,
    KING,
    PAWN_W,
    KNIGHT_W,
    BISHOP_W,
    ROOK_W,
    QUEEN_W,
    KING_W,
    PAWN_B,
    KNIGHT_B,
    BISHOP_B,
    ROOK_B,
    QUEEN_B,
    KING_B

const COLOUR_MASK = 0b0000_0011
const TYPE_MASK = 0b1111_1100

abstract type AbstractPiece end

struct PieceType
    val::UInt8
    PieceType(i::UInt8) = new(i & TYPE_MASK)
    PieceType(c::Char) = c |> Piece |> piece_type
end

struct PieceColour
    val::UInt8
    PieceColour(i::UInt8) = new(i & COLOUR_MASK)
    PieceColour(c::Char) = c |> Piece |> piece_colour
end

struct Piece <: AbstractPiece
    val::UInt8
    Piece(p::PieceType, c::PieceColour) = new(p.val | c.val)
    function Piece(piece::Char)
        if piece == 'P'
            return PAWN_W
        elseif piece == 'N'
            return KNIGHT_W
        elseif piece == 'B'
            return BISHOP_W
        elseif piece == 'R'
            return ROOK_W
        elseif piece == 'Q'
            return QUEEN_W
        elseif piece == 'K'
            return KING_W
        elseif piece == 'p'
            return PAWN_B
        elseif piece == 'n'
            return KNIGHT_B
        elseif piece == 'b'
            return BISHOP_B
        elseif piece == 'r'
            return ROOK_B
        elseif piece == 'q'
            return QUEEN_B
        elseif piece == 'k'
            return KING_B
        else
            throw(ArgumentError("Invalid piece character"))
        end
    end
end

struct Empty <: AbstractPiece end

const WHITE = PieceColour(0b0000_0001)
const BLACK = PieceColour(0b0000_0010)

const PAWN = PieceType(0b0000_0100)
const KNIGHT = PieceType(0b0000_1000)
const BISHOP = PieceType(0b0001_0000)
const ROOK = PieceType(0b0010_0000)
const QUEEN = PieceType(0b0100_0000)
const KING = PieceType(0b1000_0000)

const PAWN_W = Piece(PAWN, WHITE)
const KNIGHT_W = Piece(KNIGHT, WHITE)
const BISHOP_W = Piece(BISHOP, WHITE)
const ROOK_W = Piece(ROOK, WHITE)
const QUEEN_W = Piece(QUEEN, WHITE)
const KING_W = Piece(KING, WHITE)

const PAWN_B = Piece(PAWN, BLACK)
const KNIGHT_B = Piece(KNIGHT, BLACK)
const BISHOP_B = Piece(BISHOP, BLACK)
const ROOK_B = Piece(ROOK, BLACK)
const QUEEN_B = Piece(QUEEN, BLACK)
const KING_B = Piece(KING, BLACK)

piece_colour(p::Piece) = PieceColour(p.val & COLOUR_MASK)
piece_type(p::Piece) = PieceType(p.val & TYPE_MASK)

Base.show(io::IO, p::AbstractPiece) = show(io, piece_to_string(p))
Base.zero(::Type{AbstractPiece}) = Empty()
(==)(a::Empty, b::Empty) = true
(==)(a::Piece, b::Piece) = a.val == b.val
(==)(a::PieceType, b::PieceType) = a.val == b.val
end