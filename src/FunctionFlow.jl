module FunctionFlow

using LRUCache

export Node, base

struct Node
    f::Any
    args::Tuple{Vararg{Union{Node, Symbol}}}
    cache::LRU{UInt64, Any}

    function Node(f, args::Union{Node, Symbol}...; cache_size::Int=1)
        new(f, args, LRU{UInt64, Any}(maxsize=cache_size))
    end
end

resolve(node::Node, base) = node(; base...)
resolve(sym::Symbol, base) = base[sym]

function (node::Node)(; base...)
    key = hash(base)
    value = get!(node.cache, key) do
        args = Tuple(resolve(arg, base) for arg in node.args)
        node.f(args...)
    end
    return value
end

base(sym::Symbol) = [sym]
base(node::Node) = mapreduce(base, (head, tail) -> vcat(head, tail) |> unique, node.args)

function Base.show(io::IO, node::Node)
    print(io, "$(typeof(node)) with base ($(join(base(node), ", ")))")
end

end # module FunctionFlow
