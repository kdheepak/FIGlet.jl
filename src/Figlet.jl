module Figlet

const DEFAULT_FONT = "standard"

Base.@enum COLOR_CODES BLACK=30 RED=31 GREEN=32 YELLOW=33 BLUE=34 MAGENTA=35 CYAN=36 LIGHT_GRAY=37 DEFAULT=39 DARK_GRAY=90 LIGHT_RED=91 LIGHT_GREEN=92 LIGHT_YELLOW= 93 LIGHT_BLUE= 94 LIGHT_MAGENTA=95 LIGHT_CYAN=96 WHITE=97 RESET=0

const RESET_COLORS = "\033[0m"

const SHARED_DIRECTORY = "figlet"


function figlet_format(text, font=DEFAULT_FONT)
    fig = Figlet(font)
    return render_text(fig, text)
end

function print_figlet(text, font=DEFAULT_FONT, colors=":")
    ansiColors = parse_color(colors)
    if ansiColors:
        print(stdout, ansiColors))
    end

    println(figlet_format(text, font))

    if ansiColors:
        print(stdout, RESET_COLORS.decode('UTF-8', 'replace'))
        flush(stdout)
    end
end


abstract type FigletException <: Exception end

"""
Width is not sufficient to print a character
"""
struct CharNotPrinted <: FigletError end

"""
Font can't be located
"""
struct FontNotFound <: FigletError end


"""
Problem parsing a font file
"""
struct FontError <: FigletError end


"""
Color is invalid
"""
struct InvalidColor <: FigletError end


end # module
