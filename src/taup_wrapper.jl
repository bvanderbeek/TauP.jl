# TAUP_WRAPPER
# + These functions are intended to mimic the behaviour of TauP command-line tools.
# + Input argument types are so explicit to match declarations in original Java version of TauP.

##### TAUP_TIME #####

"""
    taup_time(phase::Union{String,Vector{String}}, arc_degrees::Float64, source_depth::Float64 = 0.0;
    receiver_depth::Float64 = 0.0, model::String = "prem", azim::Float64 = 0.0, verbose = false)

A wrapper to the Java taup_time method that returns travel-times, ray parameters, incidence and take-off angles
stored in an OutTimeTauP structure.

All angles are defined in degrees. All depths are positive and specified in kilometers.

The optional argument `azim` defines the source-to-receiver bearing to store in the OutTimeTauP structure. This
angle is required to retrieve the geographic coordinates of the source and receiver but is otherwise
inconsequential for the taup_time calculations.

If `verbose = true`, prints results in TauP-like table to the commad-line.

"""
function taup_time(phase::Union{String,Vector{String}}, arc_degrees::Float64, source_depth::Float64 = 0.0;
    receiver_depth::Float64 = 0.0, model::String = "prem", azim::Float64 = 0.0, verbose = false)

    # Must pass array of phases. The String option is for single-phase convenience.
    if typeof(phase) == String
        phase = [phase]
    end

    # Build TauP_Time Object
    TimeObj = TimeClass((JavaCall.JString,), model)

    # Set calculation parameters
    JavaCall.jcall(TimeObj, "setPhaseNames", Nothing, (Array{JavaCall.JString,1},), phase)
    JavaCall.jcall(TimeObj, "setSourceDepth", Nothing, (JavaCall.jdouble,), source_depth)
    JavaCall.jcall(TimeObj, "setReceiverDepth", Nothing, (JavaCall.jdouble,), receiver_depth)

    # Compute travel-times
    JavaCall.jcall(TimeObj, "calculate", Nothing, (JavaCall.jdouble,), arc_degrees)

    # Extract number of arrivals returned
    N = JavaCall.jcall(TimeObj, "getNumArrivals", JavaCall.jint, ())
    # Fill return structure
    TimeTauP = OutTimeTauP(model, N, arc_degrees, source_depth, azim)
    for j in 1:N
        # Extract Arrival Object
        ArrivalObj = JavaCall.jcall(TimeObj, "getArrival", ArrivalClass, (JavaCall.jint,), j - 1)
        # Extract travel-time (s)
        TimeTauP.t[j] = JavaCall.jcall(ArrivalObj, "getTime", JavaCall.jdouble, ())
        # Extract ray parameter (s/rad)
        TimeTauP.p[j] = JavaCall.jcall(ArrivalObj, "getRayParam", JavaCall.jdouble, ())
        TimeTauP.p[j] = TimeTauP.p[j]*π/180.0 # Convert to s/deg
        # Extract incident angle (degrees)
        TimeTauP.θᵢ[j] = JavaCall.jcall(ArrivalObj, "getIncidentAngle", JavaCall.jdouble, ())
        # Extract takeoff angle (degrees)
        TimeTauP.θₜ[j] = JavaCall.jcall(ArrivalObj, "getTakeoffAngle", JavaCall.jdouble, ())
        # Extract phase name
        TimeTauP.phase[j] = JavaCall.jcall(ArrivalObj, "getName", JavaCall.JString, ())
    end
    # Throw warning if no phases returned
    if N == 0
        phase_str = join(phase, ", ")
        @warn "No " * phase_str * " phase(s) predicted for given parameters."
    end
    # Throw warning for non-unique arrivals
    if N > length(phase)
        @warn "Multiple arrivals for single phase returned (i.e. more arrivals than phases requested)."
    end
    # Print TauP-like screen output
    if verbose
        print_OutTimeTauP(TimeTauP)
    end

    return TimeTauP
end
"""
    taup_time(phase::Union{String,Vector{String}}, source_lat::Float64, source_lon::Float64,
    source_depth::Float64, receiver_lat::Float64, receiver_lon::Float64;
    receiver_depth::Float64 = 0.0, model::String = "prem")

Specify source and receiver geographic coordinates rather than arc distance for taup_time calculations.
"""
function taup_time(phase::Union{String,Vector{String}}, source_lat::Float64, source_lon::Float64,
    source_depth::Float64, receiver_lat::Float64, receiver_lon::Float64;
    receiver_depth::Float64 = 0.0, model::String = "prem")

    # Convert to arc-distance and call taup_time
    Δ, α = taup_geoinv(source_lat, source_lon, receiver_lat, receiver_lon)
    TimeTauP = taup_time(phase, Δ, source_depth; receiver_depth = receiver_depth, model = model, azim = α)
    return TimeTauP
