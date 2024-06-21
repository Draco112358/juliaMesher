include("voxelizator.jl")
include("voxelize_internal.jl")
using MeshIO
using FileIO
using Meshes
using MeshBridge

function find_mins_maxs(mesh_object::Mesh)
    bb = boundingbox(mesh_object)
    #@assert mesh_object isa Mesh
    minx = coordinates(minimum(bb))[1]
    maxx = coordinates(maximum(bb))[1]
    miny = coordinates(minimum(bb))[2]
    maxy = coordinates(maximum(bb))[2]
    minz = coordinates(minimum(bb))[3]
    maxz = coordinates(maximum(bb))[3]
    return minx, maxx, miny, maxy, minz, maxz
end


function find_box_dimensions(dict_meshes::Dict)
    global_min_x, global_min_y, global_min_z = prevfloat(typemax(Float64)), prevfloat(typemax(Float64)), prevfloat(typemax(Float64))
    global_max_x, global_max_y, global_max_z = -prevfloat(typemax(Float64)), -prevfloat(typemax(Float64)), -prevfloat(typemax(Float64))

    for (key, value) in dict_meshes
        value = value["mesh"]
        #println(dict_meshes)
        minx, maxx, miny, maxy, minz, maxz = find_mins_maxs(value)
        global_min_x = min(global_min_x, minx)
        global_min_y = min(global_min_y, miny)
        global_min_z = min(global_min_z, minz)
        global_max_x = max(global_max_x, maxx)
        global_max_y = max(global_max_y, maxy)
        global_max_z = max(global_max_z, maxz)
    end

    keeper_object = Dict()
    keeper_object["meshXmin"] = global_min_x
    keeper_object["meshXmax"] = global_max_x
    keeper_object["meshYmin"] = global_min_y
    keeper_object["meshYmax"] = global_max_y
    keeper_object["meshZmin"] = global_min_z
    keeper_object["meshZmax"] = global_max_z

    w = keeper_object["meshXmax"] - keeper_object["meshXmin"]
    l = keeper_object["meshYmax"] - keeper_object["meshYmin"]
    h = keeper_object["meshZmax"] - keeper_object["meshZmin"]

    return w, l, h, keeper_object
end


function find_sizes(number_of_cells_x::Int, number_of_cells_y::Int, number_of_cells_z::Int, geometry_descriptor::Dict)

    @assert number_of_cells_x isa Int
    @assert number_of_cells_y isa Int
    @assert number_of_cells_z isa Int
    @assert geometry_descriptor isa Dict
    @assert length(geometry_descriptor) == 6

    # minimum_vertex_coordinates = [geometry_descriptor['meshXmin'] * 1e-3, geometry_descriptor['meshYmin'] * 1e-3,
    #           geometry_descriptor['meshZmin'] * 1e-3]
    # # max_v = [minmax.meshXmax minmax.meshYmax minmax.meshZmax]*1e-3;
    xv = LinRange(geometry_descriptor["meshXmin"] * 1e-3, geometry_descriptor["meshXmax"] * 1e-3,
        number_of_cells_x + 1)
    yv = LinRange(geometry_descriptor["meshYmin"] * 1e-3, geometry_descriptor["meshYmax"] * 1e-3,
        number_of_cells_y + 1)
    zv = LinRange(geometry_descriptor["meshZmin"] * 1e-3, geometry_descriptor["meshZmax"] * 1e-3,
        number_of_cells_z + 1)

    return abs(xv[3] - xv[2]), abs(yv[3] - yv[2]), abs(zv[3] - zv[2])#, minimum_vertex_coordinates
end

function slicematrix(A::AbstractMatrix{T}) where {T}
    m, n = size(A)
    B = Vector{T}[Vector{T}(undef, n) for _ in 1:m]
    for i in 1:m
        B[i] .= A[i, :]
    end
    return B
end

function dump_json_data(filename, o_x::Float64, o_y::Float64, o_z::Float64, cs_x::Float64, cs_y::Float64, cs_z::Float64, nc_x, nc_y, nc_z, matr, id_to_material)

    #print("Serialization to:",filename)
    @assert cs_x isa Float64
    @assert cs_y isa Float64
    @assert cs_z isa Float64
    @assert o_x isa Float64
    @assert o_y isa Float64
    @assert o_z isa Float64

    origin = Dict("origin_x" => o_x, "origin_y" => o_y, "origin_z" => o_z)

    n_cells = Dict("n_cells_x" => convert(Float64, nc_x), "n_cells_y" => convert(Float64, nc_y), "n_cells_z" => convert(Float64, nc_z))

    # Controllare perché è necessaria questa moltiplicazione per 1000.
    cell_size = Dict("cell_size_x" => cs_x * 1000, "cell_size_y" => cs_y * 1000, "cell_size_z" => cs_z * 1000)

    mesher_matrices_dict = Dict()


    for c in range(1, length(id_to_material))
        x = []
        for i in range(1, nc_x)
            push!(x, slicematrix(matr[c, i, :, :]))
        end
        mesher_matrices_dict[id_to_material[c]["material"]] = x

        # for matrix in eachslice(matr2, dims=1)
        #     #@assert count in keys(id_to_material)
        #     println("->")
        #     display(matrix)
        #
        #     #display(mesher_matrices_dict[id_to_material[count]])
        #     #count += 1
        # end
    end

    mats = Dict()
    for (id, m) in id_to_material
        mats[id] = m["material"]
    end


    #@assert count == n_materials+1
    json_dict = Dict("n_materials" => length(id_to_material), "materials" => mats, "origin" => origin, "cell_size" => cell_size, "n_cells" => n_cells, "mesher_matrices" => mesher_matrices_dict)
    return json_dict
