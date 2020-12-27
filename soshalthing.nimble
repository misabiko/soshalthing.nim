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
    exec "nim c -o:bin/server.exe -r src/twitter/server/server.nim"