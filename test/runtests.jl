using Test, FunctionFlow

f(a) = 2a + 3
g(a, b) = b^2 - a
h(g, b) = g + 4b
k(f, h) = h * (f - 1)

f_node = Node(f, :a)
g_node = Node(g, :a, :b)
h_node = Node(h, g_node, :b)
k_node = Node(k, f_node, h_node)

k_explicit(a, b) = (b^2 - a + 4b) * (2a + 2)

@assert k_node(a = 3, b = 2) == k_explicit(3, 2)
