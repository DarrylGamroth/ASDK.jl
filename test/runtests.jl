using Test
using ASDK

# Ensure we're running from the test directory so SDK can find config files
test_dir = @__DIR__
if pwd() != test_dir
    cd(test_dir)
    @info "Changed working directory to: $(pwd())"
end

# Check for config files in multiple locations
config_dir = joinpath(test_dir, "config")
config_files_in_test = filter(f -> endswith(f, ".acfg"), readdir(test_dir))
config_files_in_config = isdir(config_dir) ? filter(f -> endswith(f, ".acfg"), readdir(config_dir)) : String[]

# Set ACECFG environment variable to point to config directory if files are there
if !isempty(config_files_in_config) && isempty(config_files_in_test)
    ENV["ACECFG"] = config_dir
    @info "Set ACECFG environment variable to: $(config_dir)"
    config_files = config_files_in_config
    config_location = config_dir
elseif !isempty(config_files_in_test)
    config_files = config_files_in_test
    config_location = test_dir
else
    error("No .acfg config files found in test directory or config subdirectory")
end

# Test configuration
const TEST_SERIAL = "VIRT103-104"  # Virtual DM for testing

@info "Running ASDK.jl tests from: $(pwd())"
@info "Config files location: $(config_location)"
@info "Available config files: $(config_files)"

# Test utility functions
"""
Check if the virtual DM is available for testing.
"""
function is_virtual_dm_available()
    try
        dm = DM(TEST_SERIAL)
        close(dm)
        return true
    catch
        return false
    end
end

# Check if virtual DM is available before running tests
if !is_virtual_dm_available()
    @warn "Virtual DM '$TEST_SERIAL' not available. Some tests may fail."
    @warn "Make sure the ASDK library is properly installed and configured."
end

@testset "ASDK.jl Tests" begin
    include("test_asdk.jl")
end
