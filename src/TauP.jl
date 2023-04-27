module TauP
# TauP: A Julia wrapper for the TauP Toolkit, a Java Package for the calculation
# of seismic travel-times, ray paths, and related quantities through 1D spherical
# Earth velocity models.
#
# Latest release of the TauP Toolkit is hosted by the Seismology
# Group at the University of South Carolina and may be downloaded
# from: https://www.seis.sc.edu/taup/
#
# FUTURE DEVELOPMENTS
# + Continue to build wrappers for other TauP methods
# -> The taup_pierce method would be a particularly useful addition
# + Add plotting functions
# -> Useful for easy plotting of ray paths and velocity models
# + Define the .taup parameter file (see Section 3.1 of TauP manual)
# -> Defines default parameters that control TauP accuarcy etc.


# Dependencies
import JavaCall

# Included files
include("taup_structures.jl")
include("taup_wrapper.jl")
include("taup_fuctions.jl")

# Export list
export taup_time, taup_path
export taup_time!, taup_path!
export buildTimeObj, buildPathObj
export taup_geoinv, taup_geofwd, load_taup_model, write_taup_model
export set_taup_source_depth!, set_taup_receiver_depth!, set_taup_phase!, set_taup_model!
export get_taup_source_depth, get_taup_receiver_depth, get_taup_phase, get_taup_model_name

# Import TauP Java Classes
# Core Classes
const TimeClass      = JavaCall.@jimport edu.sc.seis.TauP.TauP_Time
const ArrivalClass   = JavaCall.@jimport edu.sc.seis.TauP.Arrival
const PathClass      = JavaCall.@jimport edu.sc.seis.TauP.TauP_Path
const TimeDistClass  = JavaCall.@jimport edu.sc.seis.TauP.TimeDist
# Model classes
const ModelClass         = JavaCall.@jimport edu.sc.seis.TauP.TauModel
const ModelLoadClass     = JavaCall.@jimport edu.sc.seis.TauP.TauModelLoader
const ModelCreateClass   = JavaCall.@jimport edu.sc.seis.TauP.TauP_Create
const VelocityModelClass = JavaCall.@jimport edu.sc.seis.TauP.VelocityModel
# Utility Classes
const SphericalClass = JavaCall.@jimport edu.sc.seis.TauP.SphericalCoords

# Initialisation
function __init__()

    # Define path to TauP jar-file in environment variable
    if ~haskey(ENV,"TAUP_JAR")
        taup_jar = pathof(@__MODULE__)
        taup_jar = split(taup_jar, "TauP/")
        taup_jar = taup_jar[1] * "TauP/TauP-2.6.1/lib/TauP-2.6.1.jar"
        ENV["TAUP_JAR"] = taup_jar
    end
    # Check file exists
    if isfile(ENV["TAUP_JAR"])
        println("Using TauP jar-file: " * ENV["TAUP_JAR"])
    else
        error("Could not locate TauP jar-file. Please define the 'TAUP_JAR' environment variable.")
    end

    # Setup Java Virtual Machine
    # Add TauP jar-file to class path
    JavaCall.addClassPath(ENV["TAUP_JAR"])
    # Initialise JVM
    JavaCall.init()
end

end