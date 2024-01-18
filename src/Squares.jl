module Squares

import Base: ==

export
    Rank,
    File,
    Square,
    sq_ix,
    parse_square,
    parse_sq_sequence

const ASCII_CHAR_OFFSET = 96
const ASCII_DIGIT_OFFSET = 48

struct Rank
    val::UInt8
    Rank(r::Int) = new(Int8(r))
    Rank(c::Char) = new(Int8(c) - ASCII_CHAR_OFFSET)
end

struct File
    val::UInt8
    File(f::Int) = new(Int8(f))
    File(c::Char) = new(Int8(c) - ASCII_DIGIT_OFFSET)
end

struct Square
    val::Tuple{Rank, File}
    Square(r::Rank, f::File) = new((r,f))
    Square(s::AbstractString) = new(parse_square(s))
end

sq_ix(rank::Rank, file::File) = 16 * (rank.val - 1) + file.val
sq_ix(s::Square) = sq_ix(s.val[1], s.val[2])
sq_ix(r::Int, f::Int) = sq_ix(Rank(r), File(f))
    
validate_square(square_alg::S) where {S <: AbstractString} = 
    length(square_alg) == 2 &&
    occursin(r"[a-h]", square_alg[1] * "") &&
    occursin(r"[1-8]", square_alg[2] * "") || 
    throw(ArgumentError("Invalid square algebraic notation"))

"parse the algebraic notation of a chess square. Should already be validated"
function parse_square(square_alg::S) where {S <: AbstractString}
    @assert validate_square(square_alg)

    return Rank(square_alg[1]), File(square_alg[2])
end

"get square locations from a sequence like e3h4b2 for en passant"
parse_sq_sequence(sq_alg_sequence::S) where {S <: AbstractString} = 
    [sq |> parse_square |> (tp -> sq_ix(tp...)) for sq in Iterators.partition(sq_alg_sequence, 2)]


(==)(r1::Rank, r2::Rank) = r1.val == r2.val
(==)(f1::File, f2::File) = f1.val == f2.val
(==)(s1::Square, s2::Square) = s1.val == s2.val
(==)(a::Square, b::Tuple{Rank,File}) = a.val == b
(==)(a::Tuple{Rank,File}, b::Square) = b == a

end