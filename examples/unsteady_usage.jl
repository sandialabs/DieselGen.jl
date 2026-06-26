# # Unsteady diesel operation
#
# This example simulates time-varying RPM and torque and shows the resulting
# power and fuel flow.

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

t = 0.0:0.5:60.0
dt = fill(step(t), length(t))

rpms = 1200 .+ 600 .* sin.(2 * pi .* t ./ 30)
torques = 3.0 .+ 2.0 .* sin.(2 * pi .* t ./ 10)

rpms = max.(rpms, 800)
torques = clamp.(torques, 0, 6.0)

result = simulate_engine(rpms, torques, dt, design)
req_power = power_kw.(rpms, torques)

p1 = plot(
    t,
    req_power;
    label = "Requested power (kW)",
    xlabel = "Time (s)",
    ylabel = "Power (kW)",
    title = "Unsteady power demand",
)
plot!(p1, t, result.power_out_kw; label = "Delivered power (kW)")

p2 = plot(
    t,
    result.fuel_mass_flow_kg_s .* 1e3;
    label = "Fuel mass flow (g/s)",
    xlabel = "Time (s)",
    ylabel = "Fuel (g/s)",
    title = "Fuel flow response",
)

p_eff = plot(
    t,
    result.efficiency;
    label = "Efficiency",
    xlabel = "Time (s)",
    ylabel = "Efficiency",
    title = "Efficiency response",
)

fig_unsteady = plot(p1, p2, p_eff; layout = (3, 1), size = (800, 800))
display(fig_unsteady)
savefig(fig_unsteady, joinpath(fig_dir, "unsteady_response.pdf"))

# A second run with fast ramps that exceed the engine ramp limit.
t_fast = 0.0:0.2:30.0
dt_fast = fill(step(t_fast), length(t_fast))
rpms_fast = 1000 .+ 900 .* sin.(2 * pi .* t_fast ./ 3)
torques_fast = 3.5 .+ 3.0 .* sin.(2 * pi .* t_fast ./ 1.2)
rpms_fast = max.(rpms_fast, 800)
torques_fast = clamp.(torques_fast, 0, 8.0)

result_fast = simulate_engine(rpms_fast, torques_fast, dt_fast, design)
req_power_fast = power_kw.(rpms_fast, torques_fast)

p3 = plot(
    t_fast,
    req_power_fast;
    label = "Requested power (kW)",
    xlabel = "Time (s)",
    ylabel = "Power (kW)",
    title = "Fast ramps vs engine limit",
)
plot!(p3, t_fast, result_fast.power_out_kw; label = "Delivered power (kW)")

p4 = plot(
    t_fast,
    result_fast.fuel_mass_flow_kg_s .* 1e3;
    label = "Fuel mass flow (g/s)",
    xlabel = "Time (s)",
    ylabel = "Fuel (g/s)",
    title = "Fuel flow under fast ramps",
)

p5 = plot(
    t_fast,
    result_fast.efficiency;
    label = "Efficiency",
    xlabel = "Time (s)",
    ylabel = "Efficiency",
    title = "Efficiency under fast ramps",
)

fig_fast_ramps = plot(p3, p4, p5; layout = (3, 1), size = (800, 800))
display(fig_fast_ramps)
savefig(fig_fast_ramps, joinpath(fig_dir, "unsteady_fast_ramps.pdf"))
