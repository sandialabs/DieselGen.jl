module DieselGen

export EfficiencyMap,
    DieselFuel,
    EngineDesign,
    EngineResult,
    default_diesel_map,
    default_hd_diesel_map,
    default_diesel_fuel,
    fuel_lhv_kj_per_kg,
    engine_mass_kg,
    engine_volume_l,
    power_kw,
    torque_nm,
    efficiency,
    efficiency_at_power,
    fuel_power_kw,
    fuel_mass_flow_kg_s,
    fuel_volume_flow_l_s,
    bsfc_g_per_kwh,
    simulate_engine

include("maps.jl")
include("fuel.jl")
include("engine.jl")
include("simulate.jl")

end
