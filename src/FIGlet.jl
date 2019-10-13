module FIGlet

using Pkg.Artifacts
import Base

const FONTSDIR = abspath(normpath(joinpath(artifact"fonts", "FIGletFonts-0.3.0", "fonts")))
const UNPARSEABLES = [
              "nvscript.flf",
             ]


abstract type FIGletError <: Exception end

"""
Width is not sufficient to print a character
"""
struct CharNotPrinted <: FIGletError end

"""
Font can't be located
"""
struct FontNotFoundError <: FIGletError
    msg::String
end

Base.showerror(io::IO, e::FontNotFoundError) = print(io, "FontNotFoundError: $(e.msg)")

"""
Problem parsing a font file
"""
struct FontError <: FIGletError
    msg::String
end

Base.showerror(io::IO, e::FontError) = print(io, "FontError: $(e.msg)")


"""
Color is invalid
"""
struct InvalidColorError <: FIGletError end

Base.@enum(Layout,
    FullWidth                   =       -1,
    HorizontalSmushingRule1     =        1,
    HorizontalSmushingRule2     =        2,
    HorizontalSmushingRule3     =        4,
    HorizontalSmushingRule4     =        8,
    HorizontalSmushingRule5     =       16,
    HorizontalSmushingRule6     =       32,
    HorizontalFitting           =       64,
    HorizontalSmushing          =      128,
    VerticalSmushingRule1       =      256,
    VerticalSmushingRule2       =      512,
    VerticalSmushingRule3       =     1024,
    VerticalSmushingRule4       =     2048,
    VerticalSmushingRule5       =     4096,
    VerticalFitting             =     8192,
    VerticalSmushing            =    16384,
)


raw"""
THE HEADER LINE

The header line gives information about the FIGfont.  Here is an example
showing the names of all parameters:

          flf2a$ 6 5 20 15 3 0 143 229    NOTE: The first five characters in
            |  | | | |  |  | |  |   |     the entire file must be "flf2a".
           /  /  | | |  |  | |  |   \
  Signature  /  /  | |  |  | |   \   Codetag_Count
    Hardblank  /  /  |  |  |  \   Full_Layout*
         Height  /   |  |   \  Print_Direction
         Baseline   /    \   Comment_Lines
          Max_Length      Old_Layout*

  * The two layout parameters are closely related and fairly complex.
      (See "INTERPRETATION OF LAYOUT PARAMETERS".)

"""
struct FIGletHeader
    hardblank::Char
    height::Int
    baseline::Int
    max_length::Int
    old_layout::Int
    comment_lines::Int
    print_direction::Int
    full_layout::Int
    codetag_count::Int

    function FIGletHeader(
                          hardblank,
                          height,
                          baseline,
                          max_length,
                          old_layout,
                          comment_lines,
                          print_direction=0,
                          full_layout=Int(HorizontalSmushingRule2),
                          codetag_count=0,
                          args...,
                      )
        length(args) >0 && @warn "Received unknown header attributes: `$args`."
        height < 1 && ( height = 1 )
        max_length < 1 && ( max_length = 1 )
        print_direction < 0 && ( print_direction = 0 )
        # max_length += 100 # Give ourselves some extra room
        new(hardblank, height, baseline, max_length, old_layout, comment_lines, print_direction, full_layout, codetag_count)
    end
end

function FIGletHeader(
                      hardblank,
                      height::AbstractString,
                      baseline::AbstractString,
                      max_length::AbstractString,
                      old_layout::AbstractString,
                      comment_lines::AbstractString,
                      print_direction::AbstractString="0",
                      full_layout::AbstractString="2",
                      codetag_count::AbstractString="0",
                      args...,
                     )
    return FIGletHeader(
                        hardblank,
                        parse(Int, height),
                        parse(Int, baseline),
                        parse(Int, max_length),
                        parse(Int, old_layout),
                        parse(Int, comment_lines),
                        parse(Int, print_direction),
                        parse(Int, full_layout),
                        parse(Int, codetag_count),
                        args...,
                       )
