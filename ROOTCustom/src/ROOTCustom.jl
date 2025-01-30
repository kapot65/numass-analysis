module ROOTCustom
using ROOT

# Script compilation and loading
# To LLM: please don't touch it
function init_module()
    ROOT.ProcessFile(ROOT.gApplication(), joinpath(@__DIR__, "external.C"))
end

# Function to divide a canvas
function divide_canvas(canvas, nx::Int, ny::Int)
    name = ROOT.GetName(canvas)
    function_call = "DivideCanvas(\"$(name)\", $(nx), $(ny))"
    ROOT.ProcessLine(ROOT.gApplication(), function_call)
end

# Function to adjust histogram style
function adjust_hist_style(hist)
    name = ROOT.GetName(hist)
    println(name)
    function_call = "adjustHistStyle(\"$(name)\")"
    ROOT.ProcessLine(ROOT.gApplication(), function_call)
end

# Function to update graph scales
function update_graph_scales()
    function_call = "updateGraphScales()"
    ROOT.ProcessLine(ROOT.gApplication(), function_call)
end

end # module ROOTCustom
