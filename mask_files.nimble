# Package
version     = "0.1.0"
author      = "Nathaniel Vos"
description = "Program creates a sanitized set of files for safe testing"
license     = "MIT"

requires "nim >= 1.2.2"
requires "malebolgia"

srcDir = "src"

# Build
task release, "Build project":
  let opts = [
    "--opt:speed",
    "-d:lto",
    "--passC:-march=native",
    "--mm:arc",
    "--threads:on",
    "-d:ThreadPoolSize=8",
    "-d:FixedChanSize=16"
  ].join(" ")
  exec "nim c -d:release " & opts & " --out:bin/masked_files src/mask_files.nim"
