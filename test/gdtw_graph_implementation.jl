using UnPack, LightGraphs

"""
    LazyWeightMatrix{T,F1,F2} <: AbstractMatrix{T}

A structure that computes the weights for the graph `g`
as generated by `make_graph(M, N)` lazily, for use in shortest path algorithms.
"""
struct LazyWeightMatrix{T,F1,F2} <: AbstractMatrix{T}
    M::Int
    N::Int
    node_weight::F1
    edge_weight::F2
    nv::Int
end

function LazyWeightMatrix{T}(M, N, node_weight::F1, edge_weight::F2) where {F1,F2,T}
    nv = 2 * N * M
    return LazyWeightMatrix{T,F1,F2}(M, N, node_weight, edge_weight, nv)
end

Base.size(L::LazyWeightMatrix) = (L.nv, L.nv)

function Base.getindex(LWM::LazyWeightMatrix{T,F1,F2}, i, j) where {T,F1,F2}
    @unpack M, N, node_weight, edge_weight = LWM
    CIs = CartesianIndices((1:2, 1:M, 1:N))
    src_edge = Base.tail(Tuple(CIs[i]))
    dst_edge = Base.tail(Tuple(CIs[j]))
    if src_edge == dst_edge
        return T(node_weight(src_edge...))
    else
        return T(edge_weight(src_edge, dst_edge))
    end
    return T(Inf)
end

make_graph(M, N) = make_graph(M, N, Int)

"""
    make_graph(M, N, ::Type{IT}) where {IT <: Integer} -> SimpleDiGraph

Generates a `LightGraphs.SimpleDiGraph` corresponding to the problem.
The graph has `2*N*M` vertices: since LightGraphs does not support node weights, we split each vertex
into two, and mimic a node weight by having an edge weight between these two parts.
"""
function make_graph(M, N, ::Type{IT}) where {IT<:Integer}
    LIs = LinearIndices((1:2, 1:M, 1:N))
    IN = 1
    OUT = 2

    g = SimpleDiGraph(2 * N * M)

    # Add the "node weights" by connecting the `IN` vertex to the `OUT` vertex
    for t = 1:N, j = 1:M
        add_edge!(g, LIs[IN, j, t], LIs[OUT, j, t])
    end

    # Add the real edge weights, from each `OUT` to `IN`.
    for t = 1:N-1
        for j = 1:M, k = 1:M
            add_edge!(g, LIs[OUT, j, t], LIs[IN, k, t+1])
        end
    end

    return g
end


function get_path!(warp, M, N, τ, g, wts, algo)
    # Get the optimal path via `algo`
    a = algo(g, 1, wts)
    src = a.parents[end]

    if src == 0
        error("Could not find shortest path; problem seems to be infeasible.")
    end
    # Now we want to convert it to a time-warping path
    # by removing the doubled vertices and getting the associated
    # values of `τ`.
    CIs = CartesianIndices((1:2, 1:M, 1:N))
    dst = nv(g)
    dst_ij = Base.tail(Tuple(CIs[dst]))
    src_ij = Base.tail(Tuple(CIs[src]))
    warp[N] = τ[src_ij...]
    i = N - 1
    # We don't need to accumulate the cost
    # but we can for testing to check
    # cost = 0.0
    while true
        # cost = cost + wts[src, dst]
        if src_ij != dst_ij
            warp[i] = τ[src_ij...]
            i = i - 1
            src_ij == (1, 1) && break
        end
        dst = src
        dst_ij = src_ij
        src = a.parents[src]
        src_ij = Base.tail(Tuple(CIs[src]))
    end
    # @assert cost ≈ a.dists[end]
    return a.dists[end]
end

function DynamicAxisWarping.single_gdtw!(data::D, algo::F) where {D, F}
    @unpack warp, M, N, τ, node_weight, edge_weight = data
    g = make_graph(M, N)
    lwm = LazyWeightMatrix{Float64}(M, N, node_weight, edge_weight)
    get_path!(warp, M, N, τ, g, lwm, algo)
end
