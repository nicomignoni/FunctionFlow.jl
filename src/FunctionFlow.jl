module FunctionFlow

using LRUCache

export @root, @roots, Node, Choice, base

abstract type AbstractNode end
abstract type ConcreteNode <: AbstractNode end

struct Root <: ConcreteNode 
    sym::Symbol
end

macro root(term) 
    return :( $(esc(term)) = $(Root(term)) ) 
end

# TODO: use @root in the comprehension
macro roots(terms...)
    exprs = [:( $(esc(term)) = $(Root(term)) ) for term in terms]
    return Expr(:block, exprs...)
end

struct Node{A<:Tuple, K<:NamedTuple} <: ConcreteNode
    f::Any
    args::A
    kwargs::K
    cache::LRU{UInt64,Any}

    function Node(f, args...; cache_size::Int=1, kwargs...)
        @assert all(arg isa AbstractNode for arg in args)
        @assert all(val isa AbstractNode for val in values(kwargs))
        kwargs_nt = NamedTuple(kwargs)
        cache = LRU{UInt64,Any}(maxsize=cache_size)
        new{typeof(args), typeof(kwargs_nt)}(f, args, kwargs_nt, cache)
    end
end

struct Choice <: AbstractNode
    nodes::Set{ConcreteNode}
    default::Union{Nothing,ConcreteNode}

    Choice(nodes::ConcreteNode...; default::Union{Nothing,ConcreteNode}=nothing) =
        new(Set(nodes), default)
end

function (node::Node)(selections::ConcreteNode...; base...)
    key = hash((selections, base))
    value = get!(node.cache, key) do
        args = Tuple(resolve(arg, base, selections) for arg in node.args)
        kwargs = NamedTuple(key => resolve(val, base, selections) for (key, val) in pairs(node.kwargs))
        node.f(args...; kwargs...)
    end
    return value
end

resolve(root::Root, base, ::Any) = base[root.sym]
resolve(node::Node, base, selections) = node(selections...; base...)
resolve(choice::Choice, base, selections) = resolve(selection(choice, selections), base, selections)

function selection(choice::Choice, selections::Tuple{Vararg{ConcreteNode}})
    selection = intersect(choice.nodes, Set(selections))
    selection_size = length(selection)
    if selection_size > 1 
        error("Nodes $selection can not be simultaneously selected for $choice.")
    elseif selection_size == 1
        return first(selection)
    else 
        return choice.default === nothing ? 
               error("No Node among $selections is a Node for $choice") : 
               choice.default
    end
end

base(root::Root, ::Any...) = [root]
base(node::Node, selections::ConcreteNode...) =
    mapreduce(arg -> base(arg, selections...), (h, t) -> unique(vcat(h, t)), node.args)
base(choice::Choice, selections::ConcreteNode...) = 
    base(selection(choice, selections), selections...) 

# TODO: improve printing
function Base.show(io::IO, root::Root)
    print(io, "$(root |> typeof |> nameof)($(root.sym))")
end

function Base.show(io::IO, node::Node)
    print(io, "$(node |> typeof |> nameof)($(node.f |> nameof))")
end

function Base.show(io::IO, choice::Choice)
    print(io, "$(choice |> typeof |> nameof)($(join(choice.nodes, ", ")))")
end

end # module FunctionFlow
