import ForwardDiff

const DEFAULT_PWR_FRAC = [
    0.0,
    0.005,
    0.015,
    0.04,
    0.06,
    0.10,
    0.14,
    0.20,
    0.40,
    0.60,
    0.80,
    1.00,
]

const DEFAULT_DIESEL_EFF = [
    0.0714,
    0.10,
    0.1429,
    0.1857,
    0.2286,
    0.2786,
    0.2929,
    0.30,
    0.2929,
    0.2714,
    0.2571,
    0.2429,
]

const DEFAULT_HD_DIESEL_EFF = [
    0.04,
    0.06,
    0.11,
    0.20,
    0.25,
    0.33,
    0.37,
    0.41,
    0.44,
    0.45,
    0.45,
    0.45,
]

"""
    EfficiencyMap(power_frac, eff)

Power-fraction efficiency curve for a diesel engine.

`power_frac` and `eff` must be the same length with strictly increasing
fractions in `[0, 1]`.
"""
struct EfficiencyMap{T}
    power_frac::Vector{T}
    eff::Vector{T}

    function EfficiencyMap{T}(power_frac::Vector{T}, eff::Vector{T}) where {T}
        validate_eff_map(power_frac, eff)
        return new{T}(power_frac, eff)
    end
end

function EfficiencyMap(power_frac::AbstractVector, eff::AbstractVector)
    T = promote_type(eltype(power_frac), eltype(eff))
    pf = T.(power_frac)
    ef = T.(eff)
    return EfficiencyMap{T}(collect(pf), collect(ef))
end

function validate_eff_map(pf, ef)
    length(pf) == length(ef) || throw(ArgumentError("power_frac and eff length mismatch"))
    issorted(pf) || throw(ArgumentError("power_frac must be sorted ascending"))
    all(diff(pf) .> 0) || throw(ArgumentError("power_frac must be strictly increasing"))
    all(pf .>= 0) && all(pf .<= 1) || throw(ArgumentError("power_frac must be in [0, 1]"))
    all(ef .>= 0) && all(ef .<= 1) || throw(ArgumentError("eff must be in [0, 1]"))
    return nothing
end

"""
    default_diesel_map([T=Float64]) -> EfficiencyMap

Return a scaled light-duty diesel efficiency map with a 0.30 peak efficiency
to match the 1 kW default engine size.

# Example
```julia
map = default_diesel_map()
eff = efficiency(map, 0.4)
```
"""
function default_diesel_map(::Type{T}=Float64) where {T<:Real}
    return EfficiencyMap(T.(DEFAULT_PWR_FRAC), T.(DEFAULT_DIESEL_EFF))
end

"""
    default_hd_diesel_map([T=Float64]) -> EfficiencyMap

Return the FASTSim heavy-duty diesel efficiency map (FASTSim CLI defaults).
"""
function default_hd_diesel_map(::Type{T}=Float64) where {T<:Real}
    return EfficiencyMap(T.(DEFAULT_PWR_FRAC), T.(DEFAULT_HD_DIESEL_EFF))
end

value(x) = x
value(x::ForwardDiff.Dual) = ForwardDiff.value(x)

function interp_linear(x, xs, ys)
    xval = value(x)
    if xval <= xs[1]
        return ys[1]
    elseif xval >= xs[end]
        return ys[end]
    end
    i = searchsortedfirst(xs, xval)
    x0 = xs[i - 1]
    x1 = xs[i]
    y0 = ys[i - 1]
    y1 = ys[i]
    t = (x - x0) / (x1 - x0)
    return y0 + t * (y1 - y0)
end

"""
    efficiency(map, power_frac) -> eff

Linear interpolation of efficiency at a given power fraction.
"""
function efficiency(map::EfficiencyMap, power_frac::Real)
    x = clamp(power_frac, map.power_frac[1], map.power_frac[end])
    return interp_linear(x, map.power_frac, map.eff)
end

function efficiency(map::EfficiencyMap, power_frac::AbstractVector)
    return [efficiency(map, x) for x in power_frac]
end
