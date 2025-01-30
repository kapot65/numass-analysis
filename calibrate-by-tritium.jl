using ROOT
using API

using ROOTCustom

ROOTCustom.init_module()

include("constants.jl")

const SETS = [
    "Tritium_3/set_1/",
    "Tritium_3/set_2/",
    "Tritium_3/set_3/",
]

const HIST_RAW_RANGE = 0.0:200.0
const HIST_RAW_BINS::Int = 400
const PEAK_RAW_RANGE=-4:4


HVS = [
    12000, 12500, 13000, 
    13500, 14000, 14500, 
    15000, 15500, 16000, 
    16500, 17000
]


# набираем усредненный спектр по HV
hv = HVS[6]
set = SETS[1]

filepaths = Iterators.map(set -> find_points_by_hv(set, hv), SETS) |>
  Iterators.flatten |> collect

result = let
    amps = amps_from_files(filepaths, API.ProcessParams(
        API.TRAPEZOID_DEFAULT,
        false
    ))
    find_histogramm_peak(
        amps,
        HIST_RAW_RANGE, HIST_RAW_BINS,
        PEAK_RAW_RANGE,
        "canvas"
    )
end





# API.TRAPEZOID_DEFAULT,