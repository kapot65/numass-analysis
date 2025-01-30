### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 342ac661-d76b-42dd-9b3f-a111fc3d0770
# ╠═╡ show_logs = false
begin
	import Pkg
    # careful: this is _not_ a reproducible environment
    # activate the global environment
    Pkg.activate("./")
	Pkg.develop(path="./API")
	Pkg.add(["JSON", "HTTP", "MsgPack", "IterTools", "Plots"])
	# using API
end

# ╔═╡ f213c238-a82b-427c-9651-aa7d2b0322c1
begin
	using JSON
	using HTTP
	using MsgPack
	using Dates
	using IterTools
	using Plots

	using API
end

# ╔═╡ 272eca23-f28e-45ce-84d0-5a124479a8ee
HTML("""
<!-- the wrapper span -->
<div>
	<button id="myrestart" href="#">Restart</button>
	
	<script>
		const div = currentScript.parentElement
		const button = div.querySelector("button#myrestart")
		const cell= div.closest('pluto-cell')
		console.log(button);
		button.onclick = function() { restart_nb() };
		function restart_nb() {
			console.log("Restarting Notebook");
		        cell._internal_pluto_actions.send(                    
		            "restart_process",
                            {},
                            {
                                notebook_id: editor_state.notebook.notebook_id,
                            }
                        )
		};
	</script>
</div>
""")

# ╔═╡ d9ac9c64-f607-40f7-b0d7-1f6463b89029
# plotly();

# ╔═╡ 1343df6b-d569-490c-a31a-c2326b9b71ca
process = API.ProcessParams(
    API.Trapezoid(
        6, 15, 6,
        16, 10,
        API.None(),
        # Bad(),
        API.HWResetParams(
            10, 800, 110
        )
    ),
    true
)


# ╔═╡ ade18418-a570-4b51-b009-434bf38076bd
point_file = "/data-fast/numass-server/2024_11/Tritium_2_1/set_1/p0(30s)(HV1=14000)"
# "/data-fast/numass-server/2024_11/Tritium_2_1/set_1/p1(30s)(HV1=18660)"

# ╔═╡ 5ac2e72b-b863-4903-baed-a4971e507e79
(frames, preprocess) = API.process_point(point_file, process)

# ╔═╡ 916766aa-2805-40c2-8802-4aa3b5a58d2f
begin
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
end

# ╔═╡ 9d832176-aa4a-4137-a54c-84edb0741f48
histogram(amps)

# ╔═╡ Cell order:
# ╟─272eca23-f28e-45ce-84d0-5a124479a8ee
# ╠═342ac661-d76b-42dd-9b3f-a111fc3d0770
# ╠═f213c238-a82b-427c-9651-aa7d2b0322c1
# ╠═d9ac9c64-f607-40f7-b0d7-1f6463b89029
# ╠═1343df6b-d569-490c-a31a-c2326b9b71ca
# ╠═ade18418-a570-4b51-b009-434bf38076bd
# ╠═5ac2e72b-b863-4903-baed-a4971e507e79
# ╠═916766aa-2805-40c2-8802-4aa3b5a58d2f
# ╠═9d832176-aa4a-4137-a54c-84edb0741f48