end

"""
    print_OutTimeTauP(TimeTauP::OutTimeTauP)

Prints summary of taup_time calculations to screen.
"""
function print_OutTimeTauP(TimeTauP::OutTimeTauP)
    # Round distance and depth for display
    Δ = round(TimeTauP.Δ, digits = 3)
    h = round(TimeTauP.h, digits = 1)
    printstyled("    Model: " * TimeTauP.model * " \n"; bold = true)
    printstyled("    Depth: $h (km) \n"; bold = true)
    printstyled(" Distance: $Δ (deg) \n"; bold = true)
    println(" Phase Name   Travel-time (s)   Ray Param (s/deg)   Takeoff (deg)   Incident (deg)")
    println(" ---------------------------------------------------------------------------------")
    for i in 1:TimeTauP.N
        t = string(round(TimeTauP.t[i], digits = 3))
        p = string(round(TimeTauP.p[i], digits = 3))
        θₜ = string(round(TimeTauP.θₜ[i], digits = 2))
        θᵢ = string(round(TimeTauP.θᵢ[i], digits = 2))
        print(" " *TimeTauP.phase[i] * " "^(13 - length(TimeTauP.phase[i])))
        print(t * " "^(18 - length(t)))
        print(p * " "^(20 - length(p)))
        print(θₜ * " "^(16 - length(θₜ)))
        println(θᵢ * " "^(14 - length(θᵢ)))
    end
end



##### TAUP_PATH #####

"""
    taup_path(phase::Union{String,Vector{String}}, arc_degrees::Float64, source_depth::Float64 = 0.0;
    receiver_depth::Float64 = 0.0, model::String = "prem", azim::Float64 = 0.0)

A wrapper to the Java taup_path method that returns ray paths stored in an OutPathTauP structure.

All angles are defined in degrees. All depths are positive and specified in kilometers.

The optional argument `azim` defines the source-to-receiver bearing to store in the OutPathTauP structure. This
angle is required to retrieve the geographic coordinates of the ray path but is otherwise inconsequential for
the taup_time calculations.
"""
function taup_path(phase::Union{String,Vector{String}}, arc_degrees::Float64, source_depth::Float64 = 0.0;
    receiver_depth::Float64 = 0.0, model::String = "prem", azim::Float64 = 0.0)

    # Must pass array of phases. The String option is for single-phase convenience.
    if typeof(phase) == String
        phase = [phase]
    end

    # Build TauP_Path Object
    PathObj = PathClass((JavaCall.JString,), model)

    # Set calculation parameters
    JavaCall.jcall(PathObj, "setPhaseNames", Nothing, (Array{JavaCall.JString,1},), phase)
    JavaCall.jcall(PathObj, "setSourceDepth", Nothing, (JavaCall.jdouble,), source_depth)
    JavaCall.jcall(PathObj, "setReceiverDepth", Nothing, (JavaCall.jdouble,), receiver_depth)

    # Call computation
    JavaCall.jcall(PathObj, "calculate", Nothing, (JavaCall.jdouble,), arc_degrees)

    # Extract number of rays returned
    N = JavaCall.jcall(PathObj, "getNumArrivals", JavaCall.jint, ())
    # Fill return structure
    PathTauP = OutPathTauP(model, N, arc_degrees, source_depth, azim)
    for j in 1:N
        # Extract Arrival Object
        ArrivalObj = JavaCall.jcall(PathObj, "getArrival", ArrivalClass, (JavaCall.jint,), j - 1)
        # Get the number of points in the path
        M = JavaCall.jcall(ArrivalObj, "getNumPathPoints", JavaCall.jint, ())
        # Extract phase for jᵗʰ-arrival
        PathTauP.phase[j] = JavaCall.jcall(ArrivalObj, "getName", JavaCall.JString, ())
        # Pre-allocate for ray-path point extraction
        PathTauP.d[j] = Vector{Float64}(undef,M)
        PathTauP.r[j] = Vector{Float64}(undef,M)
        PathTauP.t[j] = Vector{Float64}(undef,M)
        PathTauP.ϕ[j] = Vector{Float64}(undef,M)
        PathTauP.λ[j] = zeros(M)
        for k in 1:M
            TimeDistObj = JavaCall.jcall(ArrivalObj, "getPathPoint", TimeDistClass, (JavaCall.jint,), k - 1)
            PathTauP.d[j][k] = JavaCall.jcall(TimeDistObj, "getDistDeg", JavaCall.jdouble, ())
            PathTauP.r[j][k] = JavaCall.jcall(TimeDistObj, "getDepth", JavaCall.jdouble, ())
            PathTauP.t[j][k] = JavaCall.jcall(TimeDistObj, "getTime", JavaCall.jdouble, ())
            PathTauP.ϕ[j][k] = PathTauP.d[j][k]
        end
    end
    # Throw warning if no phases returned
    if N == 0
        phase_str = join(phase, ", ")
        @warn "No " * phase_str * " phase(s) predicted for given parameters."
    end
    # Throw warning for non-unique arrivals
    if N > length(phase)
        @warn "Multiple arrivals for single phase returned (i.e. more arrivals than phases requested)."
    end

    return PathTauP
