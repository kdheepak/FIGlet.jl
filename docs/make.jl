using Documenter, Figlet

makedocs(;
    modules=[Figlet],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/kdheepak/Figlet.jl/blob/{commit}{path}#L{line}",
    sitename="Figlet.jl",
    authors="Dheepak Krishnamurthy",
    assets=String[],
)

deploydocs(;
    repo="github.com/kdheepak/Figlet.jl",
)
