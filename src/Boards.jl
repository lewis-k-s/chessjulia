module Boards

import Base: ==
using ..Pieces
using ..Squares

export
    Boards,
    Board,
    Rank,
    File,
    Square,
    new_board,
    from_matrix,
    print_board,
    print_extended_board,
    sq_ix


"""
Board is implemented using the 0x88 style.
The main feature of 0x88 is that it allows for fast checking of valid board squares (used in move generation).
The board is a 128-element vector of pieces (ints) where 50% of the elements are unused.
An 8-bit integer (smallest permitted size on most architectures) is used to index the board vector.
The pattern is: the first 8 elements are the first rank, the next 8 are unused, the 3rd 8 are the 2nd rank, etc.

The magic of this representation is the 0x88 mask. 0x88 is 10001000 in binary.
Two rules for valid board squares:
* Three bits are used for a range of 8 values. Because every second range of 8 elements is unused, valid board squares must have the format 0bxxxx_0xxx.
* The board vector only has 128 elements and an 8-bit integer can hold 256 values, valid board squares must have the format 0b0xxx_xxxx.

Together, this means that 0x88 & square_ix == 0 for valid board squares.
"""
mutable struct Board
    board::Vector{AbstractPiece}
end

# 0x88
const oob_mask = 0b10001000

function new_board()
    b_vec::Vector{AbstractPiece} = fill(Empty(), 128)
    b_vec[sq_ix(1, 1):sq_ix(1, 8)] = [ROOK_W, KNIGHT_W, BISHOP_W, QUEEN_W, KING_W, BISHOP_W, KNIGHT_W, ROOK_W]
    b_vec[sq_ix(2, 1):sq_ix(2, 8)] = fill(PAWN_W, 8)
    b_vec[sq_ix(7, 1):sq_ix(7, 8)] = fill(PAWN_B, 8)
    b_vec[sq_ix(8, 1):sq_ix(8, 8)] = [ROOK_B, KNIGHT_B, BISHOP_B, QUEEN_B, KING_B, BISHOP_B, KNIGHT_B, ROOK_B]

    return Board(b_vec)
end

"just for tests"
function from_matrix(board_mat::Matrix{AbstractPiece})
    b_vec = fill(Empty(), 128)
    for r in 1:8
        for f in 1:8
            b_vec[sq_ix(r, f)] = board_mat[r, f]
        end
    end
    Board(b_vec)
end

piece_to_string(e::Empty) = "--"
function piece_to_string(p::Piece)
    ptype = piece_type(p)
    piece_str = ptype == KING ? "K" :
                ptype == QUEEN ? "Q" :
                ptype == ROOK ? "R" :
                ptype == BISHOP ? "B" :
                ptype == KNIGHT ? "N" :
                ptype == PAWN ? "P" : "?"

    color_str = piece_colour(p) == WHITE ? "W" : "B"

    return color_str * piece_str
end

function print_board(b::Board)
    for r in 1:8
        println(join([piece_to_string(b.board[sq_ix(r, f)]) for f in 1:8], " "))
    end
end

function print_extended_board(b::Board)
    for r in 1:8
        println(join([piece_to_string(b.board[sq_ix(r, f)]) for f in 1:16], " "))
    end
end

Base.show(io::IO, b::Board) = show(io, print_board(b))
(==)(a::Board, b::Board) = a.board == b.board

end