end
"""
    taup_path(phase::Union{String,Vector{String}}, source_lat::Float64, source_lon::Float64,
    source_depth::Float64, receiver_lat::Float64, receiver_lon::Float64;
    receiver_depth::Float64 = 0.0, model::String = "prem")

Specify source and receiver geographic coordinates rather than arc distance for taup_path calculations.
"""
function taup_path(phase::Union{String,Vector{String}}, source_lat::Float64, source_lon::Float64,
    source_depth::Float64, receiver_lat::Float64, receiver_lon::Float64;
    receiver_depth::Float64 = 0.0, model::String = "prem")

    # Convert to arc-distance and call taup_path
    Δ, α = taup_geoinv(source_lat, source_lon, receiver_lat, receiver_lon)
    PathTauP = taup_path(phase, Δ, source_depth; receiver_depth = receiver_depth, model = model, azim = α)
    # Compute geographic coordinates of ray
    for i in 1:PathTauP.N
        # Allocate arrays
        PathTauP.ϕ[i] = similar(PathTauP.d[i])
        PathTauP.λ[i] = similar(PathTauP.d[i])
        for j in eachindex(PathTauP.d[i])
            ϕⱼ, λⱼ = taup_geofwd(source_lat, source_lon, PathTauP.d[i][j], α)
            PathTauP.ϕ[i][j] = ϕⱼ
            PathTauP.λ[i][j] = λⱼ
        end
    end

    return PathTauP
end



##### UTILITIES #####

"""
    taup_geoinv(ϕ₁::Float64, λ₁::Float64, ϕ₂::Float64, λ₂::Float64)

A wrapper for TauP's implementation of the inverse geodesic problem that returns the arc distance `Δ`
and bearing `α` between two points given their latitude, `ϕ`, annd longitude `λ`.

All angles defined in degrees.

"""
function taup_geoinv(ϕ₁::Float64, λ₁::Float64, ϕ₂::Float64, λ₂::Float64)
    Δ = JavaCall.jcall(SphericalClass, "distance", JavaCall.jdouble,
    (JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,), ϕ₁, λ₁, ϕ₂, λ₂)

    α = JavaCall.jcall(SphericalClass, "azimuth", JavaCall.jdouble,
    (JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,), ϕ₁, λ₁, ϕ₂, λ₂)

    return Δ, α
end

"""
    taup_geofwd(ϕ₀::Float64, λ₀::Float64, Δ::Float64, α::Float64)

A wrapper for TauP's implementation of the forward geodesic problem that returns the latitude, `ϕ₁`
and longitude, `λ₁`, of the final point along a great circle arc given a starting position (`ϕ₀`, `λ₀`)
an arc distance, `Δ`, and bearing `α`.

All angles are in degrees.
"""
function taup_geofwd(ϕ₀::Float64, λ₀::Float64, Δ::Float64, α::Float64)
    ϕ₁ = JavaCall.jcall(SphericalClass, "latFor", JavaCall.jdouble,
    (JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,), ϕ₀, λ₀, Δ, α)

    λ₁ = JavaCall.jcall(SphericalClass, "lonFor", JavaCall.jdouble,
    (JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,JavaCall.jdouble,), ϕ₀, λ₀, Δ, α)

    return ϕ₁, λ₁
end
