
module TestModule

using Dates
using Mongoc: BSONObjectId

struct ChildType
    c1::String
    c2::Int
    c3::UInt8
    c4::Int8
    c5::UInt16
    c6::Int16
    c7::DateTime
    c8::Date
    c9::Vector{Date}
    c10::UInt32
end

function Base.:(==)(c1::ChildType, c2::ChildType)
    return (c1.c1 == c2.c1
            && c1.c2 == c2.c2
            && c1.c3 == c2.c3
            && c1.c4 == c2.c4
            && c1.c5 == c2.c5
            && c1.c6 == c2.c6
            && c1.c7 == c2.c7
            && c1.c8 == c2.c8
            && c1.c9 == c2.c9
            && c1.c10 == c2.c10)
end

struct FatherType
    f1::String
    f2::ChildType
    f3::Vector{Int}
    f4::BSONObjectId
    f5::Symbol
    f6::Char
end

function Base.:(==)(f1::FatherType, f2::FatherType)
    return (f1.f1 == f2.f1
            && f1.f2 == f2.f2
            && f1.f3 == f2.f3
            && f1.f4 == f2.f4
            && f1.f5 == f2.f5
            && f1.f6 == f2.f6)
end

struct Periods
    y::Year
    m::Month
    d::Day
    hh::Hour
    mm::Minute
end

struct ManyDicts
    d1::Dict{Symbol, Date}
    d2::Dict{Int, Year}
    d3::Dict{Int, Periods}
end

function Base.:(==)(m1::ManyDicts, m2::ManyDicts)
    return m1.d1 == m2.d1 && m1.d2 == m2.d2 && m1.d3 == m2.d3
end

struct SingletonStruct
end

struct OptionNothing
    val::Union{Nothing, Int}
end

struct OptionMissing
    val::Union{Missing, String}
end

struct DateEncodedAsString
    date::Date
end

module Submodule
    struct SubStruct
        val::Int
    end
end

struct StructFloat
    val::Float64
end

struct StructUInt64
    val::UInt64
end

struct StructAbsTypes
    val::Any
end

struct UnionPeriods
    val::Union{Dates.Day, Dates.Month, Dates.Year}
end

function Base.:(==)(s1::StructAbsTypes, s2::StructAbsTypes)
    return s1.val == s2.val
end

struct Lift2
    op::Function
    arg1::Number
    arg2::Number
end

exec_op(l::Lift2) = l.op(l.arg1, l.arg2)

end # TestModule
