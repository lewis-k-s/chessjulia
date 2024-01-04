module Uci

export
    UCICommand,
    UCICommandReceive,
    UCICommandResponse,
    UCIUCI,
    UCINewGame,
    UCIGo,
    UCIPosition,
    UCIPonderHit,
    UCIStop,
    UCIIsReady,
    UCIID,
    UCIUCIOK,
    UCIReadyOK,
    UCIInfo,
    UCIBestMove,
    start,
    parse_uci,
    uci_loop,
    uci

abstract type UCICommand end
abstract type UCICommandReceive <: UCICommand end
abstract type UCICommandResponse <: UCICommand end

###################################
# UCI commands from GUI to engine #
###################################

# for the initial command 'uci'
struct UCIUCI <: UCICommandReceive end

struct UCINewGame <: UCICommandReceive end

struct UCIGo <: UCICommandReceive
    depth :: Int
    movetime :: Int
    wtime :: Int
    btime :: Int
    winc :: Int
    binc :: Int
    movestogo :: Int
    infinite :: Bool
    UCIGo() = new(0, 0, 0, 0, 0, 0, 0, false)
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
    # seldepth :: Int
    currmove :: String
    currmovenumber :: Int
    time :: Int
    nodes :: Int
    mate :: Int
    pv :: Vector{String}
    score :: Int
    # multipv :: Int
    # cp :: Int
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

######################################
# Print UCICommandResponse to stdout #
######################################

function write_response(r :: UCIID)
    println("id name $(r.name)")
    println("id author $(r.author)")

    # default options
    println("option name Hash type spin default 1 min 1 max 128")
end

function write_response(:: UCIUCIOK)
    println("uciok")
end

function write_response(r :: UCIBestMove)
    println("bestmove $(r.bestmove) ponder $(r.ponder)")
end

function write_response(:: UCIReadyOK)
    println("readyok")
end

function write_response(r :: UCIInfo)
    println("info depth $(r.depth) currmove $(r.currmove) currmovenumber $(r.currmovenumber) time $(r.time) nodes $(r.nodes) score $(r.score) mate $(r.mate) pv $(join(r.pv, " "))")
end

##########################################
# Parse uci strings to UCICommandReceive #
##########################################

"""
the first word `go` has already been stripped.
It can be followed by `depth`, `movetime`, `wtime`, `btime`, `winc`, `binc`, `movestogo`, or `infinite`
"""
function parse_go(uci_go :: UCIGo, line :: String)
    while !empty(line)
        if startswith(line, "depth")
            match_result = match(r"depth (\d+)", line)
            uci_go.depth = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "movetime")
            match_result = match(r"movetime (\d+)", line)
            uci_go.movetime = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "wtime")
            match_result = match(r"wtime (\d+)", line)
            uci_go.wtime = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "btime")
            match_result = match(r"btime (\d+)", line)
            uci_go.btime = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "winc")
            match_result = match(r"winc (\d+)", line)
            uci_go.winc = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "binc")
            match_result = match(r"binc (\d+)", line)
            uci_go.binc = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "movestogo")
            match_result = match(r"movestogo (\d+)", line)
            uci_go.movestogo = parse(Int, match_result.captures[1])
            line = line[length(match_result.match) + 1:end]
        elseif startswith(line, "infinite")
            uci_go.infinite = true
            line = line[9:end]
        else
            error("Invalid UCI `go` field")
        end
    end
    return uci_go
end
    
"takes a string and returns a UCICommand"
function parse_uci(line :: String)
    if line == "uci"
        return UCIUCI()
    elseif line == "newgame"
        return UCINewGame()
    elseif line == "ponderhit"
        return UCIPonderHit()
    elseif line == "stop"
        return UCIStop()
    elseif line == "ready"
        return UCIReady()
    elseif line == "isready"
        return UCIReady()
    elseif startswith(line, "go")
        return parse_go(UCIGo(), line[3:end])
    # position [ fen fenstring | startpos ] moves {move1} ... {movei}
    elseif startswith("position", line)
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
        error("Invalid UCI command")
    end
end

##############################################
# Run uci interactive thread and talk to GUI #
##############################################

"Startup handshake, option setting, and first position"
function init_sequence(uci_chan_in::Channel{UCICommandReceive}, uci_chan_out::Channel{UCICommandResponse}) 
    if take!(uci_chan_in) isa UCIUCI
        put!(uci_chan_out, UCIID())
        put!(uci_chan_out, UCIUCIOK())
    else error("First command must be 'uci'")
    end

    uci_msg = take!(uci_chan_in)
    setoption_cycle(uci_msg)

    # currently do nothing on `setoption`
    setoption_cycle = (:: UCISetOption) -> setoption_cycle(take!(uci_chan_in))
    setoption_cycle = (:: UCIIsReady) -> put!(uci_chan_out, UCIReadyOK())
end

"""
Start the UCI interactive thread and return the channels to talk to it. 
The engine should then wait for a `UCINewGame` or `UCIPosition` command.
"""
function start()
    if Threads.nthreads(:interactive) == 0
        # create two unbuffered channels for the inputs from and responses to the GUI
        uci_chan_in = Channel{UCICommandReceive}(0)
        uci_chan_out = Channel{UCICommandResponse}(0)
        # start a new interactive thread to listen for GUI commands
        Threads.@spawn :interactive uci_loop(uci_chan_in, uci_chan_out)

        init_sequence(uci_chan_in, uci_chan_out)

        return uci_chan_in, uci_chan_out
    else
        error("UCI already started?")
    end
end

"talk to the GUI over UCI stdin/sdtout inside an interactive thread"
function uci_loop(uci_chan_in::Channel{UCICommandReceive}, uci_chan_out::Channel{UCICommandResponse})
    while true
        if isready(uci_chan_out)
            response = take!(uci_chan_out)
            @assert response isa UCICommandResponse
            write_response(response)
        end

        line = readline()
        cmd = parse_uci(line)
        put!(uci_chan_in, cmd)
    end
end

end # module UCI