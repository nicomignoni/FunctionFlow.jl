# FunctionFlow.jl 

*Automatic lazy dependency resolution for computational DAGs in Julia.*

## Installation
Install `FunctionFlow.jl` from the Julia REPL

```julia
add ] https://github.com/nicomignoni/FunctionFlow.jl.git
```

## Quickstart
Suppose you wrote a mathematical model characterized by the following functions
```@example QUICKSTART
f(a) = 2a + 3
g(a, b) = b^2 - a
h(g, b) = g + 4b
k(f, h) = h * (f - 1)
```
Some function arguments are themselves functions; this dependency can be expressed through a directed acycilc graph (DAG) as follows

<img src="assets/dag.svg" width="30%">

In order to calculate `k`, you need to compute `f`, `g`, and `h` first, which can be tedious and error-prone when the computational DAG grows. Since all these functions can be eventually expressed with respect to `a` and `b`, it would be more convenient to be able to write `f(a, b)` (or `g(a, b)`, for example). 

`FunctionFlow.jl` does exactly this: it allows you write a function as a `Node` of a computational DAG, which can be evaluated as a function of the `base` arguments.  

```@example QUICKSTART
using FunctionFlow

f_node = Node(f, :a)
g_node = Node(g, :a, :b)
h_node = Node(h, g_node, :b)
k_node = Node(k, f_node, h_node)
```

A `Node` automatically shows its dependency on `base` arguments
```@repl
k_node
```
