module Test

using Test
using Chess
using Logging

Logging.global_logger(Logging.SimpleLogger(stdout, Logging.Debug))

include("fen.jl")
include("uci.jl")
include("algebraic_notation.jl")
# include("chess.jl")

end
