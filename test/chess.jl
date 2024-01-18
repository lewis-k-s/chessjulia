const IO_IN = IOBuffer()
const IO_OUT = IOBuffer()

@testset "Chess Tests" begin
    @testset "UCI initialisation sequence" begin
        @debug "CHESS TEST LOG"
        # start the engine. Run async so that the engine loop doesn't block the test thread
        @async start(Settings(IO_IN, IO_OUT))
        write(IO_IN, "uci\n")
        @debug "wrote uci"
        # wait for the engine to respond
        sleep(0.01)

        response = String(take!(IO_OUT))
        @test startswith(response, "id name")

        yield()
        response = readline(IO_OUT)
        @test startswith(response, "id author")

        yield()
        response = readline(IO_OUT)
        @test startswith(response, "option")

        write(IO_IN, "isready\n")
        sleep(0.01)

        response = String(take!(IO_OUT))
        @test response == "readyok\n"

        write(IO_IN, "quit\n")
    end

    # @testset "search function Tests" begin
    #     game = Game()  # Replace with actual game initialization
    #     search_progress = Search(game)  # Replace with actual Search initialization
    #     @test search(game, search_progress) == search_progress
    # end

    # @testset "setpos function Tests" begin
    #     @testset "for startpos" begin
    #         game = setpos("startpos")
    #         @test game != nothing  # Replace with actual game comparison
    #     end

    #     @testset "for other positions" begin
    #         game = setpos("other position")  # Replace with actual FEN string
    #         @test game != nothing  # Replace with actual game comparison
    #     end
    # end

end
