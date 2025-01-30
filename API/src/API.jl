# __precompile__(false) # TODO: remove

module API

_BASE_URL = "http://localhost:8085/"

include("./process_params.jl")
include("./process.jl")

const TRAPEZOID_DEFAULT = Trapezoid(
    6,
    15,
    6,
    (16),
    10,
    None(),
    HWResetParams(10, Int16(800), 110)
)

end # module API


# test = """
# {"algorithm":{"Trapezoid":{"left":6,"center":15,"right":6,"treshold":10,"min_length":10,"skip":"None","reset_detection":{"window":10,"treshold":800,"size":110}}},"convert_to_kev":true}
# """