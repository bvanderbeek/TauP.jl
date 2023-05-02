# Benchmarks
# Simple benchmarks to compare TauP wrapper functions to simplified functions
# Preformance increase only for taup_time

# To switch TauP versions...
delete!(ENV, "TAUP_JAR");
# ENV["TAUP_JAR"] = "/Users/bvanderbeek/research/software/TauP-2.4.5/lib/TauP-2.4.5.jar";

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
taup_time!(TimeObj, phase, Δ, z₀, z₁);
taup_time!(TimeObj, Δ);
# Benchmark
@benchmark taup_time($phase, $Δ, $z₀; receiver_depth = $z₁, model = $model) # ~200 μs
@benchmark taup_time!($TimeObj, $Δ) # ~75 μs

# Compile taup_path methods
taup_path(phase, Δ, z₀; receiver_depth = z₁, model = model);
PathObj = buildPathObj(model);
taup_path!(PathObj, phase, Δ, z₀, z₁);
taup_path!(PathObj, Δ);
# Benchmark
@benchmark taup_path($phase, $Δ, $z₀; receiver_depth = $z₁, model = $model) # ~5 ms
@benchmark taup_path!($PathObj, $Δ) # ~5 ms


# What is the slow part of taup_path?
import JavaCall
@benchmark JavaCall.jcall($PathObj, "calculate", Nothing, (JavaCall.jdouble,), $Δ)

JavaCall.jcall(PathObj, "calculate", Nothing, (JavaCall.jdouble,), Δ);
@benchmark JavaCall.jcall($PathObj, "getArrival", TauP.ArrivalClass, (JavaCall.jint,), 0)

ArrivalObj = JavaCall.jcall(PathObj, "getArrival", TauP.ArrivalClass, (JavaCall.jint,), 0);
M = JavaCall.jcall(ArrivalObj, "getNumPathPoints", JavaCall.jint, ());
# Constructing the TimeDistObj appears to be the issue.
# Requires 46 allocations for every point (typically > 100 points)
@benchmark JavaCall.jcall($ArrivalObj, "getPathPoint", TauP.TimeDistClass, (JavaCall.jint,), 10)