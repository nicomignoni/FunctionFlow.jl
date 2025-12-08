using Documenter, FunctionFlow

makedocs(
    sitename="FunctionFlow.jl",
    pages=[
        "Home" => "index.md",
    ],
    format = Documenter.HTML(
        edit_link="master",
        assets=["assets/favicon.ico"]
    ),
    repo=Remotes.GitHub("nicomignoni", "FunctionFlow.jl"),
)

deploydocs(
    repo = "github.com/nicomignoni/FunctionFlow.jl.git",
)
