# TAUP_FUNCTIONS
# + Restructured TauP methods into functions designed to operate on a single seismic phase and return
#   a tuple of computed values rather than cumbersome structures that may contain multiple phases.
# + These functions are slightly more performative than those in taup_wrapper.jl because they do not
#   require building Java objects on each call.

# TRAVEL-TIME, RAY PARAMETER, INCIDENCE ANGLES

"""
    t, p, i, j = taup_time!(TimeObj::JavaCall.JavaObject, arc_degrees)

Given a TauP Time object `TimeObj` and a source-receiver range `arc_degrees`, returns the
travel-time `t`, ray parameter `p`, incidence `i` and take-off `j` angle for the
calculation parameters specified in TimeObj.

Note that `TimeObj` is modified to include travel-time information from the TauP calculation.

All angular quantities are in degrees.
"""
function taup_time!(TimeObj::JavaCall.JavaObject, arc_degrees)
    # Compute times
    JavaCall.jcall(TimeObj, "calculate", Nothing, (JavaCall.jdouble,), arc_degrees)

    # Extract number of arrivals returned
    N = JavaCall.jcall(TimeObj, "getNumArrivals", JavaCall.jint, ())
    if N > 0
        # Extract Arrival Object
        ArrivalObj = JavaCall.jcall(TimeObj, "getArrival", ArrivalClass, (JavaCall.jint,), 0)
        # Extract results
        t = JavaCall.jcall(ArrivalObj, "getTime", JavaCall.jdouble, ())
        p = JavaCall.jcall(ArrivalObj, "getRayParam", JavaCall.jdouble, ()) # s/rad
        p = p*π/180.0 # Convert to s/deg
        θᵢ = JavaCall.jcall(ArrivalObj, "getIncidentAngle", JavaCall.jdouble,())
        θₜ = JavaCall.jcall(ArrivalObj, "getTakeoffAngle", JavaCall.jdouble,())
        # Throw warning if multiple arrivals for single phase
        if N > 1
            phase = get_taup_phase(TimeObj)
            @warn "Mulitple " * phase * " phases predicted for given parameters. Returning first."
        end
    else
        t = NaN
        p = NaN
        θᵢ = NaN
        θₜ = NaN
        phase = get_taup_phase(TimeObj)
        @warn "No " * phase * " phase predicted for given parameters."
    end

    return t, p, θᵢ, θₜ
end
"""
    t, p, i, j = taup_time!(TimeObj::JavaCall.JavaObject, phase, arc_degrees, source_depth, receiver_depth)

Syntactically convenient method of `taup_time!(TimeObj, arc_degrees)` that sets the phase, source_depth, and
receiver depth parameters in the `TimeObj` from the input arguments and then performs the travel-time calulation.

Note that calculation parameters in `TimeObj` are updated.

All angles are in degrees and all depths are in kilometers with respect to the surface.
"""
function taup_time!(TimeObj::JavaCall.JavaObject, phase, arc_degrees, source_depth, receiver_depth)
    # Update calculation parameters
    set_taup_phase!(TimeObj, phase)
    set_taup_source_depth!(TimeObj, source_depth)
    set_taup_receiver_depth!(TimeObj, receiver_depth)

    return taup_time!(TimeObj, arc_degrees)
end
"""
    t, p, i, j = taup_time!(TimeObj::JavaCall.JavaObject, phase, source_lat, source_lon, source_depth, receiver_lat, receiver_lon, receiver_depth)

Syntactically convenient method of `taup_time!(TimeObj, arc_degrees)` that sets the phase, source depth, and
receiver depth parameters in the `TimeObj` given the source and receiver geographic coordinates and then performs
the travel-time calculation.

Note that calculation parameters in `TimeObj` are updated.

All angles are in degrees and all depths are in kilometers with respect to the surface.
"""
function taup_time!(TimeObj::JavaCall.JavaObject, phase, source_lat, source_lon, source_depth, receiver_lat, receiver_lon, receiver_depth)
    # Compute distance
    Δ, α = taup_geoinv(source_lat, source_lon, receiver_lat, receiver_lon)

    # Update calculation parameters
    set_taup_phase!(TimeObj, phase)
    set_taup_source_depth!(TimeObj, source_depth)
    set_taup_receiver_depth!(TimeObj, receiver_depth)

    return taup_time!(TimeObj, Δ), Δ, α
