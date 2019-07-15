
const NATIVE_BSON_DATATYPE = Union{String, Int32, Int64, DateTime, Float64, Bool, BSONObjectId}
const OTHER_NUMERIC_DATATYPE = Union{UInt8, UInt16, Int8, Int16}

#
# Native types supported by BSON
#

function encode(val::T) where {T<:NATIVE_BSON_DATATYPE}
    val
end

function decode(val::T, ::Type{T}) where {T<:NATIVE_BSON_DATATYPE}
    val
end

function encode_type(::Type{T}) where {T<:NATIVE_BSON_DATATYPE}
    T
end

#
# Integer numbers smalled than 32bits are encoded as Int32
#

function encode(val::T) where {T<:OTHER_NUMERIC_DATATYPE}
    Int32(val)
end

function decode(val::Int32, ::Type{T}) where {T<:OTHER_NUMERIC_DATATYPE}
    T(val)
end

function encode_type(::Type{T}) where {T<:OTHER_NUMERIC_DATATYPE}
    Int32
end

#
# Date is encoded as DateTime with zeroed Time
#

encode(val::Date) = DateTime(val)

function decode(val::DateTime, ::Type{Date})
    Date(val)
end

encode_type(::Type{Date}) = DateTime

#
# Vectors are encoded as BSON vectors with encoded values
#

function encode(val::Vector{T}) where {T}
    [ encode(x) for x in val ]
end

function decode(val::Vector, ::Type{Vector{T}}) where {T}
    T[ decode(x, T) for x in val ]
end

function encode_type(val::Vector{T}) where {T}
    Vector{encode_type(T)}
end

#
# Symbols are encoded as strings
#

encode(val::Symbol) = String(val)
decode(val::String, ::Type{Symbol}) = Symbol(val)
encode_type(::Type{Symbol}) = String

#
# Dictionaries with String as symbols are natively supported by BSON.
# Edge case might fail: when V is an abstract type.
#

encode_dict_key(key::String) = key
decode_dict_key(key::String, ::Type{String}) = key

encode_dict_key(key::Symbol) = String(key)
decode_dict_key(key::String, ::Type{Symbol}) = Symbol(key)

encode_dict_key(key::Integer) = string(Int(key))
function decode_dict_key(key::String, ::Type{T}) where {T<:Integer}
    T(parse(Int, key))
end

function encode(val::Dict{K,V}) where {K,V}
    encoded_dict = Dict{String,encode_type(V)}()
    for (k,v) in val
        encoded_dict[encode_dict_key(k)] = encode(v)
    end
    return encoded_dict
end

function decode(val::Dict, ::Type{Dict{K, V}}) where {K,V}
    decoded_dict = Dict{K, V}()
    for (k,v) in val
        decoded_dict[decode_dict_key(k, K)] = decode(val[k], V)
    end
    return decoded_dict
end