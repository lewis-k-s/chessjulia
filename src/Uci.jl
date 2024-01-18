module Uci

import Base.Threads: Atomic
# import .AlgebraicNotation

export
    UCI_SHOULD_CONTINUE,
    UCICommand,
    UCICommandReceive,
    UCICommandResponse,
    UCIUCI,
    UCINewGame,
    UCIGo,
    UCIPosition,
    UCIPonderHit,
    UCIStop,
    UCIQuit,
    UCIIsReady,
    UCIID,
    UCIUCIOK,
    UCIReadyOK,
    UCIInfo,
    UCIBestMove,
    Settings,
    start,
    parse_uci,
    uci_loop,
    uci

abstract type UCICommand end
abstract type UCICommandReceive <: UCICommand end
abstract type UCICommandResponse <: UCICommand end

"""
Allows us to propagate parsing errors, since throwing an exception in our interactive thread would be bad.
Also those errors don't propagate to the main thread, so they just stop the interactive thread invisibly.
"""
struct UCIError <: UCICommand
    msg :: String
end

"""
Pass this in at startup. It switches out the default IO streams for testing.
Game has a settings field but it's also used before games are started
"""
@kwdef struct Settings 
    io_in :: IO = stdin
    io_out :: IO = stdout
end

###################################
# UCI commands from GUI to engine #
###################################

# for the initial command 'uci'
struct UCIUCI <: UCICommandReceive end

struct UCINewGame <: UCICommandReceive end

@kwdef struct UCIGo <: UCICommandReceive
    # searchmoves :: [AlgebraicNotation.Move] = []
    ponder :: Bool = false
    depth :: Int = 0
    movetime :: Int = 0
    wtime :: Int = 0
    btime :: Int = 0
    winc :: Int = 0
    binc :: Int = 0
    movestogo :: Int = 0
    infinite :: Bool = false
end

struct UCIPosition <: UCICommandReceive
    fen :: String
    moves :: Vector{String}
end

struct UCIPonderHit <: UCICommandReceive end

struct UCIStop <: UCICommandReceive end

struct UCIIsReady <: UCICommandReceive end

struct UCISetOption <: UCICommandReceive
    name :: String
    value :: String
end

struct UCIQuit <: UCICommandReceive end

###############################################
# UCI commands from engine, responding to GUI #
###############################################

@kwdef struct UCIID <: UCICommandResponse
    name :: String = "CHESS.JL"
    author :: String = "Lewis"
end

struct UCIUCIOK <: UCICommandResponse end

struct UCIReadyOK <: UCICommandResponse end

struct UCIInfo <: UCICommandResponse
    depth :: Int
    currmovenumber :: Int
    time :: Int
    nodes :: Int
    # seldepth :: Int
    # currmove :: String
    # pv :: Vector{Move}
    # score :: Int
        # cp :: Int
        # mate :: Int
    # multipv :: Int
    # lowerbound :: Bool
    # upperbound :: Bool
    # hashfull :: Int
    # nps :: Int
    # tbhits :: Int
    # sbhits :: Int
    # cpuload :: Float64
    # string :: String
end

struct UCIBestMove <: UCICommandResponse
    bestmove :: String
    ponder :: String
end

# these channels are returned by `start()` but NOT exported by this module.
# Both have a small buffer because under UCI we sometimes write several responses before reading the next command.
# eg. `uci` -> `id name` -> `id author` -> `option` -> `uciok`
const UCI_CHAN_IN = Channel{UCICommandReceive}(5)
const UCI_CHAN_OUT = Channel{UCICommandResponse}(5)
const UCI_SHOULD_CONTINUE = Atomic{Bool}(true)

######################################
# Print UCICommandResponse to stdout #
######################################

respond(r :: UCIID) = [
    "id name $(r.name)",
    "id author $(r.author)",
    # default options
    println("option name Hash type spin default 1 min 1 max 128")
]

respond(:: UCIUCIOK) = ["uciok"]

respond(r :: UCIBestMove) = ["bestmove $(r.bestmove) ponder $(r.ponder)"]

respond(:: UCIReadyOK) = ["readyok"]

respond(r :: UCIInfo) = [
    "info depth $(r.depth) currmovenumber $(r.currmovenumber)" *
    "time $(r.time) nodes $(r.nodes)"
]

write_response(r :: UCICommandResponse, settings :: Settings) = 
    for line in respond(r)
        println(settings.io_out, line)
    end

##########################################
# Parse uci strings to UCICommandReceive #
##########################################

