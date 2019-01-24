"""
# module Abstractions



# Examples

```jldoctest
julia>
```
"""
module Abstractions

using ArgCheck: @argcheck
using Setfield: @set

import Base: length, ==, *, +, -

export AbstractVariable,
    BivariateField,
    whichdimension,
    getvariable,
    length, ==, *, +, -,
    iscompatible, whichdimension_iscompatible

abstract type AbstractVariable{T} end

abstract type BivariateField{A, B} end

function whichdimension(::BivariateField{A, B}, s::Symbol)::Int where {A, B}
    @argcheck s in (A, B)
    s == A ? 1 : 2
end

function getvariable(f::T, dim::Int) where {T <: BivariateField}
    getfield(f, fieldname(T, dim))
end
getvariable(f::BivariateField, s::Symbol) = (dim = whichdimension(f, s); getvariable(f, dim))

function setvariable(f::BivariateField, var::AbstractVariable{T}) where {T}
    dim = whichdimension(f, T)
    if dim == 1
        @set f.first = var
    else
        @set f.second = var
    end
end
setvariable(f::BivariateField, dim::Int, var::Vector) = setvariable(f, @set getvariable(f, dim).values = var)
setvariable(f::BivariateField, s::Symbol, var::Vector) = setvariable(f, whichdimension(f, s), var)

length(x::AbstractVariable) = length(x.values)

==(x::T, y::T) where {T <: AbstractVariable} = x.values == y.values
==(x::T, y::T) where {T <: BivariateField} = all(getfield(x, f) == getfield(y, f) for f in fieldnames(x))

iscompatible(x::T, y::T) where {T <: BivariateField} = x.first == y.first && x.second == y.second
iscompatible(f::BivariateField{A, B}, v::AbstractVariable{A}) where {A, B} = f.first == v
iscompatible(f::BivariateField{A, B}, v::AbstractVariable{B}) where {A, B} = f.second == v

whichdimension_iscompatible(f::BivariateField{A, B}, v::AbstractVariable{A}) where {A, B} = iscompatible(f, g) ? 1 : error()
whichdimension_iscompatible(f::BivariateField{A, B}, v::AbstractVariable{B}) where {A, B} = iscompatible(f, g) ? 2 : error()

function *(f::T, v::AbstractVariable)::T where {T <: BivariateField}
    dim = whichdimension_iscompatible(f, v)
    @set f.values = if dim == 1
        f.values .* v.values
    else
        f.values .* transpose(v.values)
    end
end
*(v::AbstractVariable, f::BivariateField) = *(f, v)

+(f::T, g::T) where {T <: BivariateField} = iscompatible(f, g) ? f.values + g.values : error()
-(f::T, g::T) where {T <: BivariateField} = iscompatible(f, g) ? f.values - g.values : error()

end