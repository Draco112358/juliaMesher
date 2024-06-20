using JSON, GZip

const esymiaFolderName = "esymiaProjects"
const meshFolderName = "mesherOutputs"
const gridsFolderName = "externalGrids"

function pathSeparator()::String
  separator = ""
  if (Sys.isunix() || Sys.isapple())
    separator = "/"
  end
  if Sys.iswindows()
    separator = "\\"
  end
  return separator
end

function initializeFolders()
  mkpath(homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName)
  mkpath(homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName)
end

function getStorageFilePaths(filename::String)
  meshPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName * pathSeparator() * filename * ".json"
  gridsPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName * pathSeparator() * filename * ".json"
  return meshPath, gridsPath
end

function getStorageFilePathsGZip(filename::String)
  meshPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName * pathSeparator() * filename * ".gz"
  gridsPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName * pathSeparator() * filename * ".gz"
  return meshPath, gridsPath
end

function saveMeshAndGrids(fileName::String, data::Dict)
  initializeFolders()
  (meshPath, gridsPath) = getStorageFilePaths(fileName)
  open(gridsPath, "w") do f
    write(f, JSON.json(data["grids"]))
  end
  open(meshPath, "w") do f
    write(f, JSON.json(data["mesh"]))
  end
  return meshPath, gridsPath
end

function saveMeshAndGrids2(fileName::String, data::Dict)
  initializeFolders()
  (meshPath, gridsPath) = getStorageFilePathsGZip(fileName)
  fh = GZip.open(meshPath, "w")
  write(fh, JSON.json(data["mesh"]))
  close(fh)
  fh2 = GZip.open(gridsPath, "w")
  write(fh2, JSON.json(data["grids"]))
  close(fh2)
  return meshPath, gridsPath
end