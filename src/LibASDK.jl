module LibASDK

using AlpaoSDK_jll
export AlpaoSDK_jll

using CEnum

const Char = Cchar

const UChar = UInt8

const Short = Int16

const UShort = UInt16

const Int = Int32

const UInt = UInt32

const Long = Int64

const ULong = UInt64

const Size_T = Cint

const Scalar = Cdouble

const CString = Cstring

const CStrConst = Cstring

@cenum COMPL_STAT::Int32 begin
    SUCCESS = 0
    FAILURE = -1
end

mutable struct DM end

const asdkDM = DM

"""
    asdkInit(serialName)

### Prototype
```c
asdkDM * asdkInit( CStrConst serialName );
```
"""
function asdkInit(serialName)
    @ccall libasdk.asdkInit(serialName::CStrConst)::Ptr{asdkDM}
end

"""
    asdkRelease(pDm)

### Prototype
```c
COMPL_STAT asdkRelease( asdkDM *pDm );
```
"""
function asdkRelease(pDm)
    @ccall libasdk.asdkRelease(pDm::Ptr{asdkDM})::COMPL_STAT
end

"""
    asdkSend(pDm, value)

### Prototype
```c
COMPL_STAT asdkSend( asdkDM *pDm, const Scalar *value );
```
"""
function asdkSend(pDm, value)
    @ccall libasdk.asdkSend(pDm::Ptr{asdkDM}, value::Ptr{Scalar})::COMPL_STAT
end

"""
    asdkReset(pDm)

### Prototype
```c
COMPL_STAT asdkReset( asdkDM *pDm );
```
"""
function asdkReset(pDm)
    @ccall libasdk.asdkReset(pDm::Ptr{asdkDM})::COMPL_STAT
end

"""
    asdkSendPattern(pDm, pattern, nPattern, nRepeat)

### Prototype
```c
COMPL_STAT asdkSendPattern( asdkDM *pDm, const Scalar *pattern, UInt nPattern, UInt nRepeat );
```
"""
function asdkSendPattern(pDm, pattern, nPattern, nRepeat)
    @ccall libasdk.asdkSendPattern(pDm::Ptr{asdkDM}, pattern::Ptr{Scalar}, nPattern::UInt, nRepeat::UInt)::COMPL_STAT
end

"""
    asdkStop(pDm)

### Prototype
```c
COMPL_STAT asdkStop( asdkDM *pDm );
```
"""
function asdkStop(pDm)
    @ccall libasdk.asdkStop(pDm::Ptr{asdkDM})::COMPL_STAT
end

"""
    asdkGet(pDm, command, value)

### Prototype
```c
COMPL_STAT asdkGet( asdkDM *pDm, CStrConst command, Scalar * value );
```
"""
function asdkGet(pDm, command, value)
    @ccall libasdk.asdkGet(pDm::Ptr{asdkDM}, command::CStrConst, value::Ptr{Scalar})::COMPL_STAT
end

"""
    asdkGetVector(pDm, command, value, nbElements)

### Prototype
```c
COMPL_STAT asdkGetVector(asdkDM *pDm, CStrConst command, Scalar ** value, uint32_t* nbElements);
```
"""
function asdkGetVector(pDm, command, value, nbElements)
    @ccall libasdk.asdkGetVector(pDm::Ptr{asdkDM}, command::CStrConst, value::Ptr{Ptr{Scalar}}, nbElements::Ptr{UInt32})::COMPL_STAT
end

"""
    asdkFreeVector(value)

### Prototype
```c
COMPL_STAT asdkFreeVector(Scalar ** value);
```
"""
function asdkFreeVector(value)
    @ccall libasdk.asdkFreeVector(value::Ptr{Ptr{Scalar}})::COMPL_STAT
end

"""
    asdkGetString(pDm, command, str)

### Prototype
```c
COMPL_STAT asdkGetString(asdkDM *pDm, CStrConst command, char ** str);
```
"""
function asdkGetString(pDm, command, str)
    @ccall libasdk.asdkGetString(pDm::Ptr{asdkDM}, command::CStrConst, str::Ptr{Cstring})::COMPL_STAT
end

"""
    asdkFreeString(value)

### Prototype
```c
COMPL_STAT asdkFreeString(char ** value);
```
"""
function asdkFreeString(value)
    @ccall libasdk.asdkFreeString(value::Ptr{Cstring})::COMPL_STAT
end

"""
    asdkSet(pDm, command, value)

### Prototype
```c
COMPL_STAT asdkSet( asdkDM *pDm, CStrConst command, Scalar value );
```
"""
function asdkSet(pDm, command, value)
    @ccall libasdk.asdkSet(pDm::Ptr{asdkDM}, command::CStrConst, value::Scalar)::COMPL_STAT
end

"""
    asdkSetVector(pDm, command, vector, size)

### Prototype
```c
COMPL_STAT asdkSetVector( asdkDM *pDm, CStrConst command, const Scalar* vector, Int size);
```
"""
function asdkSetVector(pDm, command, vector, size)
    @ccall libasdk.asdkSetVector(pDm::Ptr{asdkDM}, command::CStrConst, vector::Ptr{Scalar}, size::Int)::COMPL_STAT
end

"""
    asdkSetString(pDm, command, cstr)

### Prototype
```c
COMPL_STAT asdkSetString( asdkDM *pDm, CStrConst command, CStrConst cstr );
```
"""
function asdkSetString(pDm, command, cstr)
    @ccall libasdk.asdkSetString(pDm::Ptr{asdkDM}, command::CStrConst, cstr::CStrConst)::COMPL_STAT
end

# no prototype is found for this function at asdkWrapper.h:210:15, please use with caution
"""
    asdkPrintLastError()

### Prototype
```c
void asdkPrintLastError();
```
"""
function asdkPrintLastError()
    @ccall libasdk.asdkPrintLastError()::Cvoid
end

"""
    asdkGetLastError(errorNo, errMsg, errSize)

### Prototype
```c
COMPL_STAT asdkGetLastError( UInt *errorNo, CString errMsg, Size_T errSize );
```
"""
function asdkGetLastError(errorNo, errMsg, errSize)
    @ccall libasdk.asdkGetLastError(errorNo::Ptr{UInt}, errMsg::CString, errSize::Size_T)::COMPL_STAT
end

# Skipping MacroDefinition: ACS_API_EXPORTS __attribute__ ( ( __visibility__ ( "default" ) ) )

# exports
const PREFIXES = ["asdk"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
