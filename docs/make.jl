using Documenter, Surrogates
makedocs(
    sitename="Surrogates.jl",
    pages = [
    "index.md"
    "Tutorials" => [
        "Basics" => "tutorials.md",
        "Radials" => "radials.md",
        "Kriging" => "kriging.md",
        "Lobachesky" => "lobachesky.md",
        "Linear" => "LinearSurrogate.md",
        "InverseDistance" => "InverseDistance.md",
        "RandomForest" => "randomforest.md",
        "SecondOrderPolynomial" => "secondorderpoly.md"
        ]
    "User guide" => [
        "Samples" => "samples.md",
        "Surrogates" => "surrogate.md",
        "Optimization" => "optimizations.md"
        ]
    "Benchmarks" => [
        "Sphere function" => "sphere_function.md",
        "Lp norm" => "lp.md",
        "Rosenbrock" => "rosenbrock.md",
        "Tensor product" => "tensor_prod.md",
        "Cantilever beam" => "cantilever.md",
        "Water Flow function" => "water_flow.md",
        "Welded beam function" => "welded_beam.md",
        "Branin function" => "BraninFunction.md",
        "Ackley function" => "ackley.md",
        "Gramacy & Lee Function" => "gramacylee.md"
        ]
    "Contributing" => "contributing.md"
    ]
)


deploydocs(
   repo = "github.com/SciML/Surrogates.jl.git",
)
