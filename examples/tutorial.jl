# Tutorial for TauP.jl

# Load Package
using TauP
using Plots

# Inputs for examples
model = "iasp91" # Reference 1D model
phase = "P" # Seismic phase
ϕ₀ = 45.0 # Source latitude (deg.)
λ₀ = -125.0 # Source longitude (deg.)
z₀ = 50.0 # Source depth (km)
ϕ₁ = 35.0 # Receiver latitude (deg.)
λ₁ = 20.0 # Receiver longitude (deg.)
z₁ = 0.0 # Receiver depth (km)


# TauP geodesic methods

# Compute source-receiver range and azimuth
Δ, α = taup_geoinv(ϕ₀, λ₀, ϕ₁, λ₁)
# Compute geographic coordinates given distance, bearing, and starting position
ϕ, λ = taup_geofwd(ϕ₀, λ₀, Δ, α)


# TauP Command-line-like functionality in Julia
# These are functions intended to mimic the behaviour of TauP run from a command line

# 1. Methods for taup_time
# 1.1. Arc Distance Input; store results in Struct TimeTauP
TimeTauP = taup_time(phase, Δ, z₀; receiver_depth = z₁, model = model)
# 1.2. Geographic Coordinates Input
taup_time(phase, ϕ₀, λ₀, z₀, ϕ₁, λ₁; receiver_depth = z₁, model = model)
# 1.3. Can also call function with multiple phase input
taup_time(["P","S"], Δ, z₀; receiver_depth = z₁, model = model)
# 1.4. Calling taup_time with TauP-like screen output and default receiver depth (0 km) and model ("prem")
taup_time(["P","S"], Δ, z₀; verbose = true);

# 2. Methods for taup_path (same syntax as taup_time above)
# 2.1. Arc Distance Input; store results in Struct PathTauP
PathTauP = taup_path(phase, Δ, z₀; receiver_depth = z₁, model = model)
# 2.2. Geographic Coordinates Input
taup_path(phase, ϕ₀, λ₀, z₀, ϕ₁, λ₁; receiver_depth = z₁, model = model)
# Also supports multi-phase inputs
taup_path(["P", "S"], ϕ₀, λ₀, z₀, ϕ₁, λ₁; receiver_depth = z₁, model = model)


# Simplified TauP functions
# The basic TauP behaviour is not particularly convenient for integrating with other code
# because (i) Java objects must be built on each function call which can be slow and (ii) the
# results must be parsed to extract the particular phase or property of interest. For this reason,
# lower-level versions of the main taup functions that support only single-phase calculations and
# return a tuple of results have been created. These routines require first building the relevant
# TauP Java object and passing it to the desired function. Specific fields in the Java objects can
# be queried or updated and TauP calculations re-run with these modified objects.
# Below are some examples.

# Build a TauP Time object by passing a reference model name
TimeObj = buildTimeObj(model)
# Compute travel-time (t), ray parameter (p), and incidence (θᵢ) and take-off (θₜ) angles
# This will set the phase, source depth, and receiver depths fields in the TimeObj
t,p,θᵢ,θₜ = taup_time!(TimeObj,phase,Δ,z₀,z₁)
# Update some fields in the object and re-perform calculations
set_taup_phase!(TimeObj,"S")
# Check phase was indeed reset
get_taup_phase(TimeObj)
# Similar get/set functions exist for receiver depth, source depth, and model
# Re-calculate. No need to pass additional arguments as they are already defined in the TimeObj
taup_time!(TimeObj,Δ)
# Geographic coordinates are also supported
# Will additionally return the arc distance and source-receiver azimuth
taup_time!(TimeObj, phase, ϕ₀, λ₀, z₀, ϕ₁, λ₁, z₁)

# Similar syntax for computing ray paths exists
# Build a TauP Path object given a reference model
PathObj = buildPathObj(model)
# Compute ray path as a function of angular distance (d) and radial depth (r) and return travel-time along path (t)
d, r, t = taup_path!(PathObj,phase,Δ,z₀,z₁)
# Again, we can query and update fields in the object
get_taup_source_depth(PathObj)
set_taup_source_depth!(PathObj,0.0)
get_taup_source_depth(PathObj)
# And re-calculate paths by only passing the object and desired arc distance
taup_path!(PathObj,Δ)
# Geographic coordinates are supported and will additionally return the latitude (ϕ)
# and longitude (λ) of the ray path. For whatever reason, the end points of the ray path
# will not exactly match the receiver coordinates and ϵ give this error in degrees (error
# is typically on the order of meters).
d,r,t,ϕᵣ,λᵣ,ϵ = taup_path!(PathObj, phase, ϕ₀, λ₀, z₀, ϕ₁, λ₁, z₁)


# We can load a built-in TauP model by specifying the name or the full path to a TauP
# nd- or tvel-formated model file (see TauP documentation for model file description)
M = load_taup_model("prem")
# We can also write models to TauP-recognized formats via (see function documentation for details)
# write_taup_model(MyModel.nd, M; n = 3, print_full_model = true)

# Plot profiles through the model
H = plot(title = "Velocity Model")
plot!(H, M.vp, -M.r, c="blue", linewidth=2, labels="vp")
plot!(H, M.vs, -M.r, c="red", linewidth=2, labels="vs")
# Plot discontinuities
n = 1
for i in M.dindex
    plot!(H, [0.0, maximum(M.vp)], -M.r[i]*[1, 1], c="black", line=:dash, linewidth=1, labels="") # No labels
    # plot!(H, [0.0, maximum(M.vp)], -M.r[i]*[1, 1], c="black", line=:dash, linewidth=1, labels=M.discontinuity[n]) # Labels
    n += 1
end
display(H)


# Plot some ray paths
P = plot(title = "Ray Paths", proj=:polar, axis=([], false))
# Plot surface and outer- and inner-core boundaries
θ = range(start=0.0, stop = 2.0*π, length = 361)
R = range(start=1.0, stop = 1.0, length = 361)
plot!(P, θ, M.r[end]*R, c="black", linewidth=2, labels="") # Surface
plot!(P, θ, (M.r[end] - M.r[M.dindex[6]])*R, c="black", linewidth=1, labels="") # Outer-core
plot!(P, θ, (M.r[end] - M.r[M.dindex[7]])*R, c="black", linewidth=1, labels="") # Inner-core
# Compute and plot a P and SKS ray path
PathObj = buildPathObj("prem")
d, r, _ = taup_path!(PathObj, "P", 55.0, 0.0, 0.0)
# Place source at north pole
plot!(P, deg2rad.(90.0 .- d), M.r[end] .- r, c="blue", linewidth=2, labels="P")
d, r, _ = taup_path!(PathObj, "SKS", 110.0, 50.0, 0.0)
plot!(P, deg2rad.(90.0 .- d), M.r[end] .- r, c="red", linewidth=2, labels="SKS")