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

```@raw html
<img src="assets/dag.svg" width="30%">
```

In order to calculate `k`, you need to compute `f`, `g`, and `h` first, which can be tedious and error-prone when the computational DAG grows. Since all these functions can be eventually expressed with respect to `a` and `b`, it would be more convenient to be able to write `f(a, b)` (or `h(a, b)`, for example). 

`FunctionFlow.jl` does exactly this: it allows you write a function as a `Node` of a computational DAG, which can be evaluated as a function of the `base` arguments.  

```@example QUICKSTART
using FunctionFlow

f_node = Node(f, :a)
g_node = Node(g, :a, :b)
h_node = Node(h, g_node, :b)
k_node = Node(k, f_node, h_node);
```

A `Node` automatically shows its dependency on `base` arguments

```@repl QUICKSTART
k_node
```

We can now pass `a` and `b` as keyword arguments to `k_node` to compute `k` without explicitly evaluating `h`, `g`, and `f` beforehand 

```@repl QUICKSTART 
k_node(a = 3, b = 2)
```

By recursively substituting `h`, `g`, and `f` in `k`, we can rewrite it as explicitly dependent on `a` and `b`

```@example QUICKSTART
k_explicit(a, b) = (b^2 - a + 4b) * (2a + 2);
```

```@repl QUICKSTART
k_explicit(3, 2) == k_node(a = 3, b = 2)
```

Each `Node` caches its value, based on the hashed `base`, in a [Least-Recently-Used cache](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_Recently_Used_(LRU)) provided by [`LRUCache.jl`](https://github.com/JuliaCollections/LRUCache.jl).

```@repl QUICKSTART
using LRUCache

cache_info(k_node.cache)
```

Default cache size is `1`, but it can be incremented by passing `cache_size` to the `Node` constructor. 

