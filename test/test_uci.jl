using Test

# Import the function to be tested
include("path/to/your/file.jl")

# Test parse_go function
@testset "parse_go" begin
    # Test case 1
    input = "go infinite"
    expected = UCIGo("infinite")
    @test parse_go(input) == expected

    # Add more test cases here...
end