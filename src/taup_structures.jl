# Custom structures for storing TauP-related data

# OutTimeTauP: Struct to store output of taup_time calculations
struct OutTimeTauP{T}
    model::String # Name of reference model
    N::T # Number of arrivals (TauP tends to return Int32, hence the type parameter)
    Δ::Float64 # Source-receiver range (deg)
    h::Float64 # Source depth (km)
    α::Float64 # Source-receiver azimuth (deg)
    t::Vector{Float64} # Travel-time (s)
    p::Vector{Float64} # Ray parameter (s/deg)
    θᵢ::Vector{Float64} # Incidence angle (deg)
    θₜ::Vector{Float64} # Take-off angle (deg)
    phase::Vector{String} # Phases returned
    # Inner constructor method to initialize OutTimeTauP given number
    # of arrivals (N), range (Δ), and source-receiver azimuth (α)
    function OutTimeTauP(model, N, Δ, h, α = 0.0)
        # Create OutTimeTauP
        new{typeof(N)}(model, N, Δ, h, α, Vector{Float64}(undef,N), Vector{Float64}(undef,N), Vector{Float64}(undef,N),
        Vector{Float64}(undef,N), Vector{String}(undef,N))
    end
end

# OutPathTauP: Struct to store output of taup_path calculations
struct OutPathTauP{T}
    model::String # Name of reference model
    N::T # Number of arrivals (TauP tends to return Int32, hence the type parameter)
    Δ::Float64 # Source-receiver range (deg)
    h::Float64 # Source depth (km)
    α::Float64 # Source-receiver azimuth (deg)
    d::Vector{Vector{Float64}} # Raypath arc distances (deg)
    r::Vector{Vector{Float64}} # Raypath radial depths (km)
    t::Vector{Vector{Float64}} # Travel-time along ray path (s)
    ϕ::Vector{Vector{Float64}} # Raypath latitude (deg)
    λ::Vector{Vector{Float64}} # Raypath longitude (deg)
    phase::Vector{String} # Raypath phase
    # Inner constructor method to initialize OutPathTauP given number
    # of arrivals (N) and source-receiver azimuth (α)
    function OutPathTauP(model, N, Δ, h, α = 0.0)
        # Create OutPathTauP
        new{typeof(N)}(model, N, Δ, h, α, Vector{Vector{Float64}}(undef,N), Vector{Vector{Float64}}(undef,N), Vector{Vector{Float64}}(undef,N),
        Vector{Vector{Float64}}(undef,N), Vector{Vector{Float64}}(undef,N), Vector{String}(undef,N))
    end
end

# VelocityModelTauP: Struct to store TauP velocity model
struct VelocityModelTauP
    file::String # File used to generate model structure
    r::Vector{Float64} # Radial depth (km)
    vp::Vector{Float64} # Compressional velocity (km/s)
    vs::Vector{Float64} # Shear velocity (km/s)
    ρ::Vector{Float64} # Density (g/cm³)
    Qp::Vector{Float64} # Compressional quality factor
    Qs::Vector{Float64} # Shear quality factor
    dindex::Vector{Int} # First index of discontinuity
    discontinuity::Vector{String} # Name of discontinuity
end