end

function existsThisBrick(brick_coords::CartesianIndex, mesher_matrices::Dict, material)
    if 1 <= brick_coords[1] <= length(mesher_matrices[material]) &&
       1 <= brick_coords[2] <= length(mesher_matrices[material][brick_coords[1]]) &&
       1 <= brick_coords[3] <= length(mesher_matrices[material][brick_coords[1]][brick_coords[2]])
        return mesher_matrices[material][brick_coords[1]][brick_coords[2]][brick_coords[3]]
    end
    return false
end

function is_brick_valid(brick_coords::CartesianIndex, mesher_matrices::Dict, material)
    brickDown = existsThisBrick(CartesianIndex(brick_coords[1] - 1, brick_coords[2], brick_coords[3]), mesher_matrices, material)
    brickUp = existsThisBrick(CartesianIndex(brick_coords[1] + 1, brick_coords[2], brick_coords[3]), mesher_matrices, material)
    if (!brickDown && !brickUp)
        return Dict("valid" => false, "axis" => "x", "stopped" => false)
    end
    brickDown = existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2] - 1, brick_coords[3]), mesher_matrices, material)
    brickUp = existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2] + 1, brick_coords[3]), mesher_matrices, material)
    if (!brickDown && !brickUp)
        return return Dict("valid" => false, "axis" => "y", "stopped" => false)
    end
    brickDown = existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] - 1), mesher_matrices, material)
    brickUp = existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] + 1), mesher_matrices, material)
    if (!brickDown && !brickUp)
        return return Dict("valid" => false, "axis" => "z", "stopped" => false)
    end
    return Dict("valid" => true, "stopped" => false)
end

function is_mesh_valid(mesher_matrices::Dict, id::String, chan)
    for material in keys(mesher_matrices)
        checkLength = length(mesher_matrices[material]) * length(mesher_matrices[material][1]) * length(mesher_matrices[material][1][1])
        if !isnothing(chan)
            publish_data(Dict("length" => checkLength, "id" => id), "mesher_feedback", chan)
        end
        index = 1
        for brick_coords in CartesianIndices((1:length(mesher_matrices[material]), 1:length(mesher_matrices[material][1]), 1:length(mesher_matrices[material][1][1])))
            if index % ceil(checkLength / 100) == 0
                if !isnothing(chan)
                    publish_data(Dict("index" => index, "id" => id), "mesher_feedback", chan)
                end
            end
            if length(stopComputation) > 0
                pop!(stopComputation)
                return Dict("valid" => false, "stopped" => true)
            end
            if (mesher_matrices[material][brick_coords[1]][brick_coords[2]][brick_coords[3]])
                brick_valid = is_brick_valid(brick_coords, mesher_matrices, material)
                if (!brick_valid["valid"])
                    return brick_valid
                end
            end
            index += 1
        end
    end
    return Dict("valid" => true)
end

function brick_touches_the_main_bounding_box(brick_coords::CartesianIndex, mesher_matrices::Dict, material)::Bool
    Nx = size(mesher_matrices[material], 1)
    Ny = size(mesher_matrices[material], 2)
    Nz = size(mesher_matrices[material], 3)
    if brick_coords[1] == 1 || brick_coords[1] == Nx || brick_coords[2] == 1 || brick_coords[2] == Ny || brick_coords[3] == 1 || brick_coords[3] == Nz
        return true
    end
    return false
end

