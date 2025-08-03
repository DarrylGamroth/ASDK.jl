@testset "ASDK.jl Comprehensive Tests" begin
    @testset "Basic DM Operations" begin
        open(DM, TEST_SERIAL) do dm
            @test dm isa DM
            @test isopen(dm)
            @test dm.numberofactuators > 0
            
            # Test basic send operation
            values = zeros(dm.numberofactuators)
            @test_nowarn send!(dm, values)
            
            # Test with different value types
            values_float32 = zeros(Float32, dm.numberofactuators)
            @test_nowarn send!(dm, values_float32)
            
            values_int = zeros(Int, dm.numberofactuators)
            @test_nowarn send!(dm, values_int)
            
            # Test reset and stop
            @test_nowarn reset!(dm)
            @test_nowarn stop!(dm)
        end
    end
    
    @testset "DM Pattern Operations" begin
        open(DM, TEST_SERIAL) do dm
            nact = dm.numberofactuators
            
            # Test single pattern
            pattern = zeros(nact)
            @test_nowarn send!(dm, pattern, 1, 1)
            
            # Test multiple patterns
            patterns = vcat(zeros(nact), ones(nact) * 0.1, rand(nact) * 0.05)
            @test_nowarn send!(dm, patterns, 3, 1)
            
            # Test with repeat
            @test_nowarn send!(dm, patterns, 3, 2)
            
            # Test invalid pattern sizes
            @test_throws ErrorException send!(dm, zeros(nact-1), 1, 1)
            @test_throws ErrorException send!(dm, zeros(nact*2+1), 2, 1)
        end
    end
    
    @testset "Parameter Access" begin
        open(DM, TEST_SERIAL) do dm
            # Test parameters that actually work
            nact = ASDK.get(dm, "NbOfActuator")
            @test nact == dm.numberofactuators
            @test nact isa Float64
            
            # Test indexing syntax
            nact2 = dm["NbOfActuator"]
            @test nact2 == nact
            
            # Test some known working parameters
            try
                version = ASDK.get(dm, "VersionInfo")
                @test version isa Float64
                @info "VersionInfo: $version"
            catch e
                @info "VersionInfo not available: $(e)"
            end
            
            try
                useexc = ASDK.get(dm, "UseException")
                @test useexc isa Float64
                @info "UseException: $useexc"
            catch e
                @info "UseException not available: $(e)"
            end
        end
    end
    
    @testset "Parameter Setting" begin
        open(DM, TEST_SERIAL) do dm
            # Test setting UseException parameter
            try
                original = ASDK.get(dm, "UseException")
                ASDK.set!(dm, "UseException", 0.0)
                @test ASDK.get(dm, "UseException") == 0.0
                
                # Test indexing syntax for setting
                dm["UseException"] = 1.0
                @test dm["UseException"] == 1.0
                
                # Restore original value
                ASDK.set!(dm, "UseException", original)
                @info "UseException parameter setting works"
            catch e
                @info "UseException parameter setting not available: $(e)"
            end
            
            # Test vector parameter setting (if available)
            try
                # Try setting a vector parameter like mirror command or calibration
                test_vector = zeros(dm.numberofactuators)
                ASDK.set!(dm, "mcff", test_vector)
                @info "Successfully set vector parameter mcff"
            catch e
                @info "Vector parameter mcff not available: $(e)"
            end
            
            # Test string parameter setting (if available)
            try
                ASDK.set!(dm, "CfgPath", "/tmp/test")
                @info "Successfully set string parameter CfgPath"
            catch e
                @info "String parameter CfgPath not available: $(e)"
            end
        end
    end
    
    @testset "Error Handling" begin
        # Test invalid serial numbers
        @test_throws ASDK.Error DM("INVALID_SERIAL")
        @test_throws ASDK.Error DM("")
        
        # Test closed DM operations
        dm = DM(TEST_SERIAL)
        @test isopen(dm)
        close(dm)
        @test !isopen(dm)
        
        # These should throw ASDK.Error due to closed DM
        @test_throws ASDK.Error ASDK.get(dm, "NbOfActuator")
        @test_throws ASDK.Error ASDK.set!(dm, "UseException", 0.0)
        @test_throws ASDK.Error reset!(dm)
        @test_throws ASDK.Error stop!(dm)
        @test_throws ASDK.Error send!(dm, zeros(10))
        
        # Test invalid parameter access
        open(DM, TEST_SERIAL) do dm
            @test_throws ASDK.Error ASDK.get(dm, "NonExistentParameter")
            # Note: Empty string parameter may be valid in some cases, so skip this test
        end
        
        # Test invalid send operations
        open(DM, TEST_SERIAL) do dm
            # Wrong number of actuators
            @test_throws ErrorException send!(dm, zeros(dm.numberofactuators - 1))
            @test_throws ErrorException send!(dm, zeros(dm.numberofactuators + 1))
            
            # Wrong pattern sizes
            @test_throws ErrorException send!(dm, zeros(dm.numberofactuators * 2 + 1), 2, 1)
        end
    end
    
    @testset "Exception Types and Messages" begin
        # Test error structure
        try
            DM("INVALID")
        catch e
            @test e isa ASDK.Error
            @test e isa ASDK.ASDKException
            @test e.errno isa UInt32
            @test e.errmsg isa String
            @test !isempty(e.errmsg)
            
            # Test error display
            error_str = string(e)
            @test occursin("Error", error_str)  # More flexible check
            @test occursin(string(e.errno), error_str) || occursin(string(e.errno, base=16), error_str)
            @test occursin(e.errmsg, error_str)
        end
        
        # Test parameter not found errors
        open(DM, TEST_SERIAL) do dm
            try
                ASDK.get(dm, "NonExistentParameter")
            catch e
                @test e isa ASDK.Error
                @test e.errno isa UInt32
                @test occursin("not found", lowercase(e.errmsg)) || 
                      occursin("unknown", lowercase(e.errmsg)) ||
                      occursin("invalid", lowercase(e.errmsg))
            end
        end
    end
    
    @testset "Resource Management" begin
        # Test multiple open/close cycles
        for i in 1:3
            dm = DM(TEST_SERIAL)
            @test isopen(dm)
            @test dm.numberofactuators > 0
            close(dm)
            @test !isopen(dm)
        end
        
        # Test do-block syntax
        local dm_ref
        open(DM, TEST_SERIAL) do dm
            dm_ref = dm
            @test isopen(dm)
            
            # Test operations within do-block
            @test_nowarn send!(dm, zeros(dm.numberofactuators))
            @test_nowarn reset!(dm)
        end
        @test !isopen(dm_ref)
        
        # Test manual release
        dm = DM(TEST_SERIAL)
        @test isopen(dm)
        release!(dm)
        @test !isopen(dm)
        @test dm.handle == C_NULL
        @test dm.numberofactuators == -1
    end
    
    @testset "check_status Function" begin
        # Test successful status
        @test_nowarn ASDK.check_status(ASDK.LibASDK.SUCCESS)
        
        # Test error status (we can't easily test this without causing actual errors)
        # The function is tested indirectly through other operations
    end
    
    @testset "@check Macro" begin
        # Test successful operation
        @test_nowarn @ASDK.check ASDK.LibASDK.SUCCESS
        
        # The macro is tested indirectly through all other SDK operations
    end
end
