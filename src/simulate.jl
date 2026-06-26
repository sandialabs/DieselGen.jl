const TWO_PI = 2 * pi

"""
    power_kw(rpm, torque_nm) -> kW

Mechanical power from speed and torque.
"""
power_kw(rpm, torque_nm) = torque_nm * rpm * TWO_PI / 60 / 1000

"""
    torque_nm(power_kw, rpm) -> N*m

Torque from power and speed. Returns zero if `rpm` is zero.
"""
function torque_nm(power_kw, rpm)
    if rpm == 0
        return zero(rpm)
    end
    return power_kw * 1000 * 60 / (TWO_PI * rpm)
end

"""
    efficiency_at_power(design, power_kw) -> eff

Efficiency from the engine map at a given power output.
"""
function efficiency_at_power(design::EngineDesign, power_kw)
    if design.max_power_kw <= 0 || power_kw <= 0
        return zero(power_kw)
    end
    frac = clamp(power_kw / design.max_power_kw, zero(power_kw), one(power_kw))
    return efficiency(design.eff_map, frac)
end

efficiency(design::EngineDesign, power_kw) = efficiency_at_power(design, power_kw)

"""
    fuel_power_kw(design, power_out_kw) -> kW

Fuel power input required for a given power output.
"""
function fuel_power_kw(design::EngineDesign, power_out_kw)
    eff = efficiency_at_power(design, power_out_kw)
    if eff <= 0
        return zero(power_out_kw)
    end
    return power_out_kw / eff
end

"""
    fuel_mass_flow_kg_s(design, fuel_power_kw) -> kg/s

Fuel mass flow from input power and fuel LHV.
"""
function fuel_mass_flow_kg_s(design::EngineDesign, fuel_power_kw)
    if fuel_power_kw <= 0
        return zero(fuel_power_kw)
    end
    return fuel_power_kw / fuel_lhv_kj_per_kg(design.fuel)
end

"""
    fuel_volume_flow_l_s(design, fuel_mass_flow_kg_s) -> L/s
"""
function fuel_volume_flow_l_s(design::EngineDesign, fuel_mass_flow_kg_s)
    if fuel_mass_flow_kg_s <= 0
        return zero(fuel_mass_flow_kg_s)
    end
    return fuel_mass_flow_kg_s / design.fuel.density_kg_per_l
end

"""
    bsfc_g_per_kwh(design, eff) -> g/kWh

Brake specific fuel consumption from efficiency and fuel properties.
"""
function bsfc_g_per_kwh(design::EngineDesign, eff)
    if eff <= 0
        return NaN
    end
    return 3600 / (fuel_lhv_kj_per_kg(design.fuel) * eff) * 1000
end

function apply_ramp_limit(target_kw, prev_kw, design::EngineDesign, dt_s)
    if design.ramp_time_s <= 0
        return clamp(target_kw, zero(target_kw), design.max_power_kw)
    end
    ramp_rate = design.max_power_kw / design.ramp_time_s
    lower = max(zero(target_kw), prev_kw - ramp_rate * dt_s)
    upper = prev_kw + ramp_rate * dt_s
    return clamp(target_kw, lower, min(upper, design.max_power_kw))
end

"""
    EngineResult

Container for simulation outputs.
"""
struct EngineResult{T}
    rpm::Vector{T}
    torque_nm::Vector{T}
    power_out_kw::Vector{T}
    power_in_kw::Vector{T}
    efficiency::Vector{T}
    fuel_mass_flow_kg_s::Vector{T}
    fuel_volume_flow_l_s::Vector{T}
    total_fuel_mass_kg::T
    total_fuel_volume_l::T
    total_energy_in_kwh::T
    total_energy_out_kwh::T
end

"""
    simulate_engine(rpm, torque_nm, dt_s, design; engine_on=nothing) -> EngineResult

Simulate diesel fuel use over a sequence of RPM/torque points.

`dt_s` may be a scalar or a vector matching `rpm`.

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
rpm = [1500, 2000, 2500]
torque = [2.0, 2.5, 1.8]
result = simulate_engine(rpm, torque, 1.0, design)
```
"""
function simulate_engine(
    rpm::AbstractVector,
    torque_nm::AbstractVector,
    dt_s,
    design::EngineDesign;
    engine_on = nothing,
)
    n = length(rpm)
    length(torque_nm) == n || throw(ArgumentError("rpm and torque_nm length mismatch"))
    if dt_s isa AbstractVector
        length(dt_s) == n || throw(ArgumentError("dt_s length mismatch"))
    end
    if engine_on !== nothing
        length(engine_on) == n || throw(ArgumentError("engine_on length mismatch"))
    end

    T = promote_type(eltype(rpm), eltype(torque_nm), typeof(design.max_power_kw))
    p_out = Vector{T}(undef, n)
    p_in = Vector{T}(undef, n)
    eff = Vector{T}(undef, n)
    mflow = Vector{T}(undef, n)
    vflow = Vector{T}(undef, n)

    prev_kw = zero(T)
    for i in 1:n
        dt = dt_s isa AbstractVector ? dt_s[i] : dt_s
        req_kw = max(zero(T), power_kw(rpm[i], torque_nm[i]))
        on = engine_on === nothing ? req_kw > 0 : engine_on[i]

        target_kw = if on && req_kw > 0
            max(req_kw, design.idle_power_kw)
        else
            zero(T)
        end

        if target_kw == 0
            p_out[i] = zero(T)
        else
            p_out[i] = apply_ramp_limit(target_kw, prev_kw, design, dt)
        end
        eff[i] = p_out[i] > 0 ? efficiency_at_power(design, p_out[i]) : zero(T)
        p_in[i] = eff[i] > 0 ? p_out[i] / eff[i] : zero(T)
        mflow[i] = fuel_mass_flow_kg_s(design, p_in[i])
        vflow[i] = fuel_volume_flow_l_s(design, mflow[i])

        prev_kw = p_out[i]
    end

    dt_vec = dt_s isa AbstractVector ? dt_s : fill(dt_s, n)
    total_fuel_mass_kg = sum(mflow .* dt_vec)
    total_fuel_volume_l = sum(vflow .* dt_vec)
    total_energy_in_kwh = sum(p_in .* dt_vec) / 3600
    total_energy_out_kwh = sum(p_out .* dt_vec) / 3600

    rpm_vec = T.(rpm)
    torque_vec = T.(torque_nm)

    return EngineResult(
        rpm_vec,
        torque_vec,
        p_out,
        p_in,
        eff,
        mflow,
        vflow,
        total_fuel_mass_kg,
        total_fuel_volume_l,
        total_energy_in_kwh,
        total_energy_out_kwh,
    )
end
