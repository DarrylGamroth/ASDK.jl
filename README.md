# ASDK.jl

[![Build Status](https://github.com/yourusername/ASDK.jl/workflows/CI/badge.svg)](https://github.com/yourusername/ASDK.jl/actions)
[![Coverage](https://codecov.io/gh/yourusername/ASDK.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/ASDK.jl)

A Julia wrapper for the ALPAO SDK, providing high-level control of ALPAO deformable mirrors.

## Usage

### Basic Mirror Control

```julia
using ASDK

# Connect to a deformable mirror (automatic resource management)
open(DM, "BAL123") do dm
    println("Connected to DM with $(dm.numberofactuators) actuators")
    
    # Send actuator commands
    values = zeros(dm.numberofactuators)  # Flat mirror
    send!(dm, values)
    
    # Apply random deformation
    deformation = rand(dm.numberofactuators) * 0.1
    send!(dm, deformation)
    
    # Reset to default state
    reset!(dm)
end
```

### Pattern Sequences

```julia
open(DM, "BAL123") do dm
    nact = dm.numberofactuators
    
    # Create pattern sequence
    patterns = vcat(
        zeros(nact),           # Pattern 1: Flat
        ones(nact) * 0.1,      # Pattern 2: Piston  
        rand(nact) * 0.05      # Pattern 3: Random
    )
    
    # Play sequence 5 times
    send!(dm, patterns, 3, 5)
    
    # Stop playback
    stop!(dm)
end
```

### Parameter Access

```julia
open(DM, "BAL123") do dm
    # Read parameters
    nact = ASDK.get(dm, "NbOfActuator")
    version = ASDK.get(dm, "VersionInfo")
    
    # Set parameters  
    ASDK.set!(dm, "UseException", 1.0)
    
    # Indexing syntax
    temp = dm["Temperature"]
    dm["TriggerIn"] = 1.0
end
```

### Error Handling

```julia
try
    dm = DM("INVALID_SERIAL")
catch e::ASDK.Error
    println("Error $(e.errno): $(e.errmsg)")
end
```

### Virtual Mirror for Testing

```julia
# Use virtual mirror for development
dm = DM("VIRT103-104")
println("Virtual DM: $(dm.numberofactuators) actuators")
close(dm)
```

## API Reference

| Function | Description |
|----------|-------------|
| `DM(serial)` | Create mirror connection |
| `send!(dm, values)` | Send actuator values |
| `send!(dm, patterns, n, repeat)` | Send pattern sequence |
| `reset!(dm)` | Reset to default state |
| `stop!(dm)` | Stop current operations |
| `ASDK.get(dm, param)` | Get parameter value |
| `ASDK.set!(dm, param, value)` | Set parameter value |
| `close(dm)` | Release resources |

## License

MIT License - see [LICENSE](LICENSE) file for details.
