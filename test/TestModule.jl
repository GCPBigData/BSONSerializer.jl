
module TestModule

using Dates

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
            && c1.c9 == c2.c9)
end

struct FatherType
    f1::String
    f2::ChildType
    f3::Vector{Int}
end

function Base.:(==)(f1::FatherType, f2::FatherType)
    return (f1.f1 == f2.f1
            && f1.f2 == f2.f2
            && f1.f3 == f2.f3)
end

end # TestModule