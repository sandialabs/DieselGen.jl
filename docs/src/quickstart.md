# Quick Start

`DieselGen` simulates a data-light diesel engine from RPM and torque histories.
The default design is intentionally small and fast so it can be used inside
short-horizon optimization loops.

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

rpm = [1500.0, 2000.0, 2500.0]
torque = [2.0, 2.5, 1.8]
dt = 1.0

result = simulate_engine(rpm, torque, dt, design)
result.power_out_kw
result.total_fuel_mass_kg
```

For dynamic co-design work, use output power and fuel use as the subsystem
interface. SIRENOpt wraps this package with `diesel_engine_design` and
`diesel_fuel_used` so diesel dispatch can be coupled to battery, converter, and
load states.
