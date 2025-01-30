using ROOT
using API

using ROOTCustom

ROOTCustom.init_module()

include("constants.jl")

const SET = "Electrode_1/set_4"

const HIST_RANGE = 0.0:200.0
const HIST_BINS::Int = 400
const PEAK_RANGE=-4:4

const PROCESS = API.ProcessParams(
    API.TRAPEZOID_DEFAULT,
    false
)
const HVS = [
    4.0, 6.0, 8.0, 10.0,
    12.0, 14.0, 16.0, 18.0
]

function make_canvas(id, name)
    canvas = ROOT.TCanvas(id, name, 800, 600)
    ROOTCustom.divide_canvas(canvas, 3, 3)
    return canvas
end


points = let
    points = Dict()
    for hv in HVS
        push!(points, hv => find_points_by_hv(SET, Int(hv * 1e3)))
    end
    points
end

function get_peaks(hv_kev)::PointPeakFound

    amps = amps_from_files(points[hv_kev], PROCESS)
    # ROOT.SetBatch(ROOT.gROOT, true)
    result = find_histogramm_peak(
        amps,
        HIST_RANGE, HIST_BINS,
        PEAK_RANGE,
        "HV=$(hv_kev)keV"
    )
    # ROOT.SetBatch(ROOT.gROOT, false)

    return PointPeakFound(
        hv_kev,
        result.peaks,
        result.canvas,
        result.hists
    )
end

output = Vector{PointPeakFound}()
for hv_kev in HVS
    push!(output, get_peaks(hv_kev))
end


struct ChannelLinearFitResult
    x::Vector{Float64}
    y::Vector{Float64}
    graph::ROOT.TGraphAllocated
    a::Float64
    b::Float64
end


(linear_fit_canvas, linear_fit) = let
    x = map(point -> point.hv_kev, output)
    linear_fit_canvas = make_canvas("linear_fit", "Linear Fit")
    linear_fit = Vector{Union{Nothing,ChannelLinearFitResult}}()
    for ch_id in 1:7
        if isnothing(output[1].peaks[ch_id])
            push!(linear_fit, nothing)
            continue
        end
        ch = map(point -> point.peaks[ch_id], output)

        ROOT.cd(linear_fit_canvas, ch_id)
        graph = ROOT.TGraph(length(x), ch, x)
        fit_result = ROOT.Fit(graph, "pol1")
        ROOT.SetTitle(graph, "Channel $ch_id linear fit")
        ROOT.Draw(graph, "AP*")
        fit_func = ROOT.GetFunction(graph, "pol1")
        push!(
            linear_fit,
            ChannelLinearFitResult(
                ch,
                x,
                graph,
                ROOT.GetParameter(fit_func, 0),
                ROOT.GetParameter(fit_func, 1)
            )
        )
    end

    (linear_fit_canvas, linear_fit)
end


display(
    map(chan -> begin
            if isnothing(chan)
                return [1.0, 0.0]
            else
                return [chan.b, chan.a]
            end
        end, linear_fit)
)