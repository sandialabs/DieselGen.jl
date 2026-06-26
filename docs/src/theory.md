# Theory

DieselGen follows FASTSim's diesel fuel-converter abstraction. Mechanical power
is computed from RPM and torque, then mapped to efficiency by fractional load.
Fuel power is `Pout / eta`, and fuel mass flow follows from diesel lower heating
value.

The package uses a one-dimensional efficiency map rather than a full brake
specific fuel consumption surface. That keeps the model small and differentiable,
but means efficiency depends on total power only, not independently on RPM and
torque. A ramp limiter and idle floor provide first-order dynamic behavior for
controls studies.

This level of fidelity is appropriate for ontology and control co-design glue:
it exposes power, mass, fuel, and dynamic limits without locking the system model
to one engine vendor map. A higher-fidelity engine package can later replace the
same inputs and outputs.
