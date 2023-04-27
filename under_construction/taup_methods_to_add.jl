##### TAUP_CREATE #####

# Creates a .taup model file from a model stored as a text file following the .nd or .tvel format
# Creating a model in this way gives more control over computation parameters related to the model.
# Defaults are taken from the TauP manual (see Section 3.1). These defaults are used in model
# creation in general if there is no .taup file with defaults found in the home or current directory.
function taup_create(filename::String; model_dir::String = ".", minDeltaP = 0.1, maxDeltaP = 11.0,
    maxDepthInterval = 115.0, maxRangeInterval = 2.5, maxInterpError = 0.05, allowInnerCoreS = true)
    # Identify file type (.nd or .tvel)
    ftype = split(filename,".")
    ftype = ftype[end]
    if (ftype == "nd") || (ftype == "tvel")
        # This function runs without error but the does not seem to implement any of the
        # passed options except the velocity model. For example, regardless of model_in,
        # it sames the taup-model in the current directory.
        error("Wrapper for taup_create is broken...output taup-file does not reflect input parameters.")
        # Build a TauP_Create object
        ModelCreateObj = ModelCreateClass()
        # Update velocity type name and name fields
        JavaCall.jcall(ModelCreateObj, "setVelFileType", Nothing, (JavaCall.JString,), ftype)
        JavaCall.jcall(ModelCreateObj, "setModelFilename", Nothing, (JavaCall.JString,), filename)

        # Build VelocityModel object
        VelocityModelObj = JavaCall.jcall(ModelLoadClass, "loadVelocityModel", VelocityModelClass, (JavaCall.JString,), filename)
        # Print the minimum and maximum radii of this model for double checking
        rmin = JavaCall.jcall(VelocityModelObj, "getMinRadius", JavaCall.jdouble, ())
        rmax = JavaCall.jcall(VelocityModelObj, "getMaxRadius", JavaCall.jdouble, ())
        println("Min. Radius: $rmin")
        println("Max. Radius: $rmax")

        # Add to the TauP_Create object
        JavaCall.jcall(ModelCreateObj, "setVelocityModel", Nothing, (VelocityModelClass,), VelocityModelObj)
        # Set the remaining TauP_Create object fields
        JavaCall.jcall(ModelCreateObj, "setDirectory", Nothing, (JavaCall.JString,), model_dir)
        JavaCall.jcall(ModelCreateObj, "setMinDeltaP", Nothing, (JavaCall.jfloat,), minDeltaP)
        JavaCall.jcall(ModelCreateObj, "setMaxDeltaP", Nothing, (JavaCall.jfloat,), maxDeltaP)
        JavaCall.jcall(ModelCreateObj, "setMaxDepthInterval", Nothing, (JavaCall.jfloat,), maxDepthInterval)
        JavaCall.jcall(ModelCreateObj, "setMaxRangeInterval", Nothing, (JavaCall.jfloat,), maxRangeInterval)
        JavaCall.jcall(ModelCreateObj, "setMaxInterpError", Nothing, (JavaCall.jfloat,), maxInterpError)
        JavaCall.jcall(ModelCreateObj, "setAllowInnerCoreS", Nothing, (JavaCall.jboolean,), allowInnerCoreS)

        # Export the model
        JavaCall.jcall(ModelCreateObj,"start",Nothing,())
    else
        error("Unrecognized velocity model file type, '" * ftype * "'. Options are 'nd' or 'tvel'.")
    end

    return nothing
end