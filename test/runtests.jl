using FIGlet
using Test

EXCEPTIONS = [
              "3d.flf",
              "5x8.flf",
              "ANSI Regular.flf",
              "ANSI Shadow.flf",
              "Bloody.flf",
              "Calvin S.flf",
              "DOS Rebel.flf",
              "Delta Corps Priest 1.flf",
              "Diet Cola.flf",
              "Electronic.flf",
              "Elite.flf",
              "JS Cursive.flf",
              "Stronger Than All.flf",
              "THIS.flf",
              "The Edge.flf",
              "banner.flf",
              "bear.flf",
              "big.flf",
              "brite.flf",
              "briteb.flf",
              "britebi.flf",
              "britei.flf",
              "cns.flf",
              "cola.flf",
              "cour.flf",
              "courb.flf",
              "courbi.flf",
              "couri.flf",
              "dietcola.flf",
              "double.flf",
              "flipped.flf",
              "helv.flf",
              "helvb.flf",
              "helvbi.flf",
              "helvi.flf",
              "ivrit.flf",
              "jiskan16.flf",
              "knob.flf",
              "maxiwi.flf",
              "miniwi.flf",
              "nvscript.flf",
              "rotated.flf",
              "sans.flf",
              "sansb.flf",
              "sansbi.flf",
              "sansi.flf",
              "sbook.flf",
              "sbookb.flf",
              "sbookbi.flf",
              "sbooki.flf",
              "times.flf",
              "utopia.flf",
              "utopiab.flf",
              "utopiabi.flf",
              "utopiai.flf",
              "xbrite.flf",
              "xbriteb.flf",
              "xbritebi.flf",
              "xbritei.flf",
              "xcour.flf",
              "xcourb.flf",
              "xcourbi.flf",
              "xcouri.flf",
              "xhelv.flf",
              "xhelvb.flf",
              "xhelvbi.flf",
              "xhelvi.flf",
              "xsans.flf",
              "xsansb.flf",
              "xsansbi.flf",
              "xsansi.flf",
              "xsbook.flf",
              "xsbookb.flf",
              "xsbookbi.flf",
              "xsbooki.flf",
              "xtimes.flf",
              "xtty.flf",
              "xttyb.flf",
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
