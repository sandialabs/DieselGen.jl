# # Diesel performance map
#
# This example builds a simple performance map for a diesel engine design and
# plots the fuel mass flow as a 3D surface over RPM and torque.

using DieselGen
using Plots

gr()
default(
    background_color = :transparent,
    background_color_inside = :transparent,
    background_color_subplot = :transparent,
)

fig_dir = joinpath(@__DIR__, "figs")
mkpath(fig_dir)

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

rpms = 1000:250:3000
torques = 0:0.2:4.0

pmax = design.max_power_kw

fuel_map = [
    fuel_mass_flow_kg_s(
        design,
        fuel_power_kw(design, min(power_kw(r, t), pmax)),
    ) for t in torques, r in rpms
]

# Note: efficiency depends only on power fraction, so contours follow constant power.
fuel_surface = surface(
    rpms,
    torques,
    fuel_map .* 1e3;
    xlabel = "RPM",
    ylabel = "Torque (N*m)",
    zlabel = "Fuel mass flow (g/s)",
    title = "Diesel fuel flow map",
)
display(fuel_surface)
savefig(fuel_surface, joinpath(fig_dir, "perf_map_fuel_flow.pdf"))

eff_map = [
    efficiency_at_power(design, min(power_kw(r, t), pmax)) for t in torques, r in rpms
]

eff_surface = surface(
    rpms,
    torques,
    eff_map;
    xlabel = "RPM",
    ylabel = "Torque (N*m)",
    zlabel = "Efficiency",
    title = "Diesel efficiency map",
)
display(eff_surface)
savefig(eff_surface, joinpath(fig_dir, "perf_map_efficiency.pdf"))
