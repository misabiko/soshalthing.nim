# Package

version       = "0.1.0"
author        = "misabiko"
description   = "A web app showing posts through live timelines"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["soshalthing"]


# Dependencies

requires "nim >= 1.4.2", "fetch >= 0.1.0"

task proxy, "Launches the twitter proxy":
    exec "nim c -o:bin/server.exe -r src/soshalthingpkg/twitter/server/server.nim"

task karun, "Launch with karun":
    withDir("bin"):
        exec "karun.cmd -r --css:../src/head.html ../src/soshalthing.nim"

task kawatch, "Launch in watch mode with karun":
    withDir("bin"):
        exec "karun.cmd -r -w --css:../src/head.html ../src/soshalthing.nim"

task userscript, "Build a userscript file":
    discard

task sass, "Build stylesheet":
    exec "sass.cmd -I bulma ../src/sass/index.sass bin/style.css"