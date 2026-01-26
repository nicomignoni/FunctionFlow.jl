using Test, FunctionFlow

# Model
g(a, b; e=3) = b^2 - e*a
h(g, b) = g + 4b

m1(e) = log(1 + e)
m2(e) = sin(e)

f1(a) = 2a + 3
f2(b, m) = 2.3m + b

k(f, h) = h * (f - 1)

# DAG
@roots a b d e

g_node = Node(g, a, b; e)
h_node = Node(h, g_node, b)

m1_node = Node(m1, d)
m2_node = Node(m2, d, e)

f1_node = Node(f1, a)
f2_node = Node(f2, b, Choice(m1_node, m2_node, d))

k_node = Node(k, Choice(f1_node, f2_node; default=f2_node), h_node)

k_node(m1_node, f2_node; a = 3, b = 2, d = 4, e=1)

base(k_node, m1_node, f2_node)