function brick_is_on_surface(brick_coords::CartesianIndex, mesher_matrices::Dict, material)::Bool
    if brick_touches_the_main_bounding_box(brick_coords, mesher_matrices, material)
        return true
    end
    for mat in keys(mesher_matrices)
        if !existsThisBrick(CartesianIndex(brick_coords[1] - 1, brick_coords[2], brick_coords[3]), mesher_matrices, mat)
            return true
        end
        if !existsThisBrick(CartesianIndex(brick_coords[1] + 1, brick_coords[2], brick_coords[3]), mesher_matrices, mat)
            return true
        end
        if !existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2] - 1, brick_coords[3]), mesher_matrices, mat)
            return true
        end
        if !existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2] + 1, brick_coords[3]), mesher_matrices, mat)
            return true
        end
        if !existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] - 1), mesher_matrices, mat)
            return true
        end
        if !existsThisBrick(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] + 1), mesher_matrices, mat)
            return true
        end
    end
    return false
end



function create_grids_externals(grids::Dict)::Dict
    OUTPUTgrids = Dict()
    for (material, mat) in grids
        str = ""
        for cont1 in eachindex(mat)
            for cont2 in eachindex(mat[1])
                for cont3 in eachindex(mat[1][1])
                    # se il brick esiste e si affaccia su una superficie, lo aggiungiamo alla griglia
                    if mat[cont1][cont2][cont3]
                        if brick_is_on_surface(CartesianIndex(cont1, cont2, cont3), grids, material)
                            str = str * "$cont1-$cont2-$cont3\$"
                        end
                    end
                end
            end
        end
        OUTPUTgrids[material] = str[1:end-1]
    end
    return OUTPUTgrids
end


function doMeshing(dictData::Dict, id::String, chan=nothing)
    result = Dict()
    meshes = Dict()
    for geometry in Array{Any}(dictData["STLList"])
        #@assert geometry isa Dict
        mesh_id = geometry["material"]["name"]
        mesh_stl = geometry["STL"]
        #@assert mesh_id not in meshes
        open("stl.stl", "w") do write_file
            write(write_file, mesh_stl)
        end
        mesh_stl = load("stl.stl")
        mesh_stl_converted = convert(Meshes.Mesh, mesh_stl)

        #mesh_stl_converted = Meshes.Polytope(3,3,mesh_stl)
        #@assert mesh_stl_converted isa Mesh
        meshes[mesh_id] = Dict("mesh" => mesh_stl_converted, "conductivity" => geometry["material"]["conductivity"])

        Base.Filesystem.rm("stl.stl", force=true)
    end
    geometry_x_bound, geometry_y_bound, geometry_z_bound, geometry_data_object = find_box_dimensions(meshes)


    # grids grainx
    # assert type(dictData['quantum'])==list
    quantum_x, quantum_y, quantum_z = dictData["quantum"]

    # if (geometry_x_bound < quantum_x)
    #     result = Dict("x" => "too large", "max_x" => geometry_x_bound)
    # elseif (geometry_y_bound < quantum_y)
    #     result = Dict("y" => "too large", "max_y" => geometry_y_bound)
    # elseif (geometry_z_bound < quantum_z)
    #     result = Dict("z" => "too large", "max_z" => geometry_z_bound)
    # else
        # quantum_x, quantum_y, quantum_z = 1, 1e-2, 1e-2 #per Test 1
        # # quantum_x, quantum_y, quantum_z = 1e-1, 1, 1e-2  # per Test 2
        # # quantum_x, quantum_y, quantum_z = 1e-1, 1e-1, 1e-2  # per Test 3
        # # quantum_x, quantum_y, quantum_z = 2, 1, 1e-2  # per Test 4
        # # quantum_x, quantum_y, quantum_z = 1, 1, 1e-2  # per Test 5

        #print("QUANTA:",quantum_x, quantum_y, quantum_z)

    n_of_cells_x = ceil(Int, geometry_x_bound / quantum_x)
    n_of_cells_y = ceil(Int, geometry_y_bound / quantum_y)
    n_of_cells_z = ceil(Int, geometry_z_bound / quantum_z)



    #print("GRID:",n_of_cells_x, n_of_cells_y, n_of_cells_z)

    cell_size_x, cell_size_y, cell_size_z = find_sizes(n_of_cells_x, n_of_cells_y, n_of_cells_z, geometry_data_object)
    #precision = 0.1
    #print("CELL SIZE AFTER ADJUSTEMENTS:",(cell_size_x), (cell_size_y), (cell_size_z))
    # if __debug__:

    #     for size,quantum in zip([cell_size_x,cell_size_y,cell_size_z],[quantum_x,quantum_y,quantum_z]):
    #         print(abs(size*(1/precision) - quantum),precision)
    #         assert abs(size*(1/precision) - quantum)<=precision


    mesher_output = fill(false, (length(dictData["STLList"]), n_of_cells_x, n_of_cells_y, n_of_cells_z))

    mapping_ids_to_materials = Dict()

    counter_stl_files = 1
    for (material, value) in meshes
        #@assert meshes[mesh_id] isa Mesh
        mesher_output[counter_stl_files, :, :, :] = voxelize(n_of_cells_x, n_of_cells_y, n_of_cells_z, value["mesh"], geometry_data_object)
        #mapping dei materiali su id e impostazione priorità per i conduttori in overlapping.
        mapping_ids_to_materials[counter_stl_files] = Dict("material" => material, "toKeep" => (value["conductivity"] != 0.0) ? true : false)
        counter_stl_files += 1
    end


    solve_overlapping(n_of_cells_x, n_of_cells_y, n_of_cells_z, mapping_ids_to_materials, mesher_output)

    origin_x = geometry_data_object["meshXmin"] * 1e-3
    origin_y = geometry_data_object["meshYmin"] * 1e-3
    origin_z = geometry_data_object["meshZmin"] * 1e-3


    # assert(isinstance(mesher_output, np.ndarray))
    # @assert cell_size_x isa Float64
    # @assert cell_size_y isa Float64
    # @assert cell_size_z isa Float64
    # @assert origin_x isa Float64
    # @assert origin_y isa Float64
    # @assert origin_z isa Float64

    # Writing to data.json
    json_file_name = "outputMesher.json"
    mesh_result = dump_json_data(json_file_name, origin_x, origin_y, origin_z, cell_size_x, cell_size_y, cell_size_z,
        n_of_cells_x, n_of_cells_y, n_of_cells_z, mesher_output, mapping_ids_to_materials)
    mesh_result["mesh_is_valid"] = is_mesh_valid(mesh_result["mesher_matrices"], id, chan)
    if (mesh_result["mesh_is_valid"]["valid"])
        externalGrids = Dict(
            "externalGrids" => create_grids_externals(mesh_result["mesher_matrices"]),
            "origin" => "$(mesh_result["origin"]["origin_x"])-$(mesh_result["origin"]["origin_y"])-$(mesh_result["origin"]["origin_z"])",
            "n_cells" => "$(mesh_result["n_cells"]["n_cells_x"])-$(mesh_result["n_cells"]["n_cells_y"])-$(mesh_result["n_cells"]["n_cells_z"])",
            # ricordarsi di dividere per 1000 la cell_size quando la importi su esymia, così che il meshedElement la ridivida, per il solito problema di visualizzazione strano.
            "cell_size" => "$(mesh_result["cell_size"]["cell_size_x"])-$(mesh_result["cell_size"]["cell_size_y"])-$(mesh_result["cell_size"]["cell_size_z"])"
        )
    end
    result = Dict("mesh" => mesh_result, "grids" => externalGrids, "isValid" => mesh_result["mesh_is_valid"]["valid"])
    #end
    return result
