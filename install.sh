#!/bin/bash
#
# Compiles TIE-GCM with different resolutions, with and without PDAF
# integration by calling the makefile with different environment variables.
# Binaries are written to bin. Object, module, and dependency files are written
# to separate folders.
#
# binary name       | horizontal | pressure  | PDAF     |
#                   | resolution | level     | coupling |
# ------------------|------------|-----------|----------|
# tiegcm5.0         | 5.0°       | -7 : +7   | F        |
# tiegcm5.0-pdaf    | 5.0°       | -7 : +7   | T        |
# tiegcm2.5         | 2.5°       | -7 : +7   | F        |
# tiegcm2.5-pdaf    | 2.5°       | -7 : +7   | T        |
# tiegcm2.5_ae-pdaf | 2.5°       | -7 : +11  | T        |

WITH_PDAF=FALSE EXE_NAME=tiegcm5.0 BUILD_DIR=build/tiegcm5.0 HIGH_RES=FALSE make -j 8

WITH_PDAF=TRUE EXE_NAME=tiegcm5.0-pdaf BUILD_DIR=build/tiegcm5.0-pdaf HIGH_RES=FALSE make -j 8

WITH_PDAF=FALSE EXE_NAME=tiegcm2.5 BUILD_DIR=build/tiegcm2.5 HIGH_RES=TRUE make -j 8

WITH_PDAF=TRUE EXE_NAME=tiegcm2.5-pdaf BUILD_DIR=build/tiegcm2.5-pdaf HIGH_RES=TRUE make -j 8

WITH_PDAF=TRUE EXE_NAME=tiegcm2.5_ae-pdaf BUILD_DIR=build/tiegcm2.5_ae-pdaf HIGH_RES=TRUE ALT_EXT=TRUE make -j 8
