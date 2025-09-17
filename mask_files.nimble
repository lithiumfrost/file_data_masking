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
    --opt:speed
    --define:lto
    --define:release
    --passC:"-march=native"
    --mm:arc
    --threads:on
    --define:"ThreadPoolSize=8"
    --define:"FixedChanSize=16"
    --out:bin/masked_files 
    setCommand "c", "src/mask_files.nim"