end

function quantumAdvice(mesherInput::Dict)
    meshes = Dict()
    for geometry in Array{Any}(mesherInput["STLList"])
        #@assert geometry isa Dict
        mesh_id = geometry["material"]["name"]
        mesh_stl = geometry["STL"]
        #@assert mesh_id not in meshes
        open("stl.stl", "w") do write_file
            write(write_file, mesh_stl)
        end
        mesh_stl = load("stl.stl")
        mesh_stl_converted = convert(Meshes.Mesh, mesh_stl)
        meshes[mesh_id] = mesh_stl_converted
        Base.Filesystem.rm("stl.stl", force=true)
    end
    q_x = 100
    q_y = 100
    q_z = 100
    for (key, mesh) in meshes
        for c = 1:nelements(mesh)

            #% t1, t2 e t3 sono i vertici di un triangolo
            t1 = coordinates(vertices(mesh[c])[1])
            t2 = coordinates(vertices(mesh[c])[2])
            t3 = coordinates(vertices(mesh[c])[3])

            sx = abs(t1[1] - t2[1])
            if sx > 1e-10 && q_x > sx
                q_x = sx
            end

            sx = abs(t1[1] - t3[1])
            if sx > 1e-10 && q_x > sx
                q_x = sx
            end

            sx = abs(t2[1] - t3[1])
            if sx > 1e-10 && q_x > sx
                q_x = sx
            end

            sy = abs(t1[2] - t2[2])
            if sy > 1e-10 && q_y > sy
                q_y = sy
            end

            sy = abs(t1[2] - t3[2])
            if sy > 1e-10 && q_y > sy
                q_y = sy
            end

            sy = abs(t2[2] - t3[2])
            if sy > 1e-10 && q_y > sy
                q_y = sy
            end

            sz = abs(t1[3] - t2[3])
            if sz > 1e-10 && q_z > sz
                q_z = sz
            end

            sz = abs(t1[3] - t3[3])
            if sz > 1e-10 && q_z > sz
                q_z = sz
            end

            sz = abs(t2[3] - t3[3])
            if sz > 1e-10 && q_z > sz
                q_z = sz
            end

        end

    end
    q_x = 0.5 * q_x
    q_y = 0.5 * q_y
    q_z = 0.5 * q_z

    return [q_x, q_y, q_z]
end
