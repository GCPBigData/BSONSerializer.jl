
# based on BSON.jl
function modpath(x::Module)
    y = parentmodule(x)
    result = x == y ? [nameof(x)] : [modpath(y)..., nameof(x)]

    if result[1] == :Main
        popfirst!(result)
    end

    return result
end

# based on BSON.jl
typepath(x::DataType) = [modpath(x.name.module)..., x.name.name]
typepathref(x::DataType) = string.(typepath(x))

# Returns a vector of tuples (nm, t),
# where nm is a Symbol for field name, and t a DataType.
function nametypetuples(t::DataType)
    @nospecialize t

    _fieldnames = fieldnames(t)
    _fieldtypes = fieldtypes(t)
    @assert length(_fieldnames) == length(_fieldtypes)
    return [ (_fieldnames[i], _fieldtypes[i]) for i in 1:length(_fieldnames) ]
end

function codegen_serialize(datatype::DataType) :: Expr
    @nospecialize datatype

    # "fieldname" => val.val.fieldname
    function field_value_pair_expr(nm::Symbol, @nospecialize(tt::Type{T})) :: Expr where {T}
        # "fieldname" => BSONSerializer.encode(val.val.fieldname, T)
        return :($("$nm") => BSONSerializer.encode(val.val.$nm, $T))
    end

    # "f1" => val.val.1, "f2" => val.val.f2, ...
    field_value_pairs = Expr(:tuple,
        [ field_value_pair_expr(nm, t) for (nm, t) in nametypetuples(datatype) ]...)

    type_encoded = typepathref(datatype)

    quote
        function BSONSerializer.serialize(val::BSONSerializer.Serializable{$datatype})
            return BSONSerializer.BSON("type" => $type_encoded, "args" => BSONSerializer.BSON($field_value_pairs...))
        end
   end
end

function codegen_deserialize(datatype::DataType) :: Expr
    @nospecialize datatype

    function arg_expr(nm::Symbol, @nospecialize(tt::Type{T})) :: Expr where {T}
        return :(BSONSerializer.decode( args[$("$nm")], $T))
    end

    # singleton or method
    if isdefined(datatype, :instance)
        return quote
            function BSONSerializer.deserialize(bson::Union{BSONSerializer.BSON, Dict}, ::Type{BSONSerializer.Serializable{$datatype}})
                ($datatype).instance
            end
        end
    else
        arg_list = Expr(:tuple,
            [ arg_expr(nm, t) for (nm, t) in nametypetuples(datatype) ]...)

        return quote
            function BSONSerializer.deserialize(bson::Union{BSONSerializer.BSON, Dict}, ::Type{BSONSerializer.Serializable{$datatype}})
                args = bson["args"]
                ($datatype)($arg_list...)
            end
        end
    end
end

is_type_reference(@nospecialize(m), s::Symbol) = isa(m.eval(s), DataType)

function is_type_reference(caller_module::Module, expr::Expr)
    @nospecialize caller_module expr

    is_module_name(expr::Symbol) = true
    is_module_name(expr::QuoteNode) = is_module_name(expr.value)
    is_module_name(other) = false
    function is_module_name(expr::Expr)
        if expr.head == :.
            @assert length(expr.args) == 2
            return is_module_name(expr.args[1]) && is_module_name(expr.args[2])
        end
    end

    is_type_name(expr::Symbol) = true
    is_type_name(expr::QuoteNode) = is_type_name(expr.value)
    is_type_name(other) = false

    # let's go slowly, because we're going to eval some expressions...
    if expr.head == :.
        @assert length(expr.args) == 2
        possibly_module_name = expr.args[1]
        possibly_type_name = expr.args[2]

        if is_module_name(possibly_module_name)
            type_owner_module = caller_module.eval(possibly_module_name)
            if isa(type_owner_module, Module)
                if is_type_name(possibly_type_name)
                    return isa(caller_module.eval(expr), DataType)
                end
            end
        end
    end
    return false
end

macro BSONSerializable(expr::Union{Expr, Symbol})
    @nospecialize expr

    #println("macro input: $expr, type $(typeof(expr))")

    if is_type_reference(__module__, expr)
        #println("$expr is a type reference.")
        datatype = __module__.eval(expr)
        expr_serialize_method = codegen_serialize(datatype)
        expr_deserialize_method = codegen_deserialize(datatype)

        return quote
            $expr_serialize_method
            BSONSerializer.encode(val::$datatype, ::Type{$datatype}) = BSONSerializer.serialize(BSONSerializer.Serializable(val))
            BSONSerializer.encode_type(::Type{$datatype}) = BSONSerializer.BSON

            $expr_deserialize_method
            BSONSerializer.decode(val::Union{BSONSerializer.BSON, Dict}, ::Type{$datatype}) = BSONSerializer.deserialize(val, BSONSerializer.Serializable{$datatype})
        end

    elseif isa(expr, Expr) && expr.head == :struct
        __module__.eval(expr) # a bit of a hack...
        struct_name = expr.args[2]
        return quote
            @BSONSerializable($struct_name)
        end

    else
        error("Couldn't apply @BSONSerialize to $expr.")
    end
end
