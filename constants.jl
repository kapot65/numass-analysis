const DATA_ROOT = "/data-fast/numass-server/"
const RUN = "2024_11"

function find_points_by_hv(set::String, hv::Int)::Vector{String}
    directory = joinpath([DATA_ROOT, RUN, set])
    candidates = filter(
        name -> contains(name, "HV1=$(hv)"),
        readdir(directory)
    )

    return map(candidate -> joinpath(directory, candidate), candidates)
end

"""
Extract [(channel, amplitude)] pairs from points.

# Arguments
- `filepaths`: A list of file paths to the point files (return value of `find_points_by_hv`).
"""
function amps_from_files(filepaths, process::API.ProcessParams)
    function event_to_amp(event)
        (offset, event) = event
        if isa(event, API.Event)
            return (UInt8(event.channel + 1), event.amplitude)
        end
    end

    amps = asyncmap(filepath -> begin
        (frames, _) = API.process_point(filepath, process)
        Iterators.filter(
            !isnothing,
            Iterators.map(
                event_to_amp,
                Iterators.flatmap(
                    i -> i.second, frames
                )
            )
        )
    end, filepaths)

    return amps |> Iterators.flatten |> collect
end

"""
Структура для хранения данных обработки

canvas и hists добавлены чтобы они не удалялись сборщиком мусора
и были доступны для отрисовки после выполнения функции get_peaks
"""
struct PointPeakFound # TODO change order
    hv_kev::Union{Float64, Nothing}
    peaks::Vector{Union{Nothing,Float64}}
    canvas::Union{ROOT.TCanvas, Nothing} # добавлено поле для хранения гистограмм
    hists::Vector{ROOT.TH1D} # добавлено поле для хранения гистограмм
end

"""
Построение гистограммы для каждого канала и нахождение пика.
# Arguments:
- amps::Vector{Vector{UInt8, Float64}} - массив амплитуд для каждого канала (return value from amps_from_files)
- canvas_name::Union{String, Nothing} - название канваса для отображения фита (по умолчанию ничего не строится)
# Returns:
histogram objects (to prevent garbage collection)
peaks positions (idx == channel id)
"""
function find_histogramm_peak(
        amps, 
        hist_range, hist_bins::Int,
        peak_range,
        canvas_name::Union{String, Nothing}=nothing
    )::PointPeakFound

    canvas = nothing
    if !isnothing(canvas_name)
        canvas = make_canvas(canvas_name, canvas_name)
    end

    hists = Vector{ROOT.TH1DAllocated}()
    for ch_id in 1:7 # 7 channels
        push!(
            hists, 
            ROOT.TH1D(
                "h$(canvas_name)-ch$(ch_id)", "h$(canvas_name)-ch$(ch_id)", 
                hist_bins, minimum(hist_range), maximum(hist_range)
            )
        )
    end

    for (ch_id, amp) in amps
        ROOT.Fill(hists[ch_id], Float64(amp))
    end

    peak_ranges = []
    for ch_id in 1:7
        counts = ROOT.GetEntries(hists[ch_id])
        if counts == 0
            push!(peak_ranges, nothing)
        else
            argmax = ROOT.GetMaximumBin(hists[ch_id])
            left = ROOT.GetBinLowEdge(hists[ch_id], max(0, argmax + Int(minimum(peak_range))))
            right_bin = min(ROOT.FindLastBinAbove(hists[ch_id], 0), argmax + Int(maximum(peak_range)))
            right = ROOT.GetBinLowEdge(hists[ch_id], right_bin) + ROOT.GetBinWidth(hists[ch_id], right_bin)
            push!(peak_ranges, (left, right))
        end
    end

    peaks = []
    for ch_id in 1:7
        if !isnothing(peak_ranges[ch_id])
            if !isnothing(canvas)
                ROOT.cd(canvas, ch_id)
            end
            (left, right) = peak_ranges[ch_id]
            ROOT.Fit(hists[ch_id], "gaus", "", "", left, right)
            fit_func = ROOT.GetFunction(hists[ch_id], "gaus")
            peak = ROOT.GetMaximumX(fit_func, left, right)

            if !isnothing(canvas)
                ROOT.Draw(hists[ch_id], "PLC")
                ROOT.SetRangeUser(ROOT.GetXaxis(hists[ch_id]), peak - 10, peak + 10)
            end

            push!(peaks, peak)
        else
            push!(peaks, nothing)
        end
    end
    
    return PointPeakFound(
        nothing,
        peaks,
        canvas,
        hists
    )    
end