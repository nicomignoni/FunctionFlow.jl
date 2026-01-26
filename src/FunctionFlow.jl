module FunctionFlow

using LRUCache

export Node, Choice, base

abstract type AbstractNodeTrait end
abstract type ConcreteNodeTrait <: AbstractNodeTrait end

const AbstractNode = Union{AbstractNodeTrait,Symbol}
const ConcreteNode = Union{ConcreteNodeTrait,Symbol}

struct Node <: ConcreteNodeTrait
    f::Any
    args::Tuple{Vararg{AbstractNode}}
    kwargs::NamedTuple
    cache::LRU{UInt64,Any}

    function Node(f, args::AbstractNode...; cache_size::Int=1, kwargs...)
        @assert all(val isa AbstractNode for val in values(kwargs))
        kwargs_nt = NamedTuple(kwargs)
        cache = LRU{UInt64,Any}(maxsize=cache_size)
        new(f, args, kwargs_nt, cache)
    end
end

struct Choice <: AbstractNodeTrait
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

resolve(sym::Symbol, base, ::Any) = base[sym]
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

base(sym::Symbol, ::Any...) = [sym]
base(node::Node, selections::ConcreteNode...) =
    mapreduce(arg -> base(arg, selections...), (h, t) -> unique(vcat(h, t)), node.args)
base(choice::Choice, selections::ConcreteNode...) = 
    base(selection(choice, selections), selections...) 

# TODO: improve printing
function Base.show(io::IO, node::Node)
    print(io, "$(node |> typeof |> nameof)($(node.f |> nameof))")
end

function Base.show(io::IO, choice::Choice)
    print(io, "$(choice |> typeof |> nameof)($(join(choice.nodes, ", ")))")
end

end # module FunctionFlow
