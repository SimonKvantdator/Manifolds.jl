function check_manifold_point(
    M::Hyperbolic{N},
    p::PoincareHalfSpacePoint;
    kwargs...,
) where {N}
    mpv = check_manifold_point(Euclidean(N), p.value; kwargs...)
    mpv === nothing || return mpv
    if !(last(p.value) > 0)
        return DomainError(
            norm(p.value),
            "The point $(p) does not lie on $(M) since its last entry is nonpositive.",
        )
    end
end

@doc raw"""
    convert(::Type{PoincareHalfSpacePoint}, p::PoincareBallPoint)

convert a point [`PoincareBallPoint`](@ref) `p` (from $ℝ^n$) from the
Poincaré ball model of the [`Hyperbolic`](@ref) manifold $ℍ^n$ to a [`PoincareHalfSpacePoint`](@ref) $π(p) ∈ ℝ^n$.
Denote by $\tilde p = (p_1,\ldots,p_{d-1})$. Then the isometry is defined by

````math
π(p) = \frac{1}{\lVert \tilde p \rVert^2 - (p_n-1)^2}
\begin{pmatrix}2p_1\\\vdots\\2p_{n-1}\\1-\lVert\tilde p\rVert^2 - p_n^2\end{pmatrix}.
````
"""
function convert(::Type{PoincareHalfSpacePoint}, p::PoincareBallPoint)
    return PoincareHalfSpacePoint(
        1 / (norm(p.value[1:(end - 1)])^2 + (last(p.value) - 1)^2) .*
        [p.value[1:(end - 1)]..., 1 - norm(p.value[1:(end - 1)])^2 - last(p.value)^2],
    )
end

@doc raw"""
    convert(::Type{PoincareHalfSpacePoint}, p::Hyperboloid)
    convert(::Type{PoincareHalfSpacePoint}, p)

convert a [`HyperboloidPoint`](@ref) or `Vector``p` (from $ℝ^{n+1}$) from the
Hyperboloid model of the [`Hyperbolic`](@ref) manifold $ℍ^n$ to a [`PoincareHalfSpacePoint`](@ref) $π(x) ∈ ℝ^{n}$.

This is done in two steps, namely transforming it to a Poincare ball point and from there further on to a PoincareHalfSpacePoint point.
"""
convert(::Type{PoincareHalfSpacePoint}, ::Any)
function convert(t::Type{PoincareHalfSpacePoint}, x::HyperboloidPoint)
    return convert(t, convert(PoincareBallPoint, x))
end
function convert(t::Type{PoincareHalfSpacePoint}, x::T) where {T<:AbstractVector}
    return convert(t, convert(PoincareBallPoint, x))
end

@doc raw"""
    convert(
        ::Type{PoincareHalfSpaceTVector},
        (p,X)::Tuple{PoincareBallPoint,PoincareBallTVector}
    )

convert a [`PoincareBallTVector`](@ref) `X` at `p` to a [`PoincareHalfSpacePoint`](@ref)
on the [`Hyperbolic`](@ref) manifold $ℍ^n$ by computing the push forward $π_*(p)[X]$ of
the isometry $π$ that maps from the Poincaré ball to the Poincaré half space,
cf. [`convert(::Type{PoincareHalfSpacePoint}, ::PoincareBallPoint)`](@ref).

The formula reads

````math
π_*(p)[X] =
\frac{1}{\lVert \tilde p\rVert^2 + (1+p_n)^2}
\begin{pmatrix}
2X_1\\
⋮\\
2X_{n-1}\\
-2⟨X,p⟩
\end{pmatrix}
-
\frac{2}{(\lVert \tilde p\rVert^2 + (1+p_n)^2)^2}
\begin{pmatrix}
2p_1(⟨X,p⟩-X_1)\\
⋮\\
2p_{n-1}(⟨X,p⟩-X_{n-1})\\
(\lVert p \rVert^2-1)(⟨X,p⟩-X_n)
\end{pmatrix}
````
where $\tilde p = \begin{pmatrix}p_1\\\vdots\\p_{n-1}\end{pmatrix}$.
"""
function convert(
    ::Type{PoincareHalfSpaceTVector},
    (p, X)::Tuple{PoincareBallPoint,PoincareBallTVector},
)
    den = 1 + norm(p.value[1:(end - 1)])^2 + (last(p.value) + 1)^2
    scp = dot(p.value, X.value)
    c1 = (2 / den .* X.value[1:(end - 1)])
    .-4 .* p.value[1:(end - 1)] .* (scp .- X.value[1:(end - 1)]) ./ (den^2)
    c2 = -2 * scp / den + 2 * (norm(p.value)^2 - 1) * (scp - last(X.value)) / (den^2)
    return PoincareHalfSpaceTVector([c1..., c2])
end

@doc raw"""
    convert(
        ::Type{Tuple{PoincareHalfSpacePoint,PoincareHalfSpaceTVector}},
        (p,X)::Tuple{PoincareBallPoint,PoincareBallTVector}
    )

Convert a [`PoincareBallPoint`](@ref) `p` and a [`PoincareBallTVector`](@ref) `X`
to a [`PoincareHalfSpacePoint`](@ref) and a [`PoincareHalfSpaceTVector`](@ref) simultaneously,
see [`convert(::Type{PoincareHalfSpacePoint}, ::PoincareBallPoint)`](@ref) and
[`convert(::Type{PoincareHalfSpaceTVector}, ::Tuple{PoincareBallPoint,PoincareBallTVector})`](@ref)
for the formulae.
"""
function convert(
    ::Type{Tuple{PoincareHalfSpacePoint,PoincareHalfSpaceTVector}},
    (p, X)::Tuple{PoincareBallPoint,PoincareBallTVector},
)
    return (convert(PoincareBallPoint, p), convert(PoincareBallTVector, (p, X)))
end

@doc raw"""
    distance(::Hyperbolic, p::PoincareHalfSpacePoint, q::PoincareHalfSpacePoint)

Compute the distance on the [`Hyperbolic`](@ref) manifold $ℍ^n$ represented in the
Poincaré half space model. The formula reads

````math
d_{ℍ^n}(p,q) = \operatorname{acosh}\Bigl( 1 + \frac{\lVert p - q \rVert^2}{2 p_n q_n} \Bigr)
````
"""
function distance(::Hyperbolic, p::PoincareHalfSpacePoint, q::PoincareHalfSpacePoint)
    return acosh(1 + norm(p.value .- q.value)^2 / (2 * p.value[end] * q.value[end]))
end

@doc raw"""
    inner(
        ::Hyperbolic{n},
        p::PoincareHalfSpacePoint,
        X::PoincareHalfSpaceTVector,
        Y::PoincareHalfSpaceTVector
    )

Compute the inner product in the Poincaré half space model. The formula reads
````math
g_p(X,Y) = \frac{⟨X,Y⟩}{p_n^2}.
````
"""
function inner(
    ::Hyperbolic,
    p::PoincareHalfSpacePoint,
    X::PoincareHalfSpaceTVector,
    Y::PoincareHalfSpaceTVector,
)
    return dot(X.value, Y.value) / last(p.value)^2
end
