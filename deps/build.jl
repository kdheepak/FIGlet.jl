using BinaryProvider
using Pkg

tarball_url = "https://github.com/kdheepak/FIGletFonts/archive/v0.5.0.tar.gz"
hash = "39f46c840ba035ba3b52aebf46123e6eda7393a7a18c5e6e02fb68c8cb50a33d"
prefix = Prefix(@__DIR__)

!isdefined(Pkg, :Artifacts) && !isinstalled(tarball_url, hash, prefix=prefix) && install(tarball_url, hash, prefix=prefix)
