module FIGlet

using Pkg.Artifacts
import Base

const FONTSDIR = abspath(normpath(joinpath(artifact"fonts", "FIGletFonts-0.5.0", "fonts")))
const UNPARSEABLES = [
              "nvscript.flf",
             ]
const DEFAULTFONT = "Standard"


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
                          full_layout=-2,
                          codetag_count=0,
                          args...,
                      )
        length(args) >0 && @warn "Received unknown header attributes: `$args`."
        if full_layout == -2
            full_layout = old_layout
            if full_layout == 0
                full_layout = Int(HorizontalFitting)
            elseif full_layout == -1
                full_layout = 0
            else
                full_layout = ( full_layout & 63 ) | Int(HorizontalSmushing)
            end
        end
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
                      full_layout::AbstractString="-2",
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

function getfontpath(s::AbstractString)
    name = s
    if !isfile(name)
        name = abspath(normpath(joinpath(FONTSDIR, name)))
        if !isfile(name)
            name = "$name.flf"
            !isfile(name) && throw(FontNotFoundError("Cannot find font `$s`."))
        end
    end
    return name
end

function readfont(s::AbstractString)
    name = getfontpath(s)
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

    while !eof(io)
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
                if occursin(lowercase(substring), lowercase(file)) || substring == ""
                    push!(fonts, replace(file, ".flf"=>""))
                end
            end
        end
    end
    sort!(fonts)
    return fonts
end

"""
    availablefonts() -> Vector{String}
    availablefonts(substring::AbstractString) -> Vector{String}

Returns all available fonts.
If `substring` is passed, returns available fonts that contain the case insensitive `substring`.

Example:

    julia> availablefonts()
    680-element Array{String,1}:
     "1943____"
     "1row"
     ⋮
     "zig_zag_"
     "zone7___"

    julia> FIGlet.availablefonts("3d")
    5-element Array{String,1}:
     "3D Diagonal"
     "3D-ASCII"
     "3d"
     "Henry 3D"
     "Larry 3D"

    julia>
"""
availablefonts() = availablefonts("")


raw"""

    smushem(lch::Char, rch::Char, fh::FIGletHeader) -> Char

Given 2 characters, attempts to smush them into 1, according to
smushmode.  Returns smushed character or '\0' if no smushing can be
done.

smushmode values are sum of following (all values smush blanks):
    1: Smush equal chars (not hardblanks)
    2: Smush '_' with any char in hierarchy below
    4: hierarchy: "|", "/\", "[]", "{}", "()", "<>"
       Each class in hier. can be replaced by later class.
    8: [ + ] -> |, { + } -> |, ( + ) -> |
    16: / + \ -> X, > + < -> X (only in that order)
    32: hardblank + hardblank -> hardblank

"""
function smushem(lch::Char, rch::Char, fh::FIGletHeader)

    smushmode = fh.full_layout
    hardblank = fh.hardblank
    right2left = fh.print_direction

    lch==' ' && return rch
    rch==' ' && return lch

    # TODO: Disallow overlapping if the previous character or the current character has a width of 0 or 1
    # if previouscharwidth < 2 || currcharwidth < 2 return '\0' end

    if ( smushmode & Int(HorizontalSmushing::Layout) ) == 0 return '\0' end

    if ( smushmode & 63 ) == 0
        # This is smushing by universal overlapping.

        # Ensure overlapping preference to visible characters.
        if lch == hardblank return rch end
        if rch == hardblank return lch end

        # Ensures that the dominant (foreground) fig-character for overlapping is the latter in the user's text, not necessarily the rightmost character.
        if right2left == 1 return lch end

        # Catch all exceptions
        return rch
    end

    if smushmode & Int(HorizontalSmushingRule6::Layout) != 0
        if lch == hardblank && rch == hardblank return lch end
    end

    if lch == hardblank || rch == hardblank return '\0' end

    if smushmode & Int(HorizontalSmushingRule1::Layout) != 0
        if lch == rch return lch end
    end

    if smushmode & Int(HorizontalSmushingRule2::Layout) != 0
        if lch == '_' && rch in "|/\\[]{}()<>" return rch end
        if rch == '_' && lch in "|/\\[]{}()<>" return lch end
    end

    if smushmode & Int(HorizontalSmushingRule3::Layout) != 0
        if lch == '|' && rch in "/\\[]{}()<>" return rch end
        if rch == '|' && lch in "/\\[]{}()<>" return lch end
        if lch in "/\\" && rch in "[]{}()<>" return rch end
        if rch in "/\\" && lch in "[]{}()<>" return lch end
        if lch in "[]" && rch in "{}()<>" return rch end
        if rch in "[]" && lch in "{}()<>" return lch end
        if lch in "{}" && rch in "()<>" return rch end
        if rch in "{}" && lch in "()<>" return lch end
        if lch in "()" && rch in "<>" return rch end
        if rch in "()" && lch in "<>" return lch end
    end

    if smushmode & Int(HorizontalSmushingRule4::Layout) != 0
        if lch == '[' && rch == ']' return '|' end
        if rch == '[' && lch == ']' return '|' end
        if lch == '{' && rch == '}' return '|' end
        if rch == '{' && lch == '}' return '|' end
        if lch == '(' && rch == ')' return '|' end
        if rch == '(' && lch == ')' return '|' end
    end

    if smushmode & Int(HorizontalSmushingRule5::Layout) != 0
        if lch == '/' && rch == '\\' return '|' end
        if rch == '/' && lch == '\\' return 'Y' end

        # Don't want the reverse of below to give 'X'.
        if lch == '>' && rch == '<' return 'X' end
    end

    return '\0'

