# TODO: document API
using JSON

# Define SkipOption enum
abstract type SkipOption end

struct None <: SkipOption end
struct Bad <: SkipOption end
struct Good <: SkipOption end


function deserialize_skip_option(json_data::String)
    if json_data == "None"
        return None()
    elseif json_data == "Bad"
        return Bad()
    elseif json_data == "Good"
        return Good()
    else
        error("Unknown SkipOption type")
    end
end

function from_json(json_str::String, ::Type{SkipOption})
    data = JSON.parse(json_str)
    return deserialize_skip_option(data["skip"])
end

function to_json(skip_option::SkipOption)
    if isa(skip_option, None)
        return "None"
    elseif isa(skip_option, Bad)
        return "Bad"
    elseif isa(skip_option, Good)
        return "Good"
    else
        error("Unknown SkipOption type")
    end
end

# Define HWResetParams struct
struct HWResetParams
    window::Int
    treshold::Int16
    size::Int
end

function deserialize_hwresetparams(json_data::Dict{String,Any})
    return HWResetParams(
        json_data["window"],
        json_data["treshold"],
        json_data["size"]
    )
end

function from_json(json_str::String, ::Type{HWResetParams})
    data = JSON.parse(json_str)
    return deserialize_hwresetparams(data["reset_detection"])
end

function to_json(hw_reset_params::HWResetParams)
    return Dict(
        "window" => hw_reset_params.window,
        "treshold" => hw_reset_params.treshold,
        "size" => hw_reset_params.size
    )
end


# Define Algorithm enum
abstract type Algorithm end

struct Max <: Algorithm end

struct Likhovid <: Algorithm
    left::Int
    right::Int
end

struct FirstPeak <: Algorithm
    threshold::Int16
    left::Int
end

struct Trapezoid <: Algorithm
    left::Int
    center::Int
    right::Int
    treshold::Int16
    min_length::Int
    skip::SkipOption
    reset_detection::HWResetParams
end

struct LongDiff <: Algorithm
    reset_detection::HWResetParams
end

function from_json(json_str::String, ::Type{Algorithm})
    data = JSON.parse(json_str)
    return deserialize_algorithm(data["algorithm"])
end

function to_json(algorithm::Algorithm)
    if isa(algorithm, Max)
        return Dict("Max" => Dict())
    elseif isa(algorithm, Likhovid)
        likhovid = algorithm
        return Dict(
            "Likhovid" => Dict(
                "left" => likhovid.left,
                "right" => likhovid.right
            )
        )
    elseif isa(algorithm, FirstPeak)
        first_peak = algorithm
        return Dict(
            "FirstPeak" => Dict(
                "threshold" => first_peak.threshold,
                "left" => first_peak.left
            )
        )
    elseif isa(algorithm, Trapezoid)
        trapezoid = algorithm
        return Dict(
            "Trapezoid" => Dict(
                "left" => trapezoid.left,
                "center" => trapezoid.center,
                "right" => trapezoid.right,
                "treshold" => trapezoid.treshold,
                "min_length" => trapezoid.min_length,
                "skip" => to_json(trapezoid.skip),
                "reset_detection" => to_json(trapezoid.reset_detection)
            )
        )
    elseif isa(algorithm, LongDiff)
        long_diff = algorithm
        return Dict(
            "LongDiff" => Dict(
                "reset_detection" => to_json(long_diff.reset_detection)
            )
        )
    else
        error("Unknown Algorithm type")
    end
end

function deserialize_algorithm(json_data::Dict{String,Any})
    for (alg_type, alg_data) in json_data
        if alg_type == "Max"
            return Max()
        elseif alg_type == "Likhovid"
            return Likhovid(
                alg_data["left"],
                alg_data["right"]
            )
        elseif alg_type == "FirstPeak"
            return FirstPeak(
                alg_data["threshold"],
                alg_data["left"]
            )
        elseif alg_type == "Trapezoid"
            skip = deserialize_skip_option(alg_data["skip"])
            reset_detection = deserialize_hwresetparams(alg_data["reset_detection"])
            return Trapezoid(
                alg_data["left"],
                alg_data["center"],
                alg_data["right"],
                alg_data["treshold"],
                alg_data["min_length"],
                skip,
                reset_detection
            )
        elseif alg_type == "LongDiff"
            reset_detection = deserialize_hwresetparams(alg_data["reset_detection"])
            return LongDiff(reset_detection)
        else
            error("Unknown Algorithm type")
        end
    end
end

# Define ProcessParams struct
struct ProcessParams
    algorithm::Algorithm
    convert_to_kev::Bool
end

function from_json(json_str::String, ::Type{ProcessParams})
    data = JSON.parse(json_str)
    algorithm = deserialize_algorithm(data["algorithm"])
    convert_to_kev = data["convert_to_kev"]
    return ProcessParams(algorithm, convert_to_kev)
end

function to_json(process_params::ProcessParams)
    return Dict(
        "algorithm" => to_json(process_params.algorithm),
        "convert_to_kev" => process_params.convert_to_kev
    )
end