end



# RAY PATH
"""
    d, r, t = taup_path!(PathObj::JavaCall.JavaObject, arc_degrees; tf_correct_distance::Bool = true)

Given a TauP Path object `PathObj` and a source-receiver range `arc_degrees`, returns the ray path coordinates
in arc distance from source `d` and depth below the surface `r` as well as the travel-time along the path `t`
for the calculation parameters specified in `PathObj`.

The ray path end-point may not exactly coincide with `arc_degrees`. If `tf_correct_distance = true`, this will
be adjusted such that `d[end] = arc_degrees`.

Note that `PathObj` is modified to include ray information from the TauP calculation.

All angular quantities are in degrees.
"""
function taup_path!(PathObj::JavaCall.JavaObject, arc_degrees; tf_correct_distance::Bool = true)
    # Compute paths
    JavaCall.jcall(PathObj, "calculate", Nothing, (JavaCall.jdouble,), arc_degrees)
    # Extract number of rays returned
    N = JavaCall.jcall(PathObj, "getNumArrivals", JavaCall.jint, ())
    if N > 0
        # Extract first Arrival object
        ArrivalObj = JavaCall.jcall(PathObj, "getArrival", ArrivalClass, (JavaCall.jint,), 0)
        # Get the number of points in the path
        M = JavaCall.jcall(ArrivalObj, "getNumPathPoints", JavaCall.jint, ())
        # Extract and store ray path points
        d = Vector{Float64}(undef,M)
        r = Vector{Float64}(undef,M)
        t = Vector{Float64}(undef,M)
        for k in 1:M
            TimeDistObj = JavaCall.jcall(ArrivalObj, "getPathPoint", TimeDistClass, (JavaCall.jint,), k - 1)
            d[k] = JavaCall.jcall(TimeDistObj, "getDistDeg", JavaCall.jdouble, ())
            r[k] = JavaCall.jcall(TimeDistObj, "getDepth", JavaCall.jdouble, ())
            t[k] = JavaCall.jcall(TimeDistObj, "getTime", JavaCall.jdouble, ())
        end
        # TauP end point can be 10's of meters from input distance
        if tf_correct_distance
            d[end] = arc_degrees
            r[end] = get_taup_receiver_depth(PathObj)
            # No time correction
        end
        # Throw warning if multiple arrivals for single phase
        if N > 1
            phase = get_taup_phase(PathObj)
            @warn "Mulitple " * phase * " phases predicted for given parameters. Returning first."
        end
    else
        d = NaN
        r = NaN
        t = NaN
        phase = get_taup_phase(PathObj)
        @warn "No " * phase * " phase predicted for given parameters."
    end

    return d, r, t
end
"""
    d, r, t = taup_path!(PathObj::JavaCall.JavaObject, phase, arc_degrees, source_depth, receiver_depth; tf_correct_distance::Bool = true)

Syntactically convenient method of `taup_path!(TimeObj, arc_degrees)` that sets the phase, source_depth, and
receiver depth parameters in the `PathObj` from the input arguments and then performs the ray path calulation.

Note that calculation parameters in `PathObj` are updated.

All angles are in degrees and all depths are in kilometers with respect to the surface.
"""
function taup_path!(PathObj::JavaCall.JavaObject, phase, arc_degrees, source_depth, receiver_depth; tf_correct_distance::Bool = true)
    # Update calculation parameters
    set_taup_phase!(PathObj, phase)
    set_taup_source_depth!(PathObj, source_depth)
    set_taup_receiver_depth!(PathObj, receiver_depth)

    return taup_path!(PathObj, arc_degrees; tf_correct_distance = tf_correct_distance)