"""
UCI subcommands are either a single word or a key-value pair.
This handles key-value pairs with Int values. I guess it should also handle values that are 'moves'
"""
function parse_fields(line :: String, field_types :: Dict{Symbol, Type})
    # avoid constructing symbols for every field. Inputs may not be valid properties
    field_symbols = Dict{String, Symbol}(string(symb) => symb for symb in keys(field_types))
    int_fields = Dict{Symbol, Int}()
    bool_fields = Dict{Symbol, Bool}()

    split_line = split(line)
    i = 1
    while i <= length(split_line)
        if split_line[i] in keys(field_symbols)
            field = field_symbols[split_line[i]]
            if field_types[field] == Int
                int_fields[field] = parse(Int, split_line[i + 1])
                i += 1
            elseif field_types[field] == Bool
                bool_fields[field] = true
            end
        end
        i += 1
    end

    return int_fields, bool_fields
end

field_types(default) = isstructtype(typeof(default)) ?
    Dict{Symbol, Type}(field => typeof(getfield(default, field)) for field in propertynames(default)) :
    throw(ArgumentError("can only return field types of a struct"))

"""
Overwrite default values with those from the `go` command
"""
function UCIGo(line :: String)
    go_default = UCIGo()
    if isempty(line)
        return go_default
    end

    int_fields, bool_fields = parse_fields(line, field_types(go_default))
    return UCIGo(; int_fields..., bool_fields...)
end

"takes a string and returns a UCICommand or UCIError"
function parse_uci(line :: String)
    if line == "uci"
        return UCIUCI()
    elseif line == "ucinewgame"
        return UCINewGame()
    elseif line == "ponderhit"
        return UCIPonderHit()
    elseif line == "stop"
        return UCIStop()
    elseif line == "quit"
        return UCIQuit()
    elseif line == "isready"
        return UCIIsReady()
    elseif startswith(line, "go")
        return UCIGo(line[3:end])
    # position [ fen fenstring | startpos ] moves {move1} ... {movei}
    elseif startswith(line, "position")
        m = match(r"^position (startpos|fen \S+) ?(moves \S+)?$", line)
        moves = m[2] ? match(r"([prnbqk](x[prnbqk])?[1-8])+", m[2]).captures : []
        pos = m[1]
        if startswith(m[1], "fen")
            # check fen is roughly the right format
            @assert occursin(r"fen ([1-8PNBRQK]+\/){7}[1-8PNBRQK]", m[1]) 
            pos = m[1][5:end]
        end
        return UCIPosition(pos, moves)
    else
        return UCIError("unknown command $line")
    end
end

##############################################
# Run uci interactive thread and talk to GUI #
##############################################

#TODO: actually parse the options
"""
At this point the GUI can send as many `option` commands as it likes before `isready`
"""
setoption_cycle(:: UCISetOption) = setoption_cycle(take!(UCI_CHAN_IN))
setoption_cycle(:: UCIIsReady) = put!(UCI_CHAN_OUT, UCIReadyOK())

"Startup handshake, option setting, and receiving first position"
function init_sequence() 
    @debug "uci initialisation sequence"
    if take!(UCI_CHAN_IN) isa UCIUCI
        put!(UCI_CHAN_OUT, UCIID())
        put!(UCI_CHAN_OUT, UCIUCIOK())
    else error("First command must be 'uci'")
    end

    uci_msg = take!(UCI_CHAN_IN)
    setoption_cycle(uci_msg)
end

"""
Start the UCI interactive thread and return the channels to talk to it. 
The engine should then wait for a `UCINewGame` or `UCIPosition` command.
"""
function start(settings :: Settings = Settings())
    if Threads.nthreads(:interactive) == 0
        # start a new interactive thread to communicate with the GUI
        uci_loop(settings)

        init_sequence()

        return UCI_CHAN_IN, UCI_CHAN_OUT
    else
        error("UCI already started?")
    end
end

function readline_loop(settings :: Settings)
    while UCI_SHOULD_CONTINUE[]
        line = readline(settings.io_in)
        # this is pretty crucial for tests to work, because readline on an empty IOBuffer doesn't block
        if isempty(line)
            @warn "empty line read from UCI"
            yield()
            continue
        end
        @debug "reading line $line"
        try
            cmd = parse_uci(line)
            @debug "parsed command $cmd"
            if cmd isa UCIError
                @warn "UCI error: $(cmd.msg)"
            else
                put!(UCI_CHAN_IN, cmd)
            end
        catch e
            @warn "unexpected error in UCI parsing: $e"
        end
    end
end

function publish_loop(settings :: Settings)
    while UCI_SHOULD_CONTINUE[]
        if isready(UCI_CHAN_OUT)
            try
                @debug "publish loop iteration"
                response = take!(UCI_CHAN_OUT)
                @debug "publishing response $response"
                @assert response isa UCICommandResponse
                write_response(response, settings)
            catch e
                @warn "unexpected error in UCI publishing: $e"
            end
        else
            yield()
        end
    end
end

"""
Talk to the GUI over UCI stdin/sdtout inside an interactive thread.
Two async tasks independently read and write to the UCI channels.
Waiting on input should not block writing output.
"""
function uci_loop(settings :: Settings)
    Threads.@spawn :interactive begin
        @debug "interactive uci thread started"
        @async readline_loop(settings)
        @async publish_loop(settings)
    end
end

end # module UCI