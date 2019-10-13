using FIGlet
using Test

@testset "FIGlet.jl" begin
    iob = IOBuffer(b"flf2a", read=true);
    @test FIGlet.readmagic(iob) == UInt8['f', 'l', 'f', '2', 'a']

    @test FIGlet.FIGletHeader('$', 6, 5, 16, 15, 11) == FIGlet.FIGletHeader('$', 6, 5, 16, 15, 11, 0, 2, 0)

    @test FIGlet.availablefonts() |> length == 760

    for font in FIGlet.availablefonts()
        @test FIGlet.readfont(font) isa FIGlet.FIGletFont
    end

end
