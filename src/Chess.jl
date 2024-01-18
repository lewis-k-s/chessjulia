module Chess

include("Pieces.jl")
include("Squares.jl")
include("Boards.jl")
include("AlgebraicNotation.jl")
include("Uci.jl")
include("Fen.jl")
include("Games.jl")

using .Pieces
using .Games
using .Boards
import .Uci: Settings, parse_uci
import .Fen: parse_fen

export 
    start,
    stop,
    search,
    Game, 
    Settings,
    Board, 
    Rank, 
    File, 
    Square, 
    Piece,
    Empty,
    parse_fen,
    parse_uci,
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

"""
Starts the engine. The UCI interface will always run in a separate thread,
but the main engine loop will block the caller unless run with @async.
"""
function start(settings ::Uci.Settings = Uci.Settings())
    # TODO: this will also need to return an Options instance
    uci_chan_in, uci_chan_out = Uci.start(settings)

    if take!(uci_chan_in) isa Uci.UCINewGame
        game = Game(settings)
        # A uci GUI can tell us to stop thinking. At that point we just wait on new inputs
        # so 'async' will force the engine to yield when waiting on the channel instead of looping infinitely
        wait(@async engine_loop(game, uci_chan_in, uci_chan_out))
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
        @debug "engine loop: waiting for UCI command"
        if !isready(uci_chan_in) && searching
            search_progress = search(game, search_progress)
            put!(uci_chan_out, search_progress.info)
        else
            @debug "engine loop: reading new UCI command"
            cmd = take!(uci_chan_in)
            @assert cmd isa Uci.UCICommandReceive
            if cmd isa Uci.UCIGo
                @debug "engine loop: UCI go"
                searching = true
                search_progress = search(game, search_progress)
                put!(uci_chan_out, search_progress.info)
            # this should be received first (usually with `position startpos`)
            elseif cmd isa Uci.UCIPosition
                game_components = setpos(cmd.fen)
                game = Game(game_components...)
            elseif cmd isa Uci.UCIStop
                put!(uci_chan_out, Uci.UCIBestMove("TODO", "TODO"))
            elseif cmd isa Uci.UCIQuit
                @debug "UCI: quitting"
                stop()
                break
            else error("UCI: unexpected command")
            end
        end
    end
    @debug "stopping engine loop"
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

function stop()
    @debug "Stopping UCI thread"
    Uci.UCI_SHOULD_CONTINUE[] = false
end

end # module chessjl
