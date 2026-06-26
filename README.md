# DieselGen.jl

[![CI](https://github.com/kevmoor/DieselGen.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/kevmoor/DieselGen.jl/actions/workflows/CI.yml)
[![Docs](https://github.com/kevmoor/DieselGen.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/kevmoor/DieselGen.jl/actions/workflows/Docs.yml)
[![Coverage](https://codecov.io/gh/kevmoor/DieselGen.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kevmoor/DieselGen.jl)

Standalone diesel engine performance and sizing model translated from FASTSim
diesel fuel-converter logic. Designed for fast, differentiable simulations with
1 kW defaults.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/kevmoor/DieselGen.jl")
```

For local development from a checkout:

```julia
using Pkg
Pkg.develop(path = "/path/to/DieselGen.jl")
```

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

## Model Notes

- Uses FASTSim-style efficiency maps as a function of fractional power.
- Linear interpolation is used for smooth, differentiable efficiency curves.
- The default diesel map is scaled to a 0.30 peak to represent a small engine.
- Fuel power is `P_out / eta`, with LHV-based conversion to mass/volume.
- Engine mass scales with rated power and a base mass term.
- Simple ramp limiting and idle power floor are included.
- Pure Julia implementation supports ForwardDiff.

## Development

```julia
using Pkg
Pkg.test("DieselGen")
```

## License

MIT for DieselGen contributions. FASTSim-derived model defaults and
fuel-converter logic remain subject to the FASTSim permissive license terms
included in `NOTICE`.
