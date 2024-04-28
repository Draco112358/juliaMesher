using Meshes

function solve_overlapping(n_cells_x,n_cells_y,n_cells_z,id_mat_keep,output_meshing)
    for c1 in range(1, n_cells_x)
        for c2 in range(1, n_cells_y)
            for c3 in range(1, n_cells_z)
                for k in keys(id_mat_keep)
                    if output_meshing[k,c1, c2, c3] == true
                        for k2 in keys(id_mat_keep)
                            if output_meshing[k2,c1, c2, c3] == true && k!=k2
                                if id_mat_keep[k]["toKeep"]
                                    output_meshing[k2, c1, c2, c3] = false
                                else
                                    output_meshing[k, c1, c2, c3] = false
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function merge_the_3_grids(voxcountX, voxcountY, voxcountZ,gridOUTPUT1,gridOUTPUT2,gridOUTPUT3,gridOUTPUT)
    for c1 in range(1, voxcountX)
        for c2 in range(1, voxcountY)
            for c3 in range(1,voxcountZ)
                cont_true = 0
                if gridOUTPUT1[c2, c3, c1] == true
                    cont_true = cont_true + 1
                end
                if gridOUTPUT2[c3, c1, c2] == true
                    cont_true = cont_true + 1
                end
                if gridOUTPUT3[c1, c2, c3] == true
                    cont_true = cont_true + 1
                end
                if cont_true > 1
                    gridOUTPUT[c1, c2, c3] = true
                end
            end
        end
    end
    return gridOUTPUT
end

