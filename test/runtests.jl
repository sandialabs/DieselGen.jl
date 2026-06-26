using DieselGen
using ForwardDiff
using Test

@testset "EfficiencyMap" begin
    map = default_diesel_map()
    @test length(map.power_frac) == length(map.eff)
    @test isapprox(efficiency(map, 0.4), 0.2929; atol = 1e-4)
    @test isapprox(efficiency(map, 0.0), 0.0714; atol = 1e-4)
    @test isapprox(efficiency(map, 0.01), 0.12145; atol = 1e-5)

    vals = efficiency(map, [-0.2, 0.4, 1.2])
    @test isapprox(vals[1], 0.0714; atol = 1e-4)
    @test isapprox(vals[2], 0.2929; atol = 1e-4)
    @test isapprox(vals[3], 0.2429; atol = 1e-4)

    @test_throws ArgumentError EfficiencyMap([0.1, 0.0], [0.1, 0.2])
    @test_throws ArgumentError EfficiencyMap([0.0, 0.5], [0.1])
    @test_throws ArgumentError EfficiencyMap([0.0, 1.2], [0.1, 0.2])
end

@testset "Fuel Properties" begin
    fuel = default_diesel_fuel()
    lhv = fuel_lhv_kj_per_kg(fuel)
    @test lhv > 42_000
    @test lhv < 45_000
end

@testset "Engine Design" begin
    design = EngineDesign(
        max_power_kw = 110.0,
        idle_power_kw = 1.96,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    expected_mass = (110.0 / 2.13 + 61.3) * 1.4
    @test isapprox(engine_mass_kg(design), expected_mass; rtol = 1e-12)
    @test engine_mass_kg(EngineDesign(
        max_power_kw = 0.0,
        idle_power_kw = 0.0,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )) == 0.0

    @test isnan(engine_volume_l(design))
    @test engine_volume_l(design; power_density_kw_per_l = 55.0) ≈ 110.0 / 55.0
    @test engine_volume_l(design; density_kg_per_m3 = 2700.0) ≈
        engine_mass_kg(design) / 2700.0 * 1000
end

@testset "Power and Efficiency" begin
    rpm = 2000.0
    torque = 200.0
    p = power_kw(rpm, torque)
    @test isapprox(torque_nm(p, rpm), torque; rtol = 1e-12)
    @test torque_nm(10.0, 0.0) == 0.0

    design = EngineDesign(
        max_power_kw = 110.0,
        idle_power_kw = 1.96,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    @test isapprox(
        efficiency_at_power(design, 0.4 * design.max_power_kw),
        0.2929;
        atol = 1e-4,
    )
    @test efficiency_at_power(design, 0.0) == 0.0

    p_in = fuel_power_kw(design, 50.0)
    @test p_in > 50.0
    @test fuel_mass_flow_kg_s(design, 0.0) == 0.0
    @test fuel_volume_flow_l_s(design, 0.0) == 0.0

    @test isnan(bsfc_g_per_kwh(design, 0.0))
end

@testset "Simulation" begin
    design = EngineDesign(
        max_power_kw = 100.0,
        idle_power_kw = 2.0,
        ramp_time_s = 0.0,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    rpm = [2000.0, 2000.0, 2000.0]
    torque = [0.0, 100.0, 200.0]

    result = simulate_engine(rpm, torque, 1.0, design)
    @test result.power_out_kw[1] == 0.0
    @test result.power_out_kw[2] >= 2.0
    @test result.total_fuel_mass_kg > 0.0

    design_ramp = EngineDesign(
        max_power_kw = 100.0,
        idle_power_kw = 0.0,
        ramp_time_s = 10.0,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    ramp_result = simulate_engine([2000.0, 2000.0], [0.0, 400.0], 1.0, design_ramp)
    @test isapprox(ramp_result.power_out_kw[2], 10.0; rtol = 1e-6)

    engine_on = [true, false, true]
    off_result = simulate_engine(rpm, torque, 1.0, design; engine_on = engine_on)
    @test off_result.power_out_kw[2] == 0.0

    dt_vec = [1.0, 2.0]
    vec_result = simulate_engine([2000.0, 2000.0], [100.0, 100.0], dt_vec, design)
    @test isapprox(
        vec_result.total_energy_out_kwh,
        sum(vec_result.power_out_kw .* dt_vec) / 3600;
        rtol = 1e-12,
    )
end

@testset "ForwardDiff Compatibility" begin
    design = EngineDesign(
        max_power_kw = 120.0,
        idle_power_kw = 1.96,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    rpm = [2000.0, 2000.0]
    torque = [200.0, 220.0]

    f(x) = simulate_engine(rpm, torque .* x, 1.0, design).total_fuel_mass_kg
    df = ForwardDiff.derivative(f, 1.0)
    eps = 1e-4
    fd = (f(1.0 + eps) - f(1.0 - eps)) / (2 * eps)
    @test isfinite(df)
    @test isapprox(df, fd; rtol = 1e-3, atol = 1e-6)
end

@testset "Validation" begin
    design = EngineDesign(
        max_power_kw = 110.0,
        idle_power_kw = 1.96,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    peak_eff = maximum(default_diesel_map().eff)
    bsfc_peak = bsfc_g_per_kwh(design, peak_eff)
    @test 260 < bsfc_peak < 340

    hd_design = EngineDesign(
        max_power_kw = 250.0,
        idle_power_kw = 1.96,
        ramp_time_s = 6.1,
        base_mass_kg = 61.3,
        power_density_kw_per_kg = 2.13,
        comp_mass_multiplier = 1.4,
        eff_map = default_hd_diesel_map(),
        fuel = default_diesel_fuel(),
    )
    hd_peak_eff = maximum(default_hd_diesel_map().eff)
    hd_bsfc = bsfc_g_per_kwh(hd_design, hd_peak_eff)
    @test 170 < hd_bsfc < 220
end
