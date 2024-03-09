## Start the server
In order to start the Genie server, follow these istructions:
- Within the *mesher* folder create a .env file with a constant named "JULIA_PATH" containing the absolute path to your Julia executable.
- run the script ./bin/server

Genie will be started in dev mode, listening on port 8001. 
If you would, you coud change the port and other server attributes within the *.config/env/dev.jl* file

## Server resources
Resources that Genie expose are defined in the *routes.jl* file.

## Additional file
You can add custom code within the *lib* folder, so they will be automatically loaded by Genie on startup. Genie infact includes the files placed within the *lib* folder and subfolders recursively.