function voxelize(cells_on_x::Int,cells_on_y::Int,cells_on_z::Int,meshXYZ::Mesh, geometry_desc::Dict)

    #@assert cells_on_x isa Int
    #@assert cells_on_y isa Int
    #@assert cells_on_ isa Int
    #@assert geometry_desc isa Dict

    #@assert length(geometry_desc)==6
    
    # raydirection    = 'xyz'
    
    #@assert meshXYZ isa Mesh
       
    meshXmin = geometry_desc["meshXmin"]
    meshXmax = geometry_desc["meshXmax"]
    meshYmin = geometry_desc["meshYmin"]
    meshYmax = geometry_desc["meshYmax"]
    meshZmin = geometry_desc["meshZmin"]
    meshZmax = geometry_desc["meshZmax"]

    if cells_on_x==1
        #If gridX is a single integer (rather than a vector) and is equal to 1
        gridCOx   = (meshXmin+meshXmax)/2
    else
        #If gridX is a single integer (rather than a vector) then automatically create the list of x coordinates
        voxwidth  = (meshXmax-meshXmin)/(cells_on_x+1/2)
        gridCOx = [meshXmin+voxwidth/2]
        for (index, value) in enumerate(range(meshXmin+voxwidth/2, meshXmax-voxwidth/2, step=voxwidth))
            if (index != 1)
                push!(gridCOx, gridCOx[index-1]+voxwidth)
            end
        end
    end
    
    if cells_on_y==1
        #If gridX is a single integer (rather than a vector) and is equal to 1
        gridCOy   = (meshYmin+meshYmax)/2
    else
        #If gridX is a single integer (rather than a vector) then automatically create the list of x coordinates
        voxwidth  = (meshYmax-meshYmin)/(cells_on_y+1/2)
        gridCOy = [meshYmin+voxwidth/2]
        for (index, value) in enumerate(range(meshYmin+voxwidth/2, meshYmax-voxwidth/2, step=voxwidth))
            if (index != 1)
                push!(gridCOy, gridCOy[index-1]+voxwidth)
            end
        end
    end
    
    if cells_on_z==1
        #If gridX is a single integer (rather than a vector) and is equal to 1
        gridCOz   = (meshZmin+meshZmax)/2
    else
        #If gridX is a single integer (rather than a vector) then automatically create the list of x coordinates
        voxwidth  = (meshZmax-meshZmin)/(cells_on_z+1/2)
        gridCOz = [meshZmin+voxwidth/2]
        for (index, value) in enumerate(range(meshZmin+voxwidth/2, meshZmax-voxwidth/2, step=voxwidth))
            if (index != 1)
                push!(gridCOz, gridCOz[index-1]+voxwidth)
            end
        end
    end

    #@assert minimum(gridCOx)>meshXmin
    # Check that the output grid is large enough to cover the mesh:
    var_check=0
    if (minimum(gridCOx)>meshXmin || maximum(gridCOx)<meshXmax)
        var_check = 1
        gridcheckX = 0
        if minimum(gridCOx)>meshXmin
            gridCOx=vcat(meshXmin, gridCOx)
            gridcheckX += 1
        end
        if maximum(gridCOx)<meshXmax
            gridCOx = vcat(gridCOx,meshXmax)
            gridcheckX += 2
        end
    else
        if (minimum(gridCOy)>meshYmin || maximum(gridCOy)<meshYmax)
            var_check = 2
            gridcheckY = 0
            if minimum(gridCOy)>meshYmin
                gridCOy = vcat(meshYmin, gridCOy)
                gridcheckY += 1
            end
            if maximum(gridCOy)<meshYmax
                gridCOy = vcat(gridCOy, meshYmax)
                gridcheckY += 2
            end
        else
            if (minimum(gridCOz)>meshZmin || maximum(gridCOz)<meshZmax)
                var_check = 3
                gridcheckZ = 0
                if minimum(gridCOz)>meshZmin
                    gridCOz = vcat(meshZmin, gridCOz)
                    gridcheckZ += 1
                end
                if maximum(gridCOz)<meshZmax
                    gridCOz = vcat(gridCOz, meshZmax)
                    gridcheckZ += 2
                end
            end
        end
    end
    

    # %======================================================
    # % VOXELISE USING THE USER DEFINED RAY DIRECTION(S)
    # %======================================================
    
    # Count the number of voxels in each direction:
    voxcountX = length(gridCOx)
    voxcountY = length(gridCOy)
    voxcountZ = length(gridCOz)


    v0 = zeros(convert(Int64, length(vertices(meshXYZ))/3), 3)
    v1 = zeros(convert(Int64, length(vertices(meshXYZ))/3), 3)
    v2 = zeros(convert(Int64, length(vertices(meshXYZ))/3), 3)

    i = 1
    j = 1
    k = 1

    #println(vertices(meshXYZ))

    for (index, p) in enumerate(vertices(meshXYZ))
        if (mod(index, 3) == 1)
            v0[i,1] = coordinates(p)[1]
            v0[i,2] = coordinates(p)[2]
            v0[i,3] = coordinates(p)[3]
            i = i + 1
        end
        if (mod(index, 3) == 2)
            v1[j,1] = coordinates(p)[1]
            v1[j,2] = coordinates(p)[2]
            v1[j,3] = coordinates(p)[3]
            j = j + 1
        end
        if (mod(index, 3) == 0)
            v2[k,1] = coordinates(p)[1]
            v2[k,2] = coordinates(p)[2]
            v2[k,3] = coordinates(p)[3]
            k = k + 1
        end
        #println(coordinates(p))
    end

    # display(v0)
    # display(v1)
    # display(v2)

    gridOUTPUT1 = voxel_intern(gridCOy, gridCOz, gridCOx, v0, v1, v2, geometry_desc, 0)
    gridOUTPUT2 = voxel_intern(gridCOz, gridCOx, gridCOy, v0, v1, v2, geometry_desc, 1)
    gridOUTPUT3 = voxel_intern(gridCOx, gridCOy, gridCOz, v0, v1, v2, geometry_desc, 2)

    #from scipy.io import savemat
    #mdic = {"gridOUTPUT1": gridOUTPUT1, "gridOUTPUT2": gridOUTPUT2, "gridOUTPUT3": gridOUTPUT3}
    #savemat("python_grids.mat", mdic)

    gridOUTPUT = fill(false, (voxcountX, voxcountY, voxcountZ))
    gridOUTPUT = merge_the_3_grids(voxcountX, voxcountY, voxcountZ, gridOUTPUT1, gridOUTPUT2, gridOUTPUT3,gridOUTPUT)

    # %======================================================
    # % RETURN THE OUTPUT GRID TO THE SIZE REQUIRED BY THE USER (IF IT WAS CHANGED EARLIER)
    # %======================================================
    #@assert var_check in [1,2,3]
    # match var_check:
    if var_check == 1
        #@assert gridcheckX in [1,2,3]
        if gridcheckX == 1
            gridOUTPUT=gridOUTPUT[2:voxcountX,:,:]
            gridCOx    = gridCOx[2:voxcountX]
        elseif gridcheckX == 2
            gridOUTPUT = gridOUTPUT[1:voxcountX-1, :, :]
            gridCOx = gridCOx[1:voxcountX-1]
        else
            gridOUTPUT = gridOUTPUT[2:voxcountX-1, :, :]
            gridCOx = gridCOx[2:voxcountX-1]
        end
    elseif var_check == 2
        #@assert gridcheckY in [1,2,3]
            if gridcheckY == 1
                gridOUTPUT = gridOUTPUT[:,2:voxcountY, :]
                gridCOy = gridCOy[2:voxcountY]
            elseif gridcheckY == 2
                gridOUTPUT = gridOUTPUT[:, 1:voxcountY-1, :]
                gridCOy = gridCOy[1:voxcountY-1]
            else
                gridOUTPUT = gridOUTPUT[:, 2:voxcountY-1, :]
                gridCOy = gridCOy[2:voxcountY-1]
            end
    else
        #@assert var_check == 3
        #@assert gridcheckZ in [1,2,3]
        if gridcheckZ == 1
            gridOUTPUT = gridOUTPUT[:, :, 2:voxcountZ]
            gridCOz = gridCOz[2:voxcountZ]
        elseif gridcheckZ == 2
            gridOUTPUT = gridOUTPUT[:, :, 1:voxcountZ-1]
            gridCOz = gridCOz[1:voxcountZ-1]
        else
            gridOUTPUT = gridOUTPUT[:, :, 2:voxcountZ-1]
            gridCOz = gridCOz[2:voxcountZ-1]
        end
    end

    #if needed also gridCOx, gridCOy and gridCOz can be given in output
    return gridOUTPUT
end