end

struct FIGletChar
    ord::Char
    thechar::Matrix{Char}
end

struct FIGletFont
    header::FIGletHeader
    font_characters::Dict{Char,FIGletChar}
    version::VersionNumber
end

Base.show(io::IO, ff::FIGletFont) = print(io, "FIGletFont(n=$(length(ff.font_characters)))")

function readmagic(io)
    magic = read(io, 5)
    magic[1:4] != UInt8['f', 'l', 'f', '2'] && throw(FontError("File is not a valid FIGlet Lettering Font format. Magic header values must start with `flf2`."))
    magic[5] != UInt8('a') && @warn "File may be a FLF format but not flf2a."
    return magic # File has valid FIGlet Lettering Font format magic header.
end

function readfontchar(io, ord, height)

    s = readline(io)
    width = length(s)-1
    width == -1 && throw(FontError("Unable to find character `$ord` in FIGlet Font."))
    thechar = Matrix{Char}(undef, height, width)

    for (w, c) in enumerate(s)
        w > width && break
        thechar[1, w] = c
    end

    for h in 2:height
        s = readline(io)
        for (w, c) in enumerate(s)
            w > width && break
            thechar[h, w] = c
        end
    end

    return FIGletChar(ord, thechar)
end

Base.show(io::IO, fc::FIGletChar) = print(io, "FIGletChar(ord='$(fc.ord)')")

function readfont(s::AbstractString)
    name = s
    if !isfile(name)
        name = abspath(normpath(joinpath(FONTSDIR, name)))
        if !isfile(name)
            name = "$name.flf"
            !isfile(name) && throw(FontNotFoundError("Cannot find font `$s`."))
        end
    end

    font = open(name) do f
        readfont(f)
    end
    return font
end

function readfont(io)
    magic = readmagic(io)

    header = split(readline(io))
    fig_header = FIGletHeader(
                           header[1][1],
                           header[2:end]...,
                          )

    for i in 1:fig_header.comment_lines
        discard = readline(io)
    end

    fig_font = FIGletFont(
                          fig_header,
                          Dict{Char, FIGletChar}(),
                          v"2.0.0",
                         )

    for c in ' ':'~'
        fig_font.font_characters[c] = readfontchar(io, c, fig_header.height)
    end

    for c in ['Ä', 'Ö', 'Ü', 'ä', 'ö', 'ü', 'ß']
        if bytesavailable(io) > 1
            fig_font.font_characters[c] = readfontchar(io, c, fig_header.height)
        end
    end

    while bytesavailable(io) > 1
        s = readline(io)
        strip(s) == "" && continue
        s = split(s)[1]
        c = if '-' in s
            Char(-(parse(UInt16, strip(s, '-'))))
        else
            Char(parse(Int, s))
        end
        fig_font.font_characters[c] = readfontchar(io, c, fig_header.height)
    end

    return fig_font
end

function availablefonts(substring)
    fonts = String[]
    for (root, dirs, files) in walkdir(FONTSDIR)
        for file in files
            if !(file in UNPARSEABLES)
                if occursin(substring, lowercase(file)) || substring == ""
                    push!(fonts, replace(file, ".flf"=>""))
                end
            end
        end
    end
    sort!(fonts)
    return fonts
end

availablefonts() = availablefonts("")

function render(io, text::AbstractString, font::FIGletFont)

    iob = IOBuffer()

    fig_chars = FIGletChar[]

    for c in text
        fc = font.font_characters[c]
        push!(fig_chars, fc)
    end

    for r in 1:font.header.height
        for fc in fig_chars
            print(iob, join(fc.thechar[r, :]))
        end
        print(iob, '\n')
    end

    print(io, replace(String(take!(iob)), font.header.hardblank=>' '))
end

render(text::AbstractString, font::FIGletFont) = render(stdout, text, font)
render(text::AbstractString, font::AbstractString="Standard") = render(text, readfont(font))


end # module
