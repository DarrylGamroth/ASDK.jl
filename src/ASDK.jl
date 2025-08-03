module ASDK

include("LibASDK.jl")

using .LibASDK
using CEnum

export DM, 
       ASDKException,
       Error,
       check_status,
       @check,
       send!,
       reset!,
       stop!,
       release!

# Base exception type for all ASDK errors
abstract type ASDKException <: Exception end

"""
    Error

ASDK-specific error type containing error number and message.

# Fields
- `errno::UInt32`: The error number returned by the ASDK library
- `errmsg::String`: The error message describing the error
"""
struct Error <: ASDKException
    errno::UInt32
    errmsg::String
end

"""
    check_status(status:::LibASDK.COMPL_STAT)

Check the status code from ASDK function calls and throw appropriate exceptions.
Only throw if not SUCCESS.
"""
function check_status(status::LibASDK.COMPL_STAT)
    if status != LibASDK.SUCCESS
        errno = Ref{UInt32}()
        errmsg = zeros(UInt8, 512)
        GC.@preserve errno errmsg begin
            asdkGetLastError(errno, pointer(errmsg), sizeof(errmsg))
        end
        errmsg[end] = 0
        throw(Error(errno[], String(@view errmsg[1:findfirst(iszero, errmsg)-1])))
    end
end

"""
    @check status_expr

Macro to check status code from an expression and throw appropriate exception if needed.
"""
macro check(status_expr)
    quote
        status = $(esc(status_expr))
        check_status(status)
    end
end

Base.showerror(io::IO, e::Error) = print(io, "ASDK Error ($(e.errno)): $(e.errmsg)")

"""
    DM(serialno::AbstractString)

Create a new deformable mirror (DM) instance.

Initialize the ALPAO SDK with the specified serial number and create a DM object
that can be used to control the deformable mirror.

# Arguments
- `serialno::AbstractString`: The serial number of the deformable mirror

# Returns
- `DM`: A new DM instance ready for use

# Throws
- `Error`: If the SDK initialization fails
- Any error during number of actuators retrieval

# Examples
```julia
dm = DM("BAL123")
try
    # Use the DM
finally
    close(dm)
end

# Or use with do-block syntax
open(DM, "BAL123") do dm
    # Use the DM
end
```
"""
mutable struct DM
    handle::Ptr{LibASDK.asdkDM}
    numberofactuators::Int

    function DM(serialno::AbstractString)
        handle = asdkInit(serialno)
        if handle == C_NULL
            error("Could not initialze the ALPAO SDK")
        end

        dm = new(handle)

        try
            dm.numberofactuators = ASDK.get(dm, "NbOfActuator")
        catch e
            release!(dm)
            rethrow(e)
        end

        return dm
    end
end

"""
    release!(dm::DM)

Release the resources associated with a deformable mirror.

This function releases the DM handle and cleans up associated resources.
After calling this function, the DM object should not be used.

# Arguments
- `dm::DM`: The deformable mirror to release

# Examples
```julia
dm = DM("BAL123")
# Use the DM...
release!(dm)  # Clean up
```
"""
function release!(context::DM)
    @check asdkRelease(context.handle)
    context.handle = C_NULL
    context.numberofactuators = -1
end

Base.open(::Type{DM}, serialno::AbstractString) = DM(serialno)
function Base.open(f::Function, ::Type{DM}, serialno::AbstractString)
    dm = DM(serialno)
    try
        f(dm)
    finally
        close(dm)
    end
end
Base.close(dm::DM) = release!(dm)
Base.isopen(dm::DM) = dm.handle != C_NULL

"""
    send!(dm::DM, value::Vector{T}) where {T<:Real}

Send actuator values to the deformable mirror.

This function sends a vector of actuator values to control the shape of the 
deformable mirror. The length of the value vector must match the number of 
actuators in the DM.

# Arguments
- `dm::DM`: The deformable mirror instance
- `value::Vector{T}`: Vector of actuator values (will be converted to Float64)

# Throws
- `Error`: If the number of elements doesn't match the number of actuators
- `Error`: If the SDK send operation fails

# Examples
```julia
dm = DM("BAL123")
values = zeros(dm.numberofactuators)  # Flat mirror
send!(dm, values)

# Or with specific shape
values = rand(dm.numberofactuators) * 0.1  # Random small deformation
send!(dm, values)
```
"""
function send!(context::DM, value::Vector{Float64})
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    
    if length(value) != context.numberofactuators
        error("Invalid number of elements in value")
    end

    @check asdkSend(context.handle, value)
end

function send!(context::DM, value::Vector{T}) where {T<:Real}
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    
    if length(value) != context.numberofactuators
        error("Invalid number of elements in value")
    end

    value_f64 = convert(Vector{LibASDK.Scalar}, value)
    @check asdkSend(context.handle, value_f64)
end

