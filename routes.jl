using Genie, Genie.Router, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json, Genie.Requests, JSON, SimpleWebsockets, Base.Threads
include("lib/saveFiles.jl")

include("lib/mesher.jl")
Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "http://localhost:1212"
# This has to be this way - you should not include ".../*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

server = WebsocketServer()

Threads.@spawn serve(server, 8081, verbose=false)

const stopComputation = []

listen(server, :client) do client
  listen(client, :message) do message
    println(message)
    if message == "Stop computation"
      push!(stopComputation, 1)
    end
  end
  route("/meshing", method="POST") do
    result = doMeshing(jsonpayload())
    if result["isValid"] == true
      (meshPath, gridsPath) = saveMeshAndGrids(jsonpayload()["fileName"], result)
      return JSON.json(Dict("mesh" => meshPath, "grids" => gridsPath, "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => false))
    elseif !result["isValid"] == false
      return JSON.json(Dict("mesh" => "", "grids" => "", "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => result["mesh"]["mesh_is_valid"]["stopped"]))
    else
      # caso del quanto impostato troppo grande rispetto alle dimensioni del modello
      return JSON.json(result)
    end
  end
end

route("/meshing2", method="POST") do
  result = doMeshing(jsonpayload())
  if result["isValid"] == true
    (meshPath, gridsPath) = saveMeshAndGrids("init", result)
    return JSON.json(Dict("mesh" => meshPath, "grids" => gridsPath, "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => false))
  elseif result["isValid"] == false
    return JSON.json(Dict("mesh" => "", "grids" => "", "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => result["mesh"]["mesh_is_valid"]["stopped"]))
  else
    # caso del quanto impostato troppo grande rispetto alle dimensioni del modello
    return JSON.json(result)
  end

end


route("/meshingAdvice", method="POST") do
  return JSON.json(quantumAdvice(jsonpayload()))
end

function force_compile()
  sleep(5)
  println("------ Precompiling routes...wait for mesher to be ready ---------")
  for (name, r) in Router.named_routes()
    data = open(JSON.parse, "first_run_data.json")
    Genie.Requests.HTTP.request(r.method, "http://localhost:8003" * tolink(name), [("Content-Type", "application/json")], JSON.json(data))
  end
  println("MESHER READY")
end

Threads.@spawn force_compile()

