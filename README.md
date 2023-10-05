# TauP.jl
A Julia wrapper for the [TauP Toolkit](https://www.seis.sc.edu/taup/), a Java Package for the calculation of seismic travel-times, ray paths, and related quantities through 1D spherical Earth velocity models ([GitHub Repo](https://github.com/crotwell/TauP)).

Goal of this project is to provide TauP's functionality inside Julia. At present, this package includes Julia wrappers to `taup_time` (calculation of seismic travel-times, ray parameters, incidence and take-off angles) and `taup_path` (calculation of ray paths and along-ray travel-time information) and supports the placement of receivers below Earth's surface. Additionaly, Julia wrappers to TauP's geodsic methods and functions for reading and writing TauP model files are provided. Wrappers are built using [JavaCall.jl](https://github.com/JuliaInterop/JavaCall.jl).

For examples on how to use TauP.jl, see `tutorial.jl`.

Note that an older wrapper package for TauP named [TauPy.jl](https://github.com/anowacki/TauPy.jl) is available. However, `TauPy` is a Julia wrapper of a Python wrapper found in the [ObsPy](https://docs.obspy.org/) package for calling TauP's time and path methods. The motivation for this project was to create an updated and pure Julia wrapper for TauP. Those familiar with ObsPy may want to consider `TauPy` depending on their use case.


# Installation
The package is part of the Julia General Registetry and can be istalled via the package manager:
```julia
julia> import Pkg
julia> Pkg.add("TauP")
```

`TauP.jl` ships with the latest version of TauP that has been tested with the wrappers (currently v2.6.1). By default, this local version of TauP will be used by the wrappers unless the environnment variable `TAUP_JAR` is defined. In this case, `TAUP_JAR` should hold the the path to the desired TauP jar-file. This can be defined from a julia session prior to loading the TauP.jl package as follows:
```julia
julia> ENV["TAUP_JAR"] = "path to TauP jar-file"
```

## Attention Non-Windows Users!
For JavaCall to function properly, please set the environment variable `JULIA_COPY_STACKS = 1` before starting Julia. See [JavaCall documentation](https://github.com/JuliaInterop/JavaCall.jl) for more details.

Additionally, MacOS users must start Julia with the flag `julia --handle-signals=no` to avoid Java-related segmentation faults.

# Quick Start Guide
For those familiar with TauP, using the Julia wrappers should be intuitive. For example, the following calculates travel-times through the IASP91 reference model for direct P and S phases for a source-receiver distance of 55 degrees and a source depth of 100 km,

```julia
julia> using TauP
julia> TimeTauP = taup_time(["P","S"], 55.0, 100.0; model = "iasp91", verbose = true)
    Model: iasp91 
    Depth: 100.0 (km) 
 Distance: 55.0 (deg) 
 Phase Name   Travel-time (s)   Ray Param (s/deg)   Takeoff (deg)   Incident (deg)
 ---------------------------------------------------------------------------------
 P            560.843           7.202               31.98           22.07         
 S            1015.837          13.365              33.27           23.82
```

The option `verbose = true` enables TauP-like screen output of the results which are stored in the TimeTauP structure.

If performance is important or cleaner output is desired, a lower-level syntax designed for single-phase calculations can be used. For example,
```julia
julia> TimeObj = buildTimeObj("prem") # Build TauP Time object for PREM model
julia> set_taup_phase!(TimeObj, "P") # Set calculation parameters
julia> set_taup_source_depth!(TimeObj, 100.0)
julia> set_taup_receiver_depth!(TimeObj, 0.0)
julia> t, p, i, j = taup_time!(TimeObj, 55.0) # Call taup_time
```
Here, `TimeObj` is a structure corresponding to TauP's Time object that contains all the relevant information for running `taup_time`. A tuple of arguments is returned with the travel-time `t`, ray parameter `p`, incidence angle `i`, and take-off angle `j`.

Note that `TimeObj` is modified in the call to `taup_time!` to contain the relevant travel-time information. However, the same `TimeObj` may still be used on subsequent calculations and its calculation parameters may be updated via various set_* functions.

For convenience, a variety of methods for different input arguments (e.g., geographic source and receiver positions) are also implemented. See function help for details.

For more examples, see `tutorial.jl`.


# Contributing
Any comments on how the package may be improved or any additions to the package (e.g., new wrappers for other TauP methods such as taup_pierce) are welcome. Please open a GitHub issue or pull request.
