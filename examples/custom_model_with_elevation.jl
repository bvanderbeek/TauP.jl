# Example: Create Model for Elevation Calculations
# Create a model with a larger Radius from AK135 that can be used to compute
# travel-times that include elevation. This approach will not work for surface
# reflections (but maybe can work-around by adding a model interface).
delete!(ENV, "TAUP_JAR"); # Use default TauP jar-file
using TauP

# Input
theModel = "/Users/bvanderbeek/research/software/JuliaProjects/TauP/TauP-2.6.1/StdModels/ak135_e8850m"; # New model file to save
max_elv = 8.850 # Maximum elevation above sea level (km)

# Load the AK135 reference model
M = load_taup_model("ak135");

# Shift all depths by the maximum elevation
M.r .+= max_elv;
# 'Extend' model to surface without adding a new surface layer
M.r[1] = 0.0;

# Assign mantle and inner/outer core boundaries to discontinuities in AK135 (TauP preferred format)
M.discontinuity[2] = "mantle";
M.discontinuity[end-1] = "outer-core";
M.discontinuity[end] = "inner-core";

# Write the velocity model
write_taup_model(theModel, M; n = 4, print_full_model = true);

# Test the New Model
# Input parameters
phase = ["P", "S"]; # Phases
Δ = 55.0; # Arc distance
z₀ = 50.0; # Source depth
z₁ = 0.0; # Receiver depth
# TauP Time to mean sea level with original model
taup_time(phase, Δ, z₀; receiver_depth = z₁, model = "ak135", verbose = true);
# TauP Time to mean sea level with extended model
# Given reference mean sea level radius R₀, TauP model radius Rₜ, and an elevation r, the relevant TauP model depth is:
#   hₜ = Rₜ - (R₀ + r)
# Interpreting the source and receiver depths as negative elevation in this example, the new TauP depths are
#   hₜ = max_elv + zₜ
# theModel = theModel * ".nd";
taup_time(phase, Δ, max_elv + z₀; receiver_depth = max_elv + z₁, model = theModel, verbose = true);
# TauP Time to maximum elevation
taup_time(phase, Δ, max_elv + z₀; receiver_depth = z₁, model = theModel, verbose = true);