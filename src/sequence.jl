using Base.Cartesian

"""
    Sequence{N,T}(A::AbstractArray{T,N})

A sequence is a thin wrapper around a multi-dimensional array that 
allows you to index it like a vector. For example, the following
code shows a 10-dimensional time series, sampled at 100 time points:

```
data = randn(10,100)
seq = Sequence(data)
seq[1] == data[:,1] # true
```

This generalizes to higher-order arrays. Consider a time series
where a 10x10 matrix of data is collected at 100 time points:

```
data = randn(10,10,100)
seq = Sequence(data)
seq[1] == data[:,:,1] # true
```
"""
type Sequence{N,T} <: AbstractArray{T,1}
    val::AbstractArray{T,N}
end

@generated Base.size{N}(x::Sequence{N}) = :((size(x.val,N),))

@generated function Base.getindex{N}(x::Sequence{N},i::Int)
    :( x.val[@ntuple($N, (n-> n==N ? i : Colon()))...] )
end
