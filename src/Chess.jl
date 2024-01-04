module Chess

include("Boards.jl")
include("Uci.jl")
include("Fen.jl")
include("Games.jl")

using .Games
using .Boards
import .Uci
import .Fen: parse_fen

export 
    start,
    Game, 
    Board, 
    Rank, 
    File, 
    Square, 
    Piece,
    Empty,
    parse_fen,
    new_board, 
    print_board, 
    print_extended_board, 
    sq_ix

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

function start()
    # TODO: this will also need to return an Options instance
    uci_chan_in, uci_chan_out = UCI.start()

    if take!(uci_chan_in) isa UCI.UCINewGame
        game = Game()
        engine_loop(game, uci_chan_in, uci_chan_out)
    # should handle `position` without `newgame` ??
    else error("UCI: expected UCINewGame")
    end
end

"""
Takes a Game already initialised at the start position.
Loops, receiving and making new moves in a game, sending `info` messages to out channel during search, 
and handles exit commands
"""
function engine_loop(game::Game, uci_chan_in, uci_chan_out)
    @debug "starting engine loop"
    searching = false
    search_progress = Search(game)
    while true
        if isready(uci_chan_in)
            @debug "engine loop: reading new UCI command"
            cmd = take!(uci_chan_in)
            @assert cmd isa UCI.UCICommandReceive
            if cmd isa UCI.UCIGo
                searching = true
                search_progress = search(game, search_progress)
                put!(uci_chan_out, search_progress.info)
            # this should be received first (usually with `position startpos`)
            elseif cmd isa UCI.UCIPosition
                game_components = setpos(cmd.fen)
                game = Game(game_components...)
            elseif cmd isa UCI.UCIStop
                put!(uci_chan_out, UCI.UCIBestMove("TODO", "TODO"))
            elseif cmd isa UCI.UCIQuit
                @debug "UCI: quitting"
                break
            else error("UCI: unexpected command")
            end
        elseif searching
            search_progress = search(game, search_progress)
            put!(uci_chan_out, search_progress.info)
        end
    end
end

"""
Search for next move, returning search statistics. 
This should be thread safe so we can search multiple lines in parallel.

Not sure how frequently `search` should return info messages.
"""
function search(game::Game, search_progress::Search)
    #TODO
    @debug "engine is searching"
    return search_progress
end

"`setpos` returns a new Game object. So its not really setting but resetting"
function setpos(fen::String)
    return fen == "startpos" ?  Game() : Game(parse_fen(fen)...)
end

end # module chessjl
