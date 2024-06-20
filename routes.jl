using Genie, Genie.Router, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json, Genie.Requests, JSON, SimpleWebsockets, Base.Threads, AMQPClient
include("lib/saveFiles.jl")

include("lib/mesher.jl")
Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "http://localhost:1212"
# This has to be this way - you should not include ".../*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

server = WebsocketServer()

#Threads.@spawn serve(server, 8081, verbose=false)

const stopComputation = []

listen(server, :client) do client
  listen(client, :message) do message
    println(message)
    if message == "Stop computation"
      push!(stopComputation, 1)
    end
  end
  route("/meshing", method="POST") do
    result = doMeshing(jsonpayload(), client)
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
  println("------ Precompiling routes...wait for mesher to be ready ---------")
  for (name, r) in Router.named_routes()
    data = open(JSON.parse, "first_run_data.json")
    Genie.Requests.HTTP.requesEt(r.method, "http://localhost:8003" * tolink(name), [("Content-Type", "application/json")], JSON.json(data))
  end
  println("MESHER READY")
end

function force_compile2()
  println("------ Precompiling routes...wait for mesher to be ready ---------")
  data = open(JSON.parse, "first_run_data.json")
  doMeshing(data, "init")
  println("MESHER READY")
end

#Threads.@spawn force_compile()
function publish_data(result::Dict, queue::String, chan)
  data = convert(Vector{UInt8}, codeunits(JSON.json(result)))
  message = Message(data, content_type="application/json", delivery_mode=PERSISTENT)
  basic_publish(chan, message; exchange="", routing_key=queue)
end

export publish_data

const VIRTUALHOST = "/"
const HOST = "127.0.0.1"

function receive()
  # 1. Create a connection to the localhost or 127.0.0.1 of virtualhost '/'
  connection(; virtualhost=VIRTUALHOST, host=HOST) do conn
      # 2. Create a channel to send messages
      AMQPClient.channel(conn, AMQPClient.UNUSED_CHANNEL, true) do chan
          
          force_compile2()
          # EXCG_DIRECT = "MyDirectExcg"
          # @assert exchange_declare(chan1, EXCG_DIRECT, EXCHANGE_TYPE_DIRECT)
          println(" [*] Waiting for messages. To exit press CTRL+C")
          # 3. Declare a queue
          management_queue = "management"
          #queue_bind(chan, "mesher_results", EXCG_DIRECT, "mesher_results")

          # 4. Setup function to receive message
          on_receive_management = (msg) -> begin
              data = JSON.parse(String(msg.data))
              #data = String(msg.data)
              println(data["message"])
              if (data["message"] == "compute suggested quantum")
                res = quantumAdvice(data["body"])
                result = Dict("body" => JSON.json(res), "id" => data["body"]["id"])
                publish_data(result, "mesh_advices", chan)
              elseif data["message"] == "compute mesh"
                result = doMeshing(data["body"], data["body"]["fileName"], chan)
                if result["isValid"] == true
                  (meshPath, gridsPath) = saveMeshAndGrids(data["body"]["fileName"], result)
                  results = Dict("mesh" => meshPath, "grids" => gridsPath, "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => false, "id" => data["body"]["fileName"])
                  publish_data(results, "mesher_results", chan) 
                elseif result["isValid"] == false
                  results = Dict("mesh" => "", "grids" => "", "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => result["mesh"]["mesh_is_valid"]["stopped"], "id" => data["body"]["fileName"])
                  publish_data(results, "mesher_results", chan)
                end
              end
              basic_ack(chan, msg.delivery_tag)
          end

          # 5. Configure Quality of Service
          basic_qos(chan, 0, 1, false)
          success_management, consumer_tag = basic_consume(chan, management_queue, on_receive_management)

          @assert success_management == true

          while true
              sleep(1)
          end
          # 5. Close the connection
      end
  end
end


# Don't exit on Ctrl-C
Base.exit_on_sigint(false)
try
  receive()
catch ex
  if ex isa InterruptException
      println("Interrupted")
  else
      println("Exception: $ex")
  end
end