### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ e75b20dc-d977-11ef-053b-6bcc6bfa58c5
begin
	import Pkg
    Pkg.activate("./")
	Pkg.develop(path="./API")
	using API
end

# ╔═╡ 6b27cec3-10e8-437d-897f-38a332d2509c
using ROOT

# ╔═╡ 7bc33167-dba4-4535-a778-f420d9582184
md"""
## Калибровка пикселей детектора по данным электрода


"""

# ╔═╡ 5cbefbdd-4a8d-4ca3-8af5-4a46ecd463e6
begin
	const DATA_ROOT="/data-fast/numass-server/"
	const RUN = "2024_11"
	const SET = "Electrode_1/set_4"
end

# ╔═╡ 45a9227d-4d74-499e-8336-17af463ebe87
function find_point_hv(hv)
	directory = joinpath([DATA_ROOT, RUN, SET])
	
	candidates = filter(
		name -> contains(name, "HV1=$(Int(hv))"), 
		readdir(directory)
	)

	if isempty(candidates)
		return Nothing
	else
		return joinpath([directory, first(candidates)])
	end
end

# ╔═╡ 7279731a-12e2-4915-91ce-eb07cf1ae333
points = let
	points = Dict()
	for hv in [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0]
		push!(points, hv => find_point_hv(hv * 1e3))
	end
	points
end

# ╔═╡ 80b9675f-23e0-406e-9493-fef717114c8e
begin
	process = API.ProcessParams(
		API.TRAPEZOID_DEFAULT,
		false
	)
	point_file = (points |> first).second
	(frames, preprocess) = API.process_point(point_file, process)
end

# ╔═╡ b63e73af-ff41-40c4-93d4-de74ff78eb17
begin

	c = ROOT.TCanvas()
	
	frame = first(frames)
	events = frame.second

	function event_to_amp(event)
		(offset, event) = event
		if isa(event, API.Event)
			return event.amplitude
		end
	end

	amps = Iterators.filter(
		!isnothing,
		Iterators.map(
			event_to_amp, 
			Iterators.flatmap(
				i -> i.second, frames
			)
		)
	) |> collect
	
	
	th1 = ROOT.TH1D("h1f", "Test random numbers", 400, 0, 40)

	for amp in amps
		ROOT.Fill(th1, Float64(amp))
	end

	ROOT.Draw(th1)
	temp_pic = mktemp()
	ROOT.SaveAs(c, temp_pic[1])

	read(temp_pic)
end

# ╔═╡ 37e8b3af-31fd-4f4b-a8ea-8bcd5e854c09
md"
![aaa]( $(mktemp) )
"

# ╔═╡ 9739ac36-79ec-43b7-81da-751bf4d2311a
begin

	# asyncmap
end

# ╔═╡ Cell order:
# ╠═7bc33167-dba4-4535-a778-f420d9582184
# ╠═e75b20dc-d977-11ef-053b-6bcc6bfa58c5
# ╠═5cbefbdd-4a8d-4ca3-8af5-4a46ecd463e6
# ╠═45a9227d-4d74-499e-8336-17af463ebe87
# ╠═7279731a-12e2-4915-91ce-eb07cf1ae333
# ╠═6b27cec3-10e8-437d-897f-38a332d2509c
# ╠═80b9675f-23e0-406e-9493-fef717114c8e
# ╠═b63e73af-ff41-40c4-93d4-de74ff78eb17
# ╠═37e8b3af-31fd-4f4b-a8ea-8bcd5e854c09
# ╠═9739ac36-79ec-43b7-81da-751bf4d2311a
