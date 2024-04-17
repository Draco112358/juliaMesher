using LinearAlgebra

function find_pos_min(vect,N)
    min_value=1e30
    pos=0
    for cont in range(1, N)
        if vect[cont]<min_value
            min_value=vect[cont]
            pos=cont
        end
    end

    return pos
end

function find_min_max(vect)
    min_value=minimum(vect)
    max_value=maximum(vect)
    return min_value,max_value
end

function create_min_max_v_from_mesh(v0,v1,v2)
    N_points=size(v0)[1]
    meshXYZmin=zeros(N_points,3)
    meshXYZmax = zeros(N_points, 3)
    temp_V = zeros(3)
    for i in range(1, N_points)
        for j in range(1,3)
            temp_V[1] = v0[i, j]
            temp_V[2] = v1[i, j]
            temp_V[3] = v2[i, j]
            meshXYZmin[i,j],meshXYZmax[i,j] = find_min_max(temp_V)
        end
    end
    return meshXYZmin,meshXYZmax
end

function find_pos_min_max_indices_conditioned(V_min,V_max,dimension,leq,geq)
    N=size(V_min)[1]
    ind=ones(Int64, N)
    pos=0
    for i in range(1,N)
        if (V_min[i,dimension]<=leq && V_max[i,dimension]>=geq)
            pos=pos+1
            ind[pos]=i
        end
    end

    if pos>=1
        ind=ind[1:pos]
    else
        ind = ones(Int64,1)
        ind[1] = 0
    end
    return ind
end

function find_pos_min_max_indices_conditioned_and_indicized(V_min,V_max,indices,dimension,leq,geq)
    N=length(indices)
    ind=ones(Int64,N)
    pos=0
    for i in range(1,N)
        if (V_min[indices[i],dimension]<=leq) && (V_max[indices[i],dimension]>=geq)
            pos = pos + 1
            ind[pos]=i
        end
    end
    if pos >= 1
        ind=ind[1:pos]
    else
        ind = ones(Int64,1)
        ind[1] = 0
    end

    return ind
end

function find_ind_cross_list(v0,v1,v2,possibleCROSSLIST,gridCOxl,gridCOyl)
    N = length(possibleCROSSLIST)
    ind = ones(Int64,N)
    pos = 0
    for i in range(1,N)
        if (v0[possibleCROSSLIST[i],1] == gridCOxl && v1[possibleCROSSLIST[i],1] == gridCOyl) || (v0[possibleCROSSLIST[i], 2] == gridCOxl && v1[possibleCROSSLIST[i], 2] == gridCOyl) || (v0[possibleCROSSLIST[i], 3] == gridCOxl && v1[possibleCROSSLIST[i], 3] == gridCOyl)
            pos = pos + 1
            ind[pos] = i
        end
    end

    if pos >= 1
        ind=ind[1:pos]
    else
        ind = ones(Int64,1)
        ind[1] = 0
    end
    return ind
end

function find_first(V,val)
    N=length(V)
    pos=0
    for i in range(1,N)
        if (val==V[i])
            pos=i
            break
        end
    end
    return pos
end

function find_ind_to_keep_gridC0z(gridCOzCROSS,meshZmin,meshZmax)
    N=length(gridCOzCROSS)
    ind=ones(Int64,N)
    pos=0
    for i in range(1,N)
        if ((gridCOzCROSS[i]>=meshZmin-1e-12) && (gridCOzCROSS[i]<=meshZmax+1e-12))
            pos = pos + 1
            ind[pos]=i
        end
    end

    if pos >= 1
        ind=ind[1:pos]
    else
        ind = ones(Int64,1)
        ind[1] = 0
    end

    return ind
end

function find_ind_voxel_inside(V,val1,val2)
    N=length(V)
    ind=ones(Int64,N)
    pos=0
    for i in range(1,N)
        if (V[i]>val1 && V[i]<val2)
            pos=pos+1
            ind[pos]=i
        end
    end
    if pos >= 1
        ind=ind[1:pos]
    else
        ind = ones(Int64,1)
        ind[1] = 0
    end

    return ind
end

function find_all_equal_on_second_dimension(Mat2D,dimension,val)
    N=size(Mat2D)[1]
    ind = ones(Int64,N)
    pos = 0
    for i in range(1,N)
        if (val==Mat2D[i,dimension])
            pos = pos + 1
            ind[pos] = i
        end
        if pos >= 1
            ind = ind[1:pos]
        else
            ind = ones(Int64,1)
            ind[1] = 0
        end
    end

        return ind
end

function CONVERT_meshformat(v0,v1,v2)

    vertices=vcat(v0, v1)
    vertices = vcat(vertices, v2)
    vertices = sort(unique(vertices, dims=1), dims=1)

    faces = zeros(size(v0)[1], 3)

    for loopF in range(1,size(v0)[1])
        for loopV in range(1,3)
            if (loopV==1)
                ind_1 = find_all_equal_on_second_dimension(vertices, 1, v0[loopF, 1])
                ind_2 = find_all_equal_on_second_dimension(vertices, 2, v0[loopF, 2])
                ind_3 = find_all_equal_on_second_dimension(vertices, 3, v0[loopF, 3])
            else
                if loopV == 2
                    ind_1 = find_all_equal_on_second_dimension(vertices, 1, v1[loopF, 1])
                    ind_2 = find_all_equal_on_second_dimension(vertices, 2, v1[loopF, 2])
                    ind_3 = find_all_equal_on_second_dimension(vertices, 3, v1[loopF, 3])
                else
                    ind_1 = find_all_equal_on_second_dimension(vertices, 1, v2[loopF, 1])
                    ind_2 = find_all_equal_on_second_dimension(vertices, 2, v2[loopF, 2])
                    ind_3 = find_all_equal_on_second_dimension(vertices, 3, v2[loopF, 3])
                end
            end

            if (ind_1[1]!=0 && ind_2[1]!=0 && ind_3[1]!=0)
                vertref = intersect(ind_1, ind_2)
                vertref = intersect(vertref, ind_3)
                if length(vertref)>0
                    faces[loopF, loopV] = vertref[1]
                end
            end
        end
    end

    return faces,vertices
end

function COMPUTE_mesh_normals(v0,v1,v2)

    facetCOUNT = size(v0)[1]
    coordNORMALS = zeros(facetCOUNT,3)

    for loopFACE in range(1,facetCOUNT)

        # Find the coordinates for each vertex
        cornerA = v0[loopFACE, :]
        cornerB = v1[loopFACE, :]
        cornerC = v2[loopFACE, :]

        # Compute the vectors AB and AC
        AB = cornerB - cornerA
        AC = cornerC - cornerA

        # Determine the cross product AB x AC
        ABxAC = cross(AB, AC)

        # Normalise to give a unit vector
        ABxAC = ABxAC / norm(ABxAC)
        coordNORMALS[loopFACE, :] = ABxAC
    end

    return coordNORMALS
end