end
"""
    d, r, t, ϕ, λ, ϵ = taup_path!(PathObj::JavaCall.JavaObject, phase, source_lat, source_lon, source_depth,
    receiver_lat, receiver_lon, receiver_depth; tf_correct_distance::Bool = true)

Syntactically convenient method of `taup_path!(TimeObj, arc_degrees)` that sets the phase, source depth, and
receiver depth parameters in the `PathObj` given the source and receiver geographic coordinates as input
arguments and then performs the ray path calculation.

Additionally returns the latitude `ϕ` and longitude `λ` of the ray path and the distance between the receiver
location and final ray node `ϵ`. This can be non-zero due to rounding errors in TauP and the geodesic
calculations but is generally on the order of meters.

Note that calculation parameters in `PathObj` are updated.

All angles are in degrees and all depths are in kilometers with respect to the surface.
"""
function taup_path!(PathObj::JavaCall.JavaObject, phase, source_lat, source_lon, source_depth,
    receiver_lat, receiver_lon, receiver_depth; tf_correct_distance::Bool = true)
    # Compute distance
    Δ, α = taup_geoinv(source_lat, source_lon, receiver_lat, receiver_lon)

    # Update calculation parameters
    set_taup_phase!(PathObj, phase)
    set_taup_source_depth!(PathObj, source_depth)
    set_taup_receiver_depth!(PathObj, receiver_depth)

    # Get ray path
    d, r, t = taup_path!(PathObj, Δ; tf_correct_distance = tf_correct_distance)
    
    # Get ray path in geographic coordinates
    ϕ = similar(d)
    λ = similar(d)
    for i in eachindex(d)
        ϕ[i], λ[i] = taup_geofwd(source_lat, source_lon, d[i], α)
    end

    # Compute distance error at raypath end-point
    ϵ, _ = taup_geoinv(receiver_lat, receiver_lon, ϕ[end], λ[end])

    return d, r, t, ϕ, λ, ϵ
end



# OBJECT FIELDS

# Set/Get Source Depth
"""
    set_taup_source_depth!(ObjTauP::JavaCall.JavaObject, source_depth)

Sets the source depth parameter in a TauP object.
"""
function set_taup_source_depth!(ObjTauP::JavaCall.JavaObject, source_depth)
    return JavaCall.jcall(ObjTauP, "setSourceDepth", Nothing, (JavaCall.jdouble,), source_depth)
end
"""
    get_taup_source_depth(ObjTauP::JavaCall.JavaObject)

Returns the source depth parameter from a TauP object.
"""
function get_taup_source_depth(ObjTauP::JavaCall.JavaObject)
    return JavaCall.jcall(ObjTauP, "getSourceDepth", JavaCall.jdouble, ())
end


# Set/Get Receiver Depth
"""
    set_taup_receiver_depth!(ObjTauP::JavaCall.JavaObject, receiver_depth)

Sets the receiver depth parameter in a TauP object.
"""
function set_taup_receiver_depth!(ObjTauP::JavaCall.JavaObject, receiver_depth)
    return JavaCall.jcall(ObjTauP, "setReceiverDepth", Nothing, (JavaCall.jdouble,), receiver_depth)
end
"""
    get_taup_receiver_depth(ObjTauP::JavaCall.JavaObject)

Returns the receiver depth parameter in a TauP object.
"""
function get_taup_receiver_depth(ObjTauP::JavaCall.JavaObject)
    return JavaCall.jcall(ObjTauP, "getReceiverDepth", JavaCall.jdouble, ())
end


# Set/Get Phase
"""
    set_taup_phase!(ObjTauP::JavaCall.JavaObject, phase::String)

Sets the phase parameter in a TauP object.
"""
function set_taup_phase!(ObjTauP::JavaCall.JavaObject, phase::String)
    return JavaCall.jcall(ObjTauP, "setPhaseNames", Nothing, (Array{JavaCall.JString,1},), [phase])
