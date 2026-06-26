# DieselGen.jl

Standalone diesel engine performance and sizing model translated from FASTSim
diesel fuel-converter logic. Default examples target a 1 kW rated engine.

## Quick Start

```julia
using DieselGen

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
result.total_fuel_mass_kg
```

## Limitations

DieselGen follows FASTSim's data-light approach and uses a 1D efficiency curve
indexed by fractional power. This keeps the model fast and low-input, but it
means:

- Efficiency depends only on power, not explicit RPM and torque.
- Any RPM/torque pair with the same power yields the same efficiency.
- A true 2D BSFC/efficiency map and max-torque curve are not modeled.

## Detailed Usage

```julia
using DieselGen

# Custom efficiency map
map = EfficiencyMap(
    [0.0, 0.2, 0.5, 1.0],
    [0.10, 0.35, 0.40, 0.32],
)

fuel = DieselFuel(37.95, 0.832)
design = EngineDesign(
    max_power_kw = 1.0,
    idle_power_kw = 0.013,
    ramp_time_s = 6.1,
    base_mass_kg = 61.3,
    power_density_kw_per_kg = 2.13,
    comp_mass_multiplier = 1.4,
    eff_map = map,
    fuel = fuel,
)

rpm = [1800, 1800, 1800]
torque = [0.0, 3.0, 4.5]
dt = [1.0, 1.0, 2.0]

result = simulate_engine(rpm, torque, dt, design)
result.power_out_kw
```

## Theory

DieselGen follows FASTSim's diesel fuel-converter model:

- Mechanical power is computed from RPM and torque.
- Efficiency is read from a fractional power map and linearly interpolated.
- FASTSim uses a discrete lookup over a dense grid; DieselGen uses linear interpolation for smoothness.
- Fuel power is `P_out / eta`, and fuel mass flow is computed using diesel LHV.
- Engine mass scales with rated power and a base mass term.
- A simple ramp limiter and idle floor bound the dynamic output power.
- The default efficiency map is scaled to a 0.30 peak to represent a small engine.
- Peak efficiency corresponds to typical small-diesel BSFC values around 270-330 g/kWh.

## API Reference

See the [API](api.md) page for exported types and functions.
