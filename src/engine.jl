"""
    EngineDesign(; kwargs...)

Container for diesel engine design parameters.

Fields mirror FASTSim inputs:
- `max_power_kw`
- `idle_power_kw`
- `ramp_time_s`
- `base_mass_kg`
- `power_density_kw_per_kg`
- `comp_mass_multiplier`
- `eff_map`
- `fuel`

Only keyword arguments are supported when constructing `EngineDesign`.

Keyword defaults:
- `max_power_kw = 1.0`
- `idle_power_kw = 0.013 * max_power_kw`
- `ramp_time_s = 6.1`
- `base_mass_kg = 61.3`
- `power_density_kw_per_kg = 2.13`
- `comp_mass_multiplier = 1.4`
- `eff_map = default_diesel_map()`
- `fuel = default_diesel_fuel()`
"""
struct EngineDesign{T,M,F}
    max_power_kw::T
    idle_power_kw::T
    ramp_time_s::T
    base_mass_kg::T
    power_density_kw_per_kg::T
    comp_mass_multiplier::T
    eff_map::EfficiencyMap{M}
    fuel::DieselFuel{F}

    function EngineDesign(;
        max_power_kw = 1.0,
        idle_power_kw = nothing,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
        if idle_power_kw === nothing
            idle_power_kw = 0.013 * max_power_kw
        end
        T = promote_type(
            typeof(max_power_kw),
            typeof(idle_power_kw),
            typeof(ramp_time_s),
            typeof(base_mass_kg),
            typeof(power_density_kw_per_kg),
            typeof(comp_mass_multiplier),
        )
        M = eltype(eff_map.power_frac)
        F = typeof(fuel.kwh_per_gallon)
        return new{T,M,F}(
            T(max_power_kw),
            T(idle_power_kw),
            T(ramp_time_s),
            T(base_mass_kg),
            T(power_density_kw_per_kg),
            T(comp_mass_multiplier),
            eff_map,
            fuel,
        )
    end
end

"""
    engine_mass_kg(design) -> kg

Mass scaling from FASTSim: `(max_power_kw / power_density_kw_per_kg + base_mass_kg) * comp_mass_multiplier`.

# Example
```julia
design = EngineDesign(
    max_power_kw = 1.0,
    idle_power_kw = 0.013,
    ramp_time_s = 6.1,
    base_mass_kg = 61.3,
    power_density_kw_per_kg = 2.13,
    comp_mass_multiplier = 1.4,
    eff_map = default_diesel_map(),
    fuel = default_diesel_fuel(),
)
engine_mass_kg(design)
```
"""
function engine_mass_kg(design::EngineDesign)
    if design.max_power_kw <= 0
        return zero(design.max_power_kw)
    end
    return (design.max_power_kw / design.power_density_kw_per_kg + design.base_mass_kg) *
           design.comp_mass_multiplier
end

"""
    engine_volume_l(design; power_density_kw_per_l=nothing, density_kg_per_m3=nothing) -> L

Optional volume estimate using either:
- `power_density_kw_per_l` (kW/L), or
- `density_kg_per_m3` (kg/m^3) with the computed engine mass.
"""
function engine_volume_l(
    design::EngineDesign;
    power_density_kw_per_l = nothing,
    density_kg_per_m3 = nothing,
)
    if power_density_kw_per_l !== nothing
        return design.max_power_kw / power_density_kw_per_l
    elseif density_kg_per_m3 !== nothing
        return engine_mass_kg(design) / density_kg_per_m3 * 1000
    else
        return NaN
    end
end
