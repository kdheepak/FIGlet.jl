using Documenter, FIGlet

makedocs(;
    modules=[FIGlet],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/kdheepak/FIGlet.jl/blob/{commit}{path}#L{line}",
    sitename="FIGlet.jl",
    authors="Dheepak Krishnamurthy",
    assets=String[],
)

deploydocs(;
    repo="github.com/kdheepak/FIGlet.jl",
)