function voxel_intern(grid_x,grid_y,grid_z,v0_in,v1_in,v2_in,input_desc,case_perm)

    voxcountX = length(grid_x)
    voxcountY = length(grid_y)
    voxcountZ = length(grid_z)

    gridOUTPUT = fill(false,(voxcountX,voxcountY,voxcountZ))

    Nnodes=size(v0_in)[1]
    #@assert case_perm in [0,1,2]
    if case_perm==0
        meshXmin = input_desc["meshYmin"]
        meshXmax = input_desc["meshYmax"]
        meshYmin = input_desc["meshZmin"]
        meshYmax = input_desc["meshZmax"]
        meshZmin = input_desc["meshXmin"]
        meshZmax = input_desc["meshXmax"]
        v0 = zeros(Nnodes, 3)
        v1 = zeros(Nnodes, 3)
        v2 = zeros(Nnodes, 3)

        v0[:, 1]=  v0_in[:, 2]
        v1[:, 1] = v1_in[:, 2]
        v2[:, 1] = v2_in[:, 2]
        v0[:, 2] = v0_in[:, 3]
        v1[:, 2] = v1_in[:, 3]
        v2[:, 2] = v2_in[:, 3]
        v0[:, 3] = v0_in[:, 1]
        v1[:, 3] = v1_in[:, 1]
        v2[:, 3] = v2_in[:, 1]
    elseif case_perm==1
        meshXmin = input_desc["meshZmin"]
        meshXmax = input_desc["meshZmax"]
        meshYmin = input_desc["meshXmin"]
        meshYmax = input_desc["meshXmax"]
        meshZmin = input_desc["meshYmin"]
        meshZmax = input_desc["meshYmax"]
        v0 = zeros(Nnodes, 3)
        v1 = zeros(Nnodes, 3)
        v2 = zeros(Nnodes, 3)

        v0[:, 1] = v0_in[:, 3]
        v1[:, 1] = v1_in[:, 3]
        v2[:, 1] = v2_in[:, 3]
        v0[:, 2] = v0_in[:, 1]
        v1[:, 2] = v1_in[:, 1]
        v2[:, 2] = v2_in[:, 1]
        v0[:, 3] = v0_in[:, 2]
        v1[:, 3] = v1_in[:, 2]
        v2[:, 3] = v2_in[:, 2]
    else
        #@assert case_perm==2
        meshXmin = input_desc["meshXmin"]
        meshXmax = input_desc["meshXmax"]
        meshYmin = input_desc["meshYmin"]
        meshYmax = input_desc["meshYmax"]
        meshZmin = input_desc["meshZmin"]
        meshZmax = input_desc["meshZmax"]
        v0 = v0_in
        v1 = v1_in
        v2 = v2_in
    end

    # %Identify the min and max x,y coordinates (pixels) of the mesh:
    vect_temp=zeros(size(grid_x)[1])
    for cont in range(1,size(grid_x)[1])
        vect_temp[cont]=abs(grid_x[cont]-meshXmin)
    end
    meshXminp = find_pos_min(vect_temp, size(grid_x)[1])

    for cont in range(1,size(grid_x)[1])
        vect_temp[cont]=abs(grid_x[cont]-meshXmax)
    end
    meshXmaxp = find_pos_min(vect_temp, size(grid_x)[1])

    vect_temp = zeros(size(grid_y)[1])
    for cont in range(1,size(grid_y)[1])
        vect_temp[cont] = abs(grid_y[cont] - meshYmin)
    end
    meshYminp = find_pos_min(vect_temp, size(grid_y)[1])

    for cont in range(1,size(grid_y)[1])
        vect_temp[cont] = abs(grid_y[cont] - meshYmax)
    end
    meshYmaxp = find_pos_min(vect_temp, size(grid_y)[1])

    # %Make sure min < max for the mesh coordinates:
    if meshXminp > meshXmaxp
        temp=meshXminp
        meshXminp=meshXmaxp
        meshXmaxp=temp
    end
    if meshYminp > meshYmaxp
        temp = meshYminp
        meshYminp=meshYmaxp
        meshYmaxp=temp
    end

    # %Identify the min and max x,y,z coordinates of each facet:
    meshXYZmin,meshXYZmax = create_min_max_v_from_mesh(v0,v1,v2)
    #println(length(meshXYZmin))
    # %======================================================
    # % VOXELISE THE MESH
    # %======================================================

    correctionLIST = ones(Int64,0,2)   #Prepare to record all rays that fail the voxelisation.  This array is built on-the-fly, but since
                                                               #it ought to be relatively small should not incur too much of a speed penalty.

    shift_div=4.37463724e-14 #to avoid division by 0

    #shift_div=0

    # % Loop through each x,y pixel.
    # % The mesh will be voxelised by passing rays in the z-direction through
    # % each x,y pixel, and finding the locations where the rays cross the mesh.
    for loopY in range(meshYminp,meshYmaxp)
        
        
        #println(meshYmaxp)
        #   % - 1a - Find which mesh facets could possibly be crossed by the ray:
        ind_pcc = find_pos_min_max_indices_conditioned(meshXYZmin, meshXYZmax, 2, grid_y[loopY], grid_y[loopY])
        #display(ind_pcc)
        if ind_pcc[1] != 0
            possibleCROSSLISTy = ind_pcc

            for loopX in range(meshXminp,meshXmaxp)
                #println("loopX => ", loopX)
                #     % - 1b - Find which mesh facets could possibly be crossed by the ray:
                ind_pos=find_pos_min_max_indices_conditioned_and_indicized(meshXYZmin, meshXYZmax,possibleCROSSLISTy ,1, grid_x[loopX], grid_x[loopX])
                #println(ind_pos)
                if ind_pos[1]!=0

                    possibleCROSSLIST = possibleCROSSLISTy[ind_pos]

                    if length(possibleCROSSLIST)>0
                        #Only continue the analysis if some nearby facets were actually identified
                        #  - 2 - For each facet, check if the ray really does cross the facet rather than just passing it close-by:
                        # GENERAL METHOD:
                        # A. Take each edge of the facet in turn.
                        # B. Find the position of the opposing vertex to that edge.
                        # C. Find the position of the ray relative to that edge.
                        # D. Check if ray is on the same side of the edge as the opposing vertex.
                        # E. If this is true for all three edges, then the ray definitely passes through the facet.
                        #
                        # NOTES:
                        # A. If a ray crosses exactly on a vertex:
                        #   a. If the surrounding facets have normal components pointing in the same (or opposite) direction as the ray then the face IS crossed.
                        #   b. Otherwise, add the ray to the correctionlist.

                        facetCROSSLIST = zeros(Int64,0)  #Prepare to record all facets which are crossed by the ray.  This array is built on-the-fly, but since
                        # it ought to be relatively small (typically a list of <10) should not incur too much of a speed penalty.

                        #----------
                        # - 1 - Check for crossed vertices:
                        #---------

                        #Find which mesh facets contain a vertex which is crossed by the ray:
                        
                        ind_ccl=find_ind_cross_list(v0,v1,v2, possibleCROSSLIST, grid_x[loopX], grid_y[loopY])
                        if ind_ccl[1] != 0
                            vertexCROSSLIST=possibleCROSSLIST[ind_ccl]
                            checkindex = zeros(Int64,length(vertexCROSSLIST))

                            continue_cycle=true
                            while continue_cycle==true
                                vertexindex=find_first(checkindex, 0)
                                if vertexindex==1
                                    continue_cycle=false
                                else
                                    vertexindex = find_first(checkindex, -1)
                                    temp_faces, temp_vertices = CONVERT_meshformat(v0[vertexCROSSLIST,:],v1[vertexCROSSLIST,:],v2[vertexCROSSLIST,:])
                                    adjacentindex = [i in temp_faces[vertexindex,:] for i in temp_faces]
                                    coN=zeros(size(adjacentindex)[1],3)
                                    p_in=0
                                    for caux in range(1,size(adjacentindex)[1])
                                        if any(adjacentindex[caux,:])==true
                                            checkindex[caux]=1
                                            p_in=p_in+1
                                            coN[p_in,:]= COMPUTE_mesh_normals(v0[vertexCROSSLIST[caux],:,:], v1[vertexCROSSLIST[caux],:,:],v2[vertexCROSSLIST[caux], :, :] )
                                        end
                                    end
                                    if p_in!=0
                                        minco,maxc0=find_min_max([coN[:,3], size(coN)[1]])
                                        if maxc0<0 || minco>0
                                            facetCROSSLIST    = [facetCROSSLIST vertexCROSSLIST[vertexindex]]
                                        end
                                    else
                                        possibleCROSSLIST = zeros(Int64,0)
                                        correctionLIST    = vcat(correctionLIST, [loopX loopY])
                                        checkindex = ones(Int64,length(vertexCROSSLIST))
                                    end
                                end
                            end
                        end
                    end
                    #----------
                    # - 2 - Check for crossed facets:
                    #----------
                    Npc=length(possibleCROSSLIST)
                    if Npc>0  #Only continue the analysis if some nearby facets were actually identified
                        for i in range(1,Npc)
                            loopCHECKFACET= possibleCROSSLIST[i]

                            if loopCHECKFACET!=0

                                #Check if ray crosses the facet.  This method is much (>>10 times) faster than using the built-in function 'inpolygon'.
                                #Taking each edge of the facet in turn, check if the ray is on the same side as the opposing vertex.

                                Y1predicted = v1[loopCHECKFACET,2] - ((v1[loopCHECKFACET,2] -v2[loopCHECKFACET,2] ) * (v1[loopCHECKFACET,1] -v0[loopCHECKFACET,1] )/(shift_div+v1[loopCHECKFACET,1] -v2[loopCHECKFACET,1] ))
                                YRpredicted = v1[loopCHECKFACET,2]  - ((v1[loopCHECKFACET,2] -v2[loopCHECKFACET,2] ) * (v1[loopCHECKFACET,1] -grid_x[loopX])/(shift_div+v1[loopCHECKFACET,1]-v2[loopCHECKFACET,1]))

                                if (Y1predicted > v0[loopCHECKFACET,2] && YRpredicted > grid_y[loopY]) || (Y1predicted < v0[loopCHECKFACET,2] && YRpredicted < grid_y[loopY])
                                    #The ray is on the same side of the 2-3 edge as the 1st vertex.

                                    Y2predicted = v2[loopCHECKFACET,2] - ((v2[loopCHECKFACET,2]-v0[loopCHECKFACET,2]) * (v2[loopCHECKFACET,1]-v1[loopCHECKFACET,1])/(shift_div+v2[loopCHECKFACET,1]-v0[loopCHECKFACET,1]))
                                    YRpredicted = v2[loopCHECKFACET,2] - ((v2[loopCHECKFACET,2]-v0[loopCHECKFACET,2]) * (v2[loopCHECKFACET,1]-grid_x[loopX])/(shift_div+v2[loopCHECKFACET,1]-v0[loopCHECKFACET,1]))

                                    if (Y2predicted > v1[loopCHECKFACET,2] && YRpredicted > grid_y[loopY]) || (Y2predicted < v1[loopCHECKFACET,2] && YRpredicted < grid_y[loopY])
                                        #The ray is on the same side of the 3-1 edge as the 2nd vertex.
                                        Y3predicted = v0[loopCHECKFACET,2] - ((v0[loopCHECKFACET,2]-v1[loopCHECKFACET,2]) * (v0[loopCHECKFACET,1]-v2[loopCHECKFACET,1])/(shift_div+v0[loopCHECKFACET,1]-v1[loopCHECKFACET,1]))
                                        YRpredicted = v0[loopCHECKFACET,2] - ((v0[loopCHECKFACET,2]-v1[loopCHECKFACET,2]) * (v0[loopCHECKFACET,1]-grid_x[loopX])/(shift_div+v0[loopCHECKFACET,1]-v1[loopCHECKFACET,1]))

                                        if (Y3predicted > v2[loopCHECKFACET,2] && YRpredicted > grid_y[loopY]) || (Y3predicted < v2[loopCHECKFACET,2] && YRpredicted < grid_y[loopY])
                                            # The ray is on the same side of the 1-2 edge as the 3rd vertex.
                                            #The ray passes through the facet since it is on the correct side of all 3 edges
                                            
                                            facetCROSSLIST = [facetCROSSLIST ; loopCHECKFACET]
                                        end
                                    end
                                end
                            end
                        end
                    end

                    #----------
                    # - 3 - Find the z coordinate of the locations where the ray crosses each facet or vertex:
                    #----------

                    Nfc = length(facetCROSSLIST)
                    grid_zCROSS = zeros(Nfc)
                    for i in range(1,Nfc)
                        loopFINDZ=facetCROSSLIST[i]

                        #  METHOD:
                        # 1. Define the equation describing the plane of the facet.  For a
                        # more detailed outline of the maths, see:
                        # http://local.wasp.uwa.edu.au/~pbourke/geometry/planeeq/
                        #    Ax + By + Cz + D = 0
                        #    where  A = y1 (z2 - z3) + y2 (z3 - z1) + y3 (z1 - z2)
                        #           B = z1 (x2 - x3) + z2 (x3 - x1) + z3 (x1 - x2)
                        #           C = x1 (y2 - y3) + x2 (y3 - y1) + x3 (y1 - y2)
                        #           D = - x1 (y2 z3 - y3 z2) - x2 (y3 z1 - y1 z3) - x3 (y1 z2 - y2 z1)
                        # 2. For the x and y coordinates of the ray, solve these equations to find the z coordinate in this plane.

                        planecoA = v0[loopFINDZ,2]*(v1[loopFINDZ,3]-v2[loopFINDZ,3]) + v1[loopFINDZ,2]*(v2[loopFINDZ,3]-v0[loopFINDZ,3]) + v2[loopFINDZ,2]*(v0[loopFINDZ,3]-v1[loopFINDZ,3])
                        planecoB = v0[loopFINDZ,3]*(v1[loopFINDZ,1]-v2[loopFINDZ,1]) + v1[loopFINDZ,3]*(v2[loopFINDZ,1]-v0[loopFINDZ,1]) + v2[loopFINDZ,3]*(v0[loopFINDZ,1]-v1[loopFINDZ,1])
                        
                        planecoC = v0[loopFINDZ,1]*(v1[loopFINDZ,2]-v2[loopFINDZ,2]) + v1[loopFINDZ,1]*(v2[loopFINDZ,2]-v0[loopFINDZ,2]) + v2[loopFINDZ,1]*(v0[loopFINDZ,2]-v1[loopFINDZ,2])
                        
                        planecoD = - v0[loopFINDZ,1]*(v1[loopFINDZ,2]*v2[loopFINDZ,3]-v2[loopFINDZ,2]*v1[loopFINDZ,3]) - v1[loopFINDZ,1]*(v2[loopFINDZ,2]*v0[loopFINDZ,3]-v0[loopFINDZ,2]*v2[loopFINDZ,3]) - v2[loopFINDZ,1]*(v0[loopFINDZ,2]*v1[loopFINDZ,3]-v1[loopFINDZ,2]*v0[loopFINDZ,3])
                        
                        if abs(planecoC) < 1e-14
                            planecoC=0.0
                        end

                        grid_zCROSS[i] = (- planecoD - planecoA*grid_x[loopX] - planecoB*grid_y[loopY]) / (shift_div+planecoC)
                    end
                    # Remove values of grid_zCROSS which are outside of the mesh limits (including a 1e-12 margin for error).
                    ind_pos_keep=find_ind_to_keep_gridC0z(grid_zCROSS, meshZmin, meshZmax)
                    
                    if ind_pos_keep[1] != 0
                        grid_zCROSS=grid_zCROSS[ind_pos_keep]

                        #Round grid_zCROSS to remove any rounding errors, and take only the unique values:
                        grid_zCROSS = round.(grid_zCROSS*1e12)/1e12
                        
                        grid_zCROSS = sort(unique(grid_zCROSS))
    
                        #----------
                        # - 4 - Label as being inside the mesh all the voxels that the ray passes through after crossing one facet before crossing another facet:
                        #----------
                        if mod(length(grid_zCROSS), 2)==0 #Only rays which cross an even number of facets are voxelised
                            for loopASSIGN in range(1,Int64(floor(length(grid_zCROSS)/2)))
                                voxelsINSIDE = find_ind_voxel_inside(grid_z,grid_zCROSS[2*(loopASSIGN)-1],grid_zCROSS[2*(loopASSIGN)])
                                if voxelsINSIDE[1] != 0
                                    gridOUTPUT[loopX,loopY,voxelsINSIDE] .= true
                                end
                            end
                        else
                            if length(grid_zCROSS)>0  # Remaining rays which meet the mesh in some way are not voxelised, but are labelled for correction later.
                                correctionLIST=vcat(correctionLIST, [loopX loopY])
                            end
                        end
                    end
                end
            end
        end
    end

        # ======================================================
        #  USE INTERPOLATION TO FILL IN THE RAYS WHICH COULD NOT BE VOXELISED
        # ======================================================
        # For rays where the voxelisation did not give a clear result, the ray is
        # computed by interpolating from the surrounding rays.

    countCORRECTIONLIST = size(correctionLIST)[1]



    if countCORRECTIONLIST>0
    
        # If necessary, add a one-pixel border around the x and y edges of the
        # array.  This prevents an error if the code tries to interpolate a ray at
        # the edge of the x,y grid.
        if minimum(correctionLIST[:,1])==1 || maximum(correctionLIST[:,1])==(length(grid_x)) || minimum(correctionLIST[:,2])==1 || maximum(correctionLIST[:,2])==(length(grid_y))
            temp = [(fill(false, (voxcountX, 1, voxcountZ))) gridOUTPUT]
            temp = [temp fill(false,(voxcountX, 1, voxcountZ))]
            temp = vcat(fill(false, (1, voxcountY+2, voxcountZ)),temp)
            gridOUTPUT = vcat(temp, fill(false,(1, voxcountY+2, voxcountZ)))
            correctionLIST = correctionLIST + ones(Int64,countCORRECTIONLIST,2)
        end

  
        for loopC in range(1,countCORRECTIONLIST)
            for cz in range(1,size(gridOUTPUT)[3])
                voxelsforcorrection = 0
                if gridOUTPUT[correctionLIST[loopC,1]-1,correctionLIST[loopC,2]-1,cz]==true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC,1]-1,correctionLIST[loopC,2],cz]==true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC, 1] - 1, correctionLIST[loopC, 2]+1, cz] == true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC, 1] , correctionLIST[loopC, 2] , cz] == true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC, 1] , correctionLIST[loopC, 2] + 1, cz] == true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC, 1] + 1, correctionLIST[loopC, 2] - 1, cz] == true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC, 1] + 1, correctionLIST[loopC, 2] , cz] == true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if gridOUTPUT[correctionLIST[loopC, 1] + 1, correctionLIST[loopC, 2] + 1, cz] == true
                    voxelsforcorrection=voxelsforcorrection+1
                end
                if voxelsforcorrection>3
                    #gridOUTPUT[correctionLIST[loopC, 1], correctionLIST[loopC, 2], voxelsforcorrection] = true
                    gridOUTPUT[correctionLIST[loopC, 1], correctionLIST[loopC, 2], cz] = true
                end
            end
        end

        #Remove the one-pixel border surrounding the array, if this was added previously
        Ntx = size(gridOUTPUT)[1]
        Nty = size(gridOUTPUT)[2]

        if (Ntx>length(grid_x) || Nty>length(grid_y))
            gridOUTPUT = gridOUTPUT[2:Ntx,2:Nty,:]
        end
    end
    
    return gridOUTPUT

end