end
"""
    get_taup_phase(ObjTauP::JavaCall.JavaObject)::String

Returns the phase parameter in a TauP object.
"""
function get_taup_phase(ObjTauP::JavaCall.JavaObject)::String # Compiler had issues determining type here hence the declaration
    return JavaCall.jcall(ObjTauP, "getPhaseNameString", JavaCall.JString, ())
end


# Set/Get Model
"""
    set_taup_model!(ObjTauP::JavaCall.JavaObject, refModel::String)

Sets the model in a TauP object.
"""
function set_taup_model!(ObjTauP::JavaCall.JavaObject, refModel::String)
    ModelObj = JavaCall.jcall(ModelLoadClass, "load", ModelClass, (JavaCall.JString,), refModel)
    return JavaCall.jcall(ObjTauP, "setTauModel", Nothing, (ModelClass,), ModelObj)
end
"""
    get_taup_model_name(ObjTauP::JavaCall.JavaObject)::String

Returns the model name in a TauP object.
"""
function get_taup_model_name(ObjTauP::JavaCall.JavaObject)::String # Compiler had issues determining type here hence the declaration
    return JavaCall.jcall(ObjTauP, "getTauModelName", JavaCall.JString, ())
end

# Object Building

"""
    buildTimeObj(model::String)

Initialises a TauP Time object given a reference model name or custom model file.
"""
function buildTimeObj(model::String)
    return TimeClass((JavaCall.JString,),model)
end

"""
    buildPathObj(model::String)

Initialises a TauP Path object given a reference model name or custom model file.
"""
function buildPathObj(model::String)
    return PathClass((JavaCall.JString,),model)
end



# MODEL READING/WRITING
"""
    load_taup_model(filename)

Read a TauP nd- or tvel-formated file and stores the model in a `VelocityModelTauP` structure.

Note that `filename` may be the name of a built-in TauP model (e.g., "prem" or "ak135") or a 
custom model file.

This is a rather simple brute-force function in which model data lines are identified as those
that begin with a digit and have at least 3 columns.

See TauP manual for more information on model file formats.
"""
function load_taup_model(filename)
    # Check if file exists
    if isfile(filename)
        # Check file type
        ftype = split(filename,'.')
        # Open if valid file, otherwise error
        if ~(ftype == "nd") || ~(ftype == "tvel")
            error("Unrecognized velocity model file type, '" * ftype * "'. Options are 'nd' or 'tvel'.")
        end
    else
        # If no file found, check if input is a standard TauP model name
        if (filename == "iasp91") || (filename == "ak135") || (filename == "qdt")
            ftype = "tvel"
            filename = filename * "." * ftype
        elseif ((filename == "1066a") || (filename == "1066b") || (filename == "alfs")
            || (filename == "herrin") || (filename == "jb") || (filename == "prem")
            || (filename == "pwdk") || (filename == "sp6"))
            ftype = "nd"
            filename = filename * "." * ftype
        else
            error("Cannot locate model, " * filename)
        end
        # Search for model in expected TauP location
        pathtaup = ENV["TAUP_JAR"]
        pathtaup = split(pathtaup,"/")
        pathtaup = join(pathtaup[1:end-2],"/")
        filename = pathtaup * "/src/main/resources/edu/sc/seis/TauP/StdModels/" * filename
        if ~isfile(filename)
            error("Cannot locate TauP model file, " * filename)
        end
    end
    # Read-in every line of the file
    L = readlines(filename)
    # Count number of potential data lines
    N = length(L)

    # Allocate storage arrays
    r  = zeros(N) # Radial depth (km)
    vp = zeros(N) # Compressional velocity (km/s)
    vs = zeros(N) # Shear velocity (km/s)
    ρ  = zeros(N) # Density (g/cm³)
    Qp = (1.0e6)*ones(N) # Compressional quality factor
    Qs = (1.0e6)*ones(N) # Shear quality factor
    ibad = falses(N) # Identifies bad data lines (i.e. commented lines)
    # For identifying and storing discontinuities
    rⱼ = -10.0 # Last data depth
    j = 0 # Last data line index
    k = 0 # Running count of data lines
    dindex = Vector{Int}() # Stores first index of discontinuity
    dname = Vector{String}() # Stores data number and discontinuity name
    # Loop over lines in file
    for i in 1:N
        # Process iᵗʰ-line of file (split on white space)
        line = split(L[i])
        # Length of split line must be greater than 2 to be a valid model line (i.e. r, vp, and vs columns)
        if length(line) > 2
            # First character must be a digit if a data line
            if isdigit(line[1][1])
                r[i] = parse(Float64,line[1])
                vp[i] = parse(Float64,line[2])
                vs[i] = parse(Float64,line[3])
                # Read in remaining model fields if present
                if length(line) > 4
                    ρ[i] = parse(Float64,line[4])
                    Qp[i] = parse(Float64,line[5])
                    Qs[i] = parse(Float64,line[6])
                elseif length(line) > 3
                    ρ[i] = parse(Float64,line[4])
                end
                # Discontinuity check: If previous depth matches current depth, we hit a discontinuity
                if r[i] == rⱼ
                    # Interpret lines interupting data as the discontinuity name. Default to "anonymous"
                    if j == (i - 1)
                        id = "anonymous"
                    else
                        id = L[i - 1]
                    end
                    # Add discontinuity index and name
                    # These arrays grow...but who cares for this convenience function
                    dindex = push!(dindex, k)
                    dname = push!(dname, id)
                end
                # Update counters
                rⱼ = r[i]
                j = i
                k += 1
            else
                # Non-data: Non-digit first character
                ibad[i] = true
            end
        else
            # Non-data: Incorrect number of columns
            ibad[i] = true
        end
    end
    # Subset results to only those lines with model data
    deleteat!(r,ibad)
    deleteat!(vp,ibad)
    deleteat!(vs,ibad)
    deleteat!(ρ,ibad)
    deleteat!(Qp,ibad)
    deleteat!(Qs,ibad)

    # Return model structure
    return VelocityModelTauP(filename, r, vp, vs, ρ, Qp, Qs, dindex, dname)
