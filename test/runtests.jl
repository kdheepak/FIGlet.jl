using FIGlet
using Test

EXCEPTIONS = [
              "nvscript.flf",
             ]


@testset "FIGlet.jl" begin
    iob = IOBuffer(b"flf2a", read=true);
    @test FIGlet.readmagic(iob) == UInt8['f', 'l', 'f', '2', 'a']

    @test FIGlet.FIGletHeader('$', 6, 5, 16, 15, 11) == FIGlet.FIGletHeader('$', 6, 5, 16, 15, 11, 0, 2, 0)

    for (root, dirs, files) in walkdir(FIGlet.FONTS)
        for file in files
            if endswith(file, ".flf") && !any(occursin.(file, EXCEPTIONS))
                open(joinpath(root, file)) do f
                    @test FIGlet.readfont(f) isa FIGlet.FIGletFont
                end
            end
        end
    end

end
