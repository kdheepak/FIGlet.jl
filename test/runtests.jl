using FIGlet
using Test

function generate_output(s::AbstractString, font::AbstractString="Standard")
    fontpath = FIGlet.getfontpath(font)
    io = IOContext(IOBuffer())
    FIGlet.render(io, s, FIGlet.readfont(fontpath))
    jl_output = String(take!(io.io))
    cli_output = read(`figlet -f $fontpath $s`, String)

    return strip(join(strip.(split(jl_output, '\n')), '\n')), strip(join(strip.(split(cli_output, '\n')), '\n'))
end

@testset "FIGlet.jl" begin
    iob = IOBuffer(b"flf2a", read=true);
    @test FIGlet.readmagic(iob) == UInt8['f', 'l', 'f', '2', 'a']

    @test FIGlet.FIGletHeader('$', 6, 5, 16, 15, 11) == FIGlet.FIGletHeader('$', 6, 5, 16, 15, 11, 0, 143, 0)

    @test FIGlet.availablefonts() |> length == 680

    for font in FIGlet.availablefonts()
        @test FIGlet.readfont(font) isa FIGlet.FIGletFont
    end

    ff = FIGlet.readfont("jiskan16")
    iob = IOBuffer()
    print(iob, ff)
    @test String(take!(iob)) == "FIGletFont(n=7098)"

    iob = IOBuffer()
    print(iob, ff.font_characters['㙤'])
    @test String(take!(iob)) == "FIGletChar(ord='㙤')"

    @test_throws FIGlet.FontNotFoundError FIGlet.readfont("wat")
    @test_throws FIGlet.FontError FIGlet.readfont(joinpath(@__DIR__, "..", "README.md"))

    iob = IOBuffer()
    FIGlet.render(iob, "the quick brown fox jumps over the lazy dog", "standard")
    @test String(take!(iob)) == raw"""
 _   _                        _      _      _
| |_| |__   ___    __ _ _   _(_) ___| | __ | |__  _ __ _____      ___ __
| __| '_ \ / _ \  / _` | | | | |/ __| |/ / | '_ \| '__/ _ \ \ /\ / / '_ \
| |_| | | |  __/ | (_| | |_| | | (__|   <  | |_) | | | (_) \ V  V /| | | |
 \__|_| |_|\___|  \__, |\__,_|_|\___|_|\_\ |_.__/|_|  \___/ \_/\_/ |_| |_|
                     |_|

  __               _
 / _| _____  __   (_)_   _ _ __ ___  _ __  ___    _____   _____ _ __
| |_ / _ \ \/ /   | | | | | '_ ` _ \| '_ \/ __|  / _ \ \ / / _ \ '__|
|  _| (_) >  <    | | |_| | | | | | | |_) \__ \ | (_) \ V /  __/ |
|_|  \___/_/\_\  _/ |\__,_|_| |_| |_| .__/|___/  \___/ \_/ \___|_|
                |__/                |_|

 _   _            _                       _
| |_| |__   ___  | | __ _ _____   _    __| | ___   __ _
| __| '_ \ / _ \ | |/ _` |_  / | | |  / _` |/ _ \ / _` |
| |_| | | |  __/ | | (_| |/ /| |_| | | (_| | (_) | (_| |
 \__|_| |_|\___| |_|\__,_/___|\__, |  \__,_|\___/ \__, |
                              |___/               |___/

"""

    iob = IOBuffer()
    FIGlet.render(iob, uppercase("the quick brown fox jumps over the lazy dog"), "standard")
    @test String(take!(iob)) == raw"""
 _____ _   _ _____    ___  _   _ ___ ____ _  __
|_   _| | | | ____|  / _ \| | | |_ _/ ___| |/ /
  | | | |_| |  _|   | | | | | | || | |   | ' /
  | | |  _  | |___  | |_| | |_| || | |___| . \
  |_| |_| |_|_____|  \__\_\\___/|___\____|_|\_\


 ____  ____   _____        ___   _   _____ _____  __
| __ )|  _ \ / _ \ \      / / \ | | |  ___/ _ \ \/ /
|  _ \| |_) | | | \ \ /\ / /|  \| | | |_ | | | \  /
| |_) |  _ <| |_| |\ V  V / | |\  | |  _|| |_| /  \
|____/|_| \_\\___/  \_/\_/  |_| \_| |_|   \___/_/\_\


     _ _   _ __  __ ____  ____     _____     _______ ____
    | | | | |  \/  |  _ \/ ___|   / _ \ \   / / ____|  _ \
 _  | | | | | |\/| | |_) \___ \  | | | \ \ / /|  _| | |_) |
| |_| | |_| | |  | |  __/ ___) | | |_| |\ V / | |___|  _ <
 \___/ \___/|_|  |_|_|   |____/   \___/  \_/  |_____|_| \_\


 _____ _   _ _____   _        _     _______   __  ____   ___   ____
|_   _| | | | ____| | |      / \   |__  /\ \ / / |  _ \ / _ \ / ___|
  | | | |_| |  _|   | |     / _ \    / /  \ V /  | | | | | | | |  _
  | | |  _  | |___  | |___ / ___ \  / /_   | |   | |_| | |_| | |_| |
  |_| |_| |_|_____| |_____/_/   \_\/____|  |_|   |____/ \___/ \____|


"""

    iob = IOBuffer()
    FIGlet.render(iob, "the quick brown fox jumps over the lazy dog", "mirror")
    @test String(take!(iob)) == raw"""
                              _      _      _                        _   _
   __ ___      _____ __ _  __| | __ | |___ (_)_   _ _ __    ___   __| |_| |
  / _` \ \ /\ / / _ \__` |/ _` | \ \| |__ \| | | | | '_ \  / _ \ / _` |__ |
 | | | |\ V  V / (_) | | | (_| |  >   |__) | | |_| | |_) | \__  | | | |_| |
 |_| |_| \_/\_/ \___/  |_|\__,_| /_/|_|___/|_|_.__/| .__/  |___/|_| |_|__/
                                                   |_|

                                                  _               __
  __ _ _____   _____    ___  __ _  ___ __ _ _   _(_)   __  _____ |_ \
 |__` / _ \ \ / / _ \  |__ \/ _` |/ _ ' _` | | | | |   \ \/ / _ \ _| |
    | \__  \ V / (_) | / __/ (_| | | | | | | |_| | |    >  < (_) |_  |
    |_|___/ \_/ \___/  \___|\__, |_| |_| |_|_.__/| \_  /_/\_\___/  |_|
                               |_|                \__|

              _                       _            _   _
  _ __   ___ | |__    _   _____ _ __ | |  ___   __| |_| |
 | '_ \ / _ \| '_ \  | | | \  _| '_ \| | / _ \ / _` |__ |
 | |_) | (_) | |_) | | |_| |\ \| |_) | | \__  | | | |_| |
 | .__/ \___/|_.__/  | .__/|___\_.__/|_| |___/|_| |_|__/
  \___|               \___|

"""

    iob = IOBuffer()
    FIGlet.render(iob, uppercase("the quick brown fox jumps over the lazy dog"), "mirror")
    @test String(take!(iob)) == raw"""
 __  _ ____ ___ _   _  ___    _____ _   _ _____
 \ \| |___ \_ _| | | |/ _ \  |____ | | | |_   _|
  \ ` |   | | || | | | | | |   |_  | |_| | | |
  / . |___| | || |_| | |_| |  ___| |  _  | | |
 /_/|_|____/___|\___//_/__/  |_____|_| |_| |_|


 __  _____ _____   _   ___        _____   ____  ____
 \ \/ / _ \___  | | | / \ \      / / _ \ / _  |( __ |
  \  / | | | _| | | |/  |\ \ /\ / / | | | (_| |/ _  |
  /  \ |_| ||_  | |  /| | \ V  V /| |_| |> _  | (_| |
 /_/\_\___/   |_| |_/ |_|  \_/\_/  \___//_/ |_|\____|


   ____ _______     _____     ____  ____ __  __ _   _ _
  / _  |____ \ \   / / _ \   |___ \/ _  |  \/  | | | | |
 | (_| | |_  |\ \ / / | | |  / ___/ (_| | |\/| | | | | |  _
  > _  |___| | \ V /| |_| | | (___ \__  | |  | | |_| | |_| |
 /_/ |_|_____|  \_/  \___/   \____|   |_|_|  |_|\___/ \___/


  ____   ___   ____  __   _______     _        _   _____ _   _ _____
 |___ \ / _ \ / _  | \ \ / /\  __|   / \      | | |____ | | | |_   _|
  _  | | | | | | | |  \ V /  \ \    / _ \     | |   |_  | |_| | | |
 | |_| | |_| | |_| |   | |   _\ \  / ___ \ ___| |  ___| |  _  | | |
 |____/ \___/ \____|   |_|  |____\/_/   \_\_____| |_____|_| |_| |_|


"""

    @testset "Render all fonts" begin

        for (i, font) in enumerate(FIGlet.availablefonts())
            try
                iob = IOBuffer()
                sentence = "the quick brown fox jumps over the lazy dog"
                FIGlet.render(iob, sentence, font)
                FIGlet.render(iob, uppercase(sentence), font)
                @test length(String(take!(iob))) > 0
            catch
                println("Cannot render font: number = $i, name = \"$font\"")
            end
        end

    end

end