end

function smushamount(current::Matrix{Char}, thechar::Matrix{Char}, fh::FIGletHeader)

    smushmode = fh.full_layout
    right2left = fh.print_direction

    if (smushmode & (Int(HorizontalSmushing::Layout) | Int(HorizontalFitting::Layout)) == 0)
        return 0
    end

    nrows_l, ncols_l = size(current)
    _, ncols_r = size(thechar)

    maximum_smush = ncols_r
    smush = ncols_l

    for row in 1:nrows_l

        cl = '\0'
        cr = '\0'
        linebd = 0
        charbd = 0
        if right2left == 1
            if maximum_smush > ncols_l
                maximum_smush = ncols_l
            end

            for col_r in ncols_r:-1:1
                cr = thechar[row, col_r]
                if cr == ' '
                    charbd += 1
                    continue
                else
                    break
                end
            end
            for col_l in 1:ncols_l
                cl = current[row, col_l]
                if cl == '\0' || cl == ' '
                    linebd += 1
                    continue
                else
                    break
                end
            end
        else
            for col_l in ncols_l:-1:1
                cl = current[row, col_l]
                if col_l > 1 && ( cl == '\0' || cl == ' ' )
                    linebd += 1
                    continue
                else
                    break
                end
            end

            for col_r in 1:ncols_r
                cr = thechar[row, col_r]
                if cr == ' '
                    charbd += 1
                    continue
                else
                    break
                end
            end
        end

        smush = linebd + charbd

        if cl == '\0' || cl == ' '
            smush += 1
        elseif (cr != '\0')
            if smushem(cl, cr, fh) != '\0'
                smush += 1
            end
        end

        if smush < maximum_smush
            maximum_smush = smush
        end
    end
    return maximum_smush
end

function addchar(current::Matrix{Char}, thechar::Matrix{Char}, fh::FIGletHeader)

    right2left = fh.print_direction

    current = copy(current)
    thechar = copy(thechar)
    maximum_smush = smushamount(current, thechar, fh)

    _, ncols_l = size(current)
    nrows_r, ncols_r = size(thechar)

    for row in 1:nrows_r
        if right2left == 1
            for smush in 1:maximum_smush
                col_r = ncols_r - maximum_smush + smush
                col_r < 1 && ( col_r = 1 )
                thechar[row, col_r] = smushem(thechar[row, col_r], current[row, smush], fh)
            end
        else
            for smush in 1:maximum_smush
                col_l = ncols_l - maximum_smush + smush
                col_l < 1 && ( col_l = 1 )
                current[row, col_l] = smushem(current[row, col_l], thechar[row, smush], fh)
            end
        end

    end
    if right2left == 1
        current = hcat(
                       thechar,
                       current[:, ( maximum_smush + 1 ):end],
                      )

    else
        current = hcat(
                       current,
                       thechar[:, ( maximum_smush + 1 ):end],
                      )
    end

    return current

end

function render(io, text::AbstractString, ff::FIGletFont)
    (HEIGHT, WIDTH) = Base.displaysize(io)

    words = Matrix{Char}[]
    for word in split(text)
        current = fill(' ', ff.header.height, 1)
        for c in word
            current = addchar(current, ff.font_characters[c].thechar, ff.header)
        end
        current = addchar(current, ff.font_characters[' '].thechar, ff.header)
        push!(words, current)
    end

    lines = Matrix{Char}[]
    current = fill('\0', ff.header.height, 0)
    for word in words
        if size(current)[2] + size(word)[2] < WIDTH
            if ff.header.print_direction == 1
                current = hcat(word, current)
            else
                current = hcat(current, word)
            end
        else
            push!(lines, current)
            current = fill('\0', ff.header.height, 0)
            if ff.header.print_direction == 1
                current = hcat(word, current)
            else
                current = hcat(current, word)
            end
        end
    end
    push!(lines, current)

    for line in lines
        nrows, ncols = size(line)
        for r in 1:nrows
            s = join(line[r, :])
            s = replace(s, ff.header.hardblank=>' ') |> rstrip
            print(io, s)
            print(io, '\n')
        end
        print(io, '\n')
    end

end

render(io, text::AbstractString, ff::AbstractString) = render(io, text, readfont(ff))

"""
    render(text::AbstractString, font::Union{AbstractString, FIGletFont})

Renders `text` using `font` to `stdout`

Example:

    render("hello world", "standard")
    render("hello world", readfont("standard"))
"""
render(text::AbstractString, font=DEFAULTFONT) = render(stdout, text, font)

end # module
