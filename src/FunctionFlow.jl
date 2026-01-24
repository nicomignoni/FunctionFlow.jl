module FunctionFlow

using LRUCache

export Node, Ambiguity, base

abstract type AbstractNodeTrait end
abstract type ConcreteNodeTrait <: AbstractNodeTrait end

const AbstractNode = Union{AbstractNodeTrait, Symbol}
const ConcreteNode = Union{ConcreteNodeTrait, Symbol}

struct Node <: ConcreteNodeTrait
    f::Any
    args::Tuple{Vararg{AbstractNode}}
    cache::LRU{UInt64,Any}

    function Node(f, args::AbstractNode...; cache_size::Int=1)
        new(f, args, LRU{UInt64,Any}(maxsize=cache_size))
    end
end

struct Ambiguity <: AbstractNodeTrait
    nodes::Set{ConcreteNode}
    default::Union{Nothing,ConcreteNode}

    Ambiguity(nodes::ConcreteNode...; default::Union{Nothing,ConcreteNode}=nothing) =
        new(Set(nodes), default)
end

function (node::Node)(selections::ConcreteNode...; base...)
    key = hash((selections, base))
    value = get!(node.cache, key) do
        args = Tuple(resolve(arg, base, selections) for arg in node.args)
        node.f(args...)
    end
    return value
end

function selection(ambiguity::Ambiguity, selections::Tuple{Vararg{ConcreteNode}})
    selection = intersect(ambiguity.nodes, Set(selections))
    selection_size = length(selection)
    if selection_size > 1 
        error("Nodes $selection can not be simultaneously selected for $ambiguity.")
    elseif selection_size == 1
        return first(selection)
    else 
        return ambiguity.default === nothing ? 
               error("No Node among $selections is a Node for $ambiguity") : 
               ambiguity.default
    end
end

resolve(sym::Symbol, base, ::Any) = base[sym]
resolve(node::Node, base, selections) = node(selections...; base...)
resolve(ambiguity::Ambiguity, base, selections) = resolve(selection(ambiguity, selections), base, selections)

base(sym::Symbol, ::Any...) = [sym]
base(node::Node, selections::ConcreteNode...) =
    mapreduce(arg -> base(arg, selections...), (h, t) -> unique(vcat(h, t)), node.args)
base(ambiguity::Ambiguity, selections::ConcreteNode...) = 
    base(selection(ambiguity, selections), selections...) 

# TODO: improve printing
function Base.show(io::IO, node::Node)
    print(io, "$(typeof(node))($(nameof(node.f)); $(join(node.args, ", ")))")
end

function Base.show(io::IO, ambiguity::Ambiguity)
    print(io, "$(typeof(ambiguity))($(join(ambiguity.nodes, ", ")))")
end

end # module FunctionFlow
