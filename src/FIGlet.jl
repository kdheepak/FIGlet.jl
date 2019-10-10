module FIGlet

const DEFAULT_FONT = "standard"
const FONTFILESUFFIX = ".flf"
const FONTFILEMAGICNUMBER = "flf2"


abstract type FIGletError <: Exception end

"""
Width is not sufficient to print a character
"""
struct CharNotPrinted <: FIGletError end

"""
Font can't be located
"""
struct FontNotFound <: FIGletError end


"""
Problem parsing a font file
"""
struct FontError <: FIGletError end


"""
Color is invalid
"""
struct InvalidColor <: FIGletError end

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
struct FIGHeader
    hardblank::Char
    height::Int
    baseline::Int
    max_length::Int
    old_layout::Int
    comment_lines::Int
    print_direction::Int
    full_layout::Int
    codetag_count::Int

    function FIGHeader(hardblank, height, baseline, max_length, old_layout, comment_lines,
                       print_direction=0, full_layout=Int(HorizontalSmushingRule2), codetag_count=0
                      )
        new(hardblank, height, baseline, max_length, old_layout, comment_lines, print_direction, full_layout, codetag_count)
    end
end

function readmagic(io)
    magic = read(io, 5)
    # magic[1:4] != UInt8['f', 'l', 'f', '2'] && error("File is not a valid FIGlet Lettering Font format.")
    magic[5] != UInt8('a') && @warn "File may be a FLF format but not flf2a."
    return magic # File has valid FIGlet Lettering Font format magic header.
end

function readfont(io)
    magic = readmagic(io)

    header = split(readline(io))
    fig_header = FIGHeader(
                           header[1][1],
                           parse.(Int, header[2:end])...,
                          )
    for i in fig_header.comment_lines
        discard = readline(io)
    end

    return fig_header
end

end # module
