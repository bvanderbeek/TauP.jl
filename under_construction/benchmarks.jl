# Benchmarks
# Simple benchmarks to compare TauP wrapper functions to simplified functions
# Preformance increase only for taup_time

# To switch TauP versions...
# delete!(ENV, "TAUP_JAR")
# ENV["TAUP_JAR"] = "/Users/bvanderbeek/research/software/TauP-2.4.5/lib/TauP-2.4.5.jar"

# Load Packages
using TauP
using BenchmarkTools

# Define some inputs
model = "iasp91"
phase = "P"
Δ = 55.0
z₀ = 50.0
z₁ = 0.0

# Compile taup_time methods
taup_time(phase, Δ, z₀; receiver_depth = z₁, model = model, verbose = true);
TimeObj = buildTimeObj(model);
taup_time!(TimeObj,phase,Δ,z₀,z₁);
taup_time!(TimeObj,Δ);
# Benchmark
@btime taup_time($phase, $Δ, $z₀; receiver_depth = $z₁, model = $model); # ~200 μs
@btime taup_time!($TimeObj,$Δ); # ~75 μs

# Compile taup_path methods
taup_path(phase, Δ, z₀; receiver_depth = z₁, model = model);
PathObj = buildPathObj(model);
taup_path!(PathObj,phase,Δ,z₀,z₁);
taup_path!(PathObj,Δ);
# Benchmark
@btime taup_path($phase, $Δ, $z₀; receiver_depth = $z₁, model = $model); # ~5 ms
@btime taup_path!($PathObj,$Δ); # ~5 ms
