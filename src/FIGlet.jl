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


end # module
