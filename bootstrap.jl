(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using JuliaMesher
const UserApp = JuliaMesher
JuliaMesher.main()
