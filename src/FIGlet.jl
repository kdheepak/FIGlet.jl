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
    old_layout::Layout
    comment_lines::Int
    print_direction::Int
    full_layout::Layout
    codetag_count::Int
end

function is_valid_magic_header(io)
    magic = read(io, 4)
    magic != UInt8['f', 'l', 'f', '2'] && return false # File is not a valid FIGlet Lettering Font format."

    b = read(io, 1)
    b != UInt8('a') || @warn "File is a FLF format but not flf2a."

    return true # File has valid FIGlet Lettering Font format magic header.
end

end # module
