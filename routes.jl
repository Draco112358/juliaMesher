using Genie, Genie.Router, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json, Genie.Requests, JSON, SimpleWebsockets, Base.Threads

include("lib/mesher.jl")

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "http://localhost:1212"
# This has to be this way - you should not include ".../*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

# route("/") do
#   serve_static_file("welcome.html")
# end

server = WebsocketServer()

Threads.@spawn serve(server, 8081, verbose=false)

const stopComputation = []

listen(server, :client) do client
  listen(client, :message) do message
    println(message)
    if message == "Stop computation"
      #error("stop computation")
      push!(stopComputation, 1)
    end
  end
  route("/meshing", method="POST") do
    return JSON.json(doMeshing(jsonpayload()))
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
