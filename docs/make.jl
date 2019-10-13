using Documenter, FIGlet, DocumenterMarkdown

cp(joinpath(@__DIR__, "../README.md"), joinpath(@__DIR__, "./src/index.md"), force=true, follow_symlinks=true)

makedocs(
         sitename="FIGlet.jl documentation",
         format = Markdown()
        )

deploydocs(;
    repo="github.com/kdheepak/FIGlet.jl",
    deps = Deps.pip(
                   "mkdocs==0.17.5",
                   "mkdocs-material==2.9.4",
                   "python-markdown-math",
                   "pygments",
                   "pymdown-extensions",
                   ),
    make = () -> run(`mkdocs build`),
    target = "site",
)