"""
    send!(dm::DM, value::Vector{T}, numpatterns, numrepeat=1) where {T<:Real}

Send multiple patterns to the deformable mirror for sequential playback.

This function sends multiple actuator patterns that will be played back 
sequentially by the DM. Useful for creating dynamic sequences of mirror shapes.

# Arguments
- `dm::DM`: The deformable mirror instance
- `value::Vector{T}`: Concatenated vector of all patterns
- `numpatterns`: Number of patterns in the value vector
- `numrepeat`: Number of times to repeat the sequence (default: 1)

# Throws
- `Error`: If the pattern size doesn't match the number of actuators
- `Error`: If the SDK send pattern operation fails

# Examples
```julia
dm = DM("BAL123")
# Create 3 patterns for a DM with 10 actuators
patterns = vcat(zeros(10), ones(10)*0.1, rand(10)*0.05)
send!(dm, patterns, 3, 2)  # Play 3 patterns, repeat twice
```
"""
function send!(context::DM, value::Vector{T}, numpatterns, numrepeat=1) where {T<:Real}
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    
    if length(value) / numpatterns != context.numberofactuators
        error("Invalid number of elements in value")
    end

    value_f64 = convert(Vector{LibASDK.Scalar}, value)
    @check asdkSendPattern(context.handle, value_f64, numpatterns, numrepeat)
end

"""
    reset!(dm::DM)

Reset the deformable mirror to its default state.

This function resets the DM actuators to their default positions, typically
resulting in a flat mirror surface.

# Arguments
- `dm::DM`: The deformable mirror to reset

# Throws
- `Error`: If the SDK reset operation fails

# Examples
```julia
dm = DM("BAL123")
# Apply some deformation...
send!(dm, rand(dm.numberofactuators))
# Reset to flat
reset!(dm)
```
"""
function reset!(context::DM)
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    @check asdkReset(context.handle)
end

"""
    stop!(dm::DM)

Stop any ongoing operations on the deformable mirror.

This function stops any currently running patterns or operations on the DM.

# Arguments
- `dm::DM`: The deformable mirror to stop

# Throws
- `Error`: If the SDK stop operation fails

# Examples
```julia
dm = DM("BAL123")
# Start a pattern sequence...
send!(dm, patterns, 10, 100)  # Long sequence
# Stop it early
stop!(dm)
```
"""
function stop!(context::DM)
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    @check asdkStop(context.handle)
end

"""
    get(dm::DM, command::AbstractString)

Get a scalar parameter value from the deformable mirror.

This function retrieves configuration parameters or status values from the DM.

# Arguments
- `dm::DM`: The deformable mirror instance
- `command::AbstractString`: The parameter name to retrieve

# Returns
- `Float64`: The parameter value

# Throws
- `Error`: If the parameter doesn't exist or SDK operation fails

# Examples
```julia
dm = DM("BAL123")
nact = get(dm, "NbOfActuator")  # Number of actuators
temp = get(dm, "Temperature")   # Current temperature (if available)

# Using indexing syntax (equivalent)
nact = dm["NbOfActuator"]
```
"""
function get(context::DM, command::AbstractString)
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    value = Ref{LibASDK.Scalar}()
    @check asdkGet(context.handle, command, value)
    return value[]
end

Base.getindex(context::DM, command::AbstractString) = get(context, command)

"""
    set!(dm::DM, command::AbstractString, value)

Set a parameter value on the deformable mirror.

This function sets configuration parameters on the DM. Supports scalar values,
vector values, and string values.

# Arguments
- `dm::DM`: The deformable mirror instance
- `command::AbstractString`: The parameter name to set
- `value`: The value to set (Real, Vector{Real}, or String)

# Throws
- `Error`: If the parameter doesn't exist or SDK operation fails

# Examples
```julia
dm = DM("BAL123")

# Set scalar parameter
set!(dm, "TriggerIn", 1.0)

# Set vector parameter
calibration = ones(dm.numberofactuators) * 0.5
set!(dm, "Calibration", calibration)

# Set string parameter
set!(dm, "ConfigFile", "/path/to/config.txt")

# Using indexing syntax (equivalent)
dm["TriggerIn"] = 1.0
dm["Calibration"] = calibration
```
"""
function set!(context::DM, command::AbstractString, value::T) where {T<:Real}
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    @check asdkSet(context.handle, command, value)
end

function set!(context::DM, command::AbstractString, value::Vector{T}) where {T<:Real}
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    value_f64 = convert(Vector{LibASDK.Scalar}, value)
    @check asdkSetVector(context.handle, command, value_f64, length(value_f64))
end

function set!(context::DM, command::AbstractString, value::AbstractString)
    if !isopen(context)
        throw(Error(0, "DM is not open"))
    end
    @check asdkSetString(context.handle, command, value)
end

Base.setindex!(context, value, command) = set!(context, command, value)

end # module ASDK
