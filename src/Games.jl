module Games

import ..Pieces: Piece, PieceColour, WHITE
import ..Boards: Board, new_board, Square 
import ..Uci: UCIInfo, Settings

export 
    Game, 
    Options,
    Search

mutable struct Game
    board :: Board
    turn :: PieceColour
    castling_rights :: Set{Piece}
    en_passant :: Set{Int}
    halfmove_clock :: Int
    fullmove_number :: Int
    settings :: Settings
    Game(settings = Settings()) = new(new_board(), WHITE, Set(), Set(), 0, 0, settings)
end

# TODO: allow init sequence `setoption` to set these
struct Options
    hash_size :: Int
    threads :: Int
    multipv :: Int
    skill_level :: Int
    move_overhead :: Int
    minimum_think_time :: Int
    slow_mover :: Int
    nodestime :: Int
    ucinewgame :: Bool
    syzygy_path :: String
    syzygy_probe_depth :: Int
    syzygy_probe_limit :: Int
    syzygy_50_move_rule :: Bool
    syzygy_wdl :: Bool
    syzygy_wdl_cache :: Bool
    syzygy_tb :: Bool
end

struct Search 
    game :: Game
    depth :: Int
    movetime :: Int
    wtime :: Int
    btime :: Int
    winc :: Int
    binc :: Int
    movestogo :: Int
    infinite :: Bool
    info :: UCIInfo
    Search(game) = new(game, 0, 0, 0, 0, 0, 0, 0, false, UCIInfo(0, 0, 0, 0))
end

end
