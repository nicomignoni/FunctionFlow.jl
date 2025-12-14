module FunctionFlow

using LRUCache

export Node, Ambiguity, base

abstract type AbstractNodeTrait end
abstract type ConcreteNodeTrait <: AbstractNodeTrait end

const AbstractNode = Union{AbstractNodeTrait,Symbol}
const ConcreteNode = Union{ConcreteNodeTrait,Symbol}

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

resolve(sym::Symbol, base, ::Any) = base[sym]
resolve(node::Node, base, selections) = node(selections...; base...)
function resolve(ambiguity::Ambiguity, base, selections)
    selection = intersect(ambiguity.nodes, Set(selections))
    selection_size = length(selection)

    if selection_size > 1
        error("Inconsistent")
    elseif selection_size == 1
        return resolve(first(selection), base, selections)
    else
        if ambiguity.default === nothing
            error("No default and missing selection")
        else
            return resolve(ambiguity.default, base, selections)
        end
    end
end

function (node::Node)(selections::ConcreteNode...; base...)
    key = hash((base, selections))
    value = get!(node.cache, key) do
        args = Tuple(resolve(arg, base, selections) for arg in node.args)
        node.f(args...)
    end
    return value
end

base(sym::Symbol) = [sym]
base(node::Node) = mapreduce(base, (head, tail) -> vcat(head, tail) |> unique, node.args)

# TODO: figure out what is a `base` for an Ambiguity
base(ambiguity::Ambiguity) = [base(node) for node in ambiguity.nodes]

function Base.show(io::IO, node::Node)
    print(io, "$(typeof(node)) with base ($(join(base(node), ", ")))")
end

# TODO: figure out how to print Ambiguities
function Base.show(io::IO, ambiguity::Ambiguity)
    print(io, "$(typeof(ambiguity)) with Nodes ($(join(ambiguity.nodes, ", ")))")
end

end # module FunctionFlow
