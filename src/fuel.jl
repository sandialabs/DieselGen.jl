const L_PER_GAL = 3.78541

"""
    DieselFuel(kwh_per_gallon, density_kg_per_l)

Diesel fuel properties used to convert energy to mass and volume.
"""
struct DieselFuel{T}
    kwh_per_gallon::T
    density_kg_per_l::T
end

"""
    default_diesel_fuel([T=Float64]) -> DieselFuel

Return typical diesel properties (37.95 kWh/gal, 0.832 kg/L).

# Example
```julia
fuel = default_diesel_fuel()
fuel_lhv_kj_per_kg(fuel)
```
"""
function default_diesel_fuel(::Type{T}=Float64) where {T<:Real}
    return DieselFuel(T(37.95), T(0.832))
end

"""
    fuel_lhv_kj_per_kg(fuel) -> kJ/kg

Lower heating value implied by `kwh_per_gallon` and density.
"""
function fuel_lhv_kj_per_kg(fuel::DieselFuel)
    return fuel.kwh_per_gallon / L_PER_GAL / fuel.density_kg_per_l * 3600
end