end


"""
    write_taup_model(filename::String, M::VelocityModelTauP; n::Int = 3, print_full_model::Bool = true)

Write a TauP nd- or tvel-formatted model (determined from the extension defined in `filename`) given a
`VelocityModelTauP` structure.

The `filename` should end in '.nd' to create a named-discontinuity model file or '.tvel'.

Optionally, one can specify the number of post-decimal digits to print to the model file by
specifying the argument `n`; default is `n = 3`.

If `print_full_model = true` (default), then the model file will include density and P and S
quality factor columns. Otherwise, only depth and P and S velocities are written.

See TauP manual for more information on model file formats.
"""
function write_taup_model(filename::String, M::VelocityModelTauP; n::Int = 3, print_full_model::Bool = true)
    # Check number of discontinuities
    nd = length(M.dindex)
    # Check if any have non-anonymous names. This determines the file type.
    if nd > 0
        if all(M.discontinuity .== "anonymous")
            ftype = ".tvel"
        else
            ftype = ".nd"
        end
        j = M.dindex[1] # First discontinuity index
    else
        ftype = ".tvel"
        j = 0
    end
    k = 1 # Index into discontinuity vectors

    # Open file
    fid = open(filename * ftype,"w")
    # Loop over depths in model
    for i in eachindex(M.r)
        # Construct iᵗʰ line
        line = [round(M.r[i], digits = n), round(M.vp[i], digits = n), round(M.vs[i], digits = n)]
        # Add lines to print full model
        if print_full_model
            line = append!(line, [round(M.ρ[i], digits = n), round(M.Qp[i], digits = n), round(M.Qs[i], digits = n)])
        end
        # Print to file
        println(fid,join(line, " "))
        # Print discontinuity name
        if i == j
            # Print the discontinuity name
            if ~(M.discontinuity[k] == "anonymous")
                println(fid,M.discontinuity[k])
            end
            # Update index
            k = min(k + 1, nd)
            j = M.dindex[k]
        end
    end
    # Close file
    close(fid)

    return nothing
end