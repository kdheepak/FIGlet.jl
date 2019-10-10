using FIGlet
using Test

@testset "FIGlet.jl" begin
    iob = IOBuffer(b"flf2a", read=true);
    @test FIGlet.is_valid_magic_header(iob)
end
