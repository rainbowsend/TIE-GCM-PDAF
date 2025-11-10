This NCAR HAO TIE-GCM fork was created at the Institute for Geodesy and Geoinformation (University of Bonn) by the Group of Astronomical, Physical, and Mathematical Geodesy.

This fork includes modification to combine TIE-GCM 3.0 with the parallel data assimilation framework (PDAF).



# Main modifications
* PDAF integration (must be enabled by using `-DUSEPDAF` preprocessor flag)
* using `mpi_f08`
* some additional consitency checks/limits
* some variables are no longer hard coded, so they can be perturbed
* alternative makefile

# Installation

You need
* a compiler supporting Fortran 2018 features (e.g., GCC 11)
* a MPI implementation supporting mpi_f08 interface (e.g., openMPI 4.1.4)
* a LAPACK implpementation (e.g., OpenBLAS-0.3.20)
* NetCDF-fortran with nc4 support and parallel IO (requires HDF)

## Install submodules

pull dependencies, e.g., using `git submodule update --init`

### esmf
Follow the [installation instructions](https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/node10.html)

### pdaf
Follow the [installation instructions](https://pdaf.awi.de/trac/wiki/CompilingPdaf)

### geodetic-fortran-utilities
`cd deps/geodetic-fortran-utilities`

First you need to set the correct paths in `Make.hostname`. `hostname` is the name of the computer where you compile the program. Use the file `Make.gfortran` as template.
Here, you have to set only three variables, e.g.,
``` bash
FC:=gfortran
CXX:=g++
OPTIM:=-O3 -g -march=native
```

` make -j 8`

## Install TIE-GCM
Change the path to the root directorty of the repository.

First you need to set the correct paths in `Make.hostname`. `hostname` is the name of the computer where you compile the program. Use the file `Make.gfortran` as template.

Try first to install TIE-GCM without PDAF binding using
`WITH_PDAF=FALSE EXE_NAME=tiegcm5.0 BUILD_DIR=build/tiegcm5.0 TGCM_RES=LOW make`

if no error occures install TIE-GCM with PDAF binding

```
rm -rf Depends
WITH_PDAF=TRUE EXE_NAME=tiegcm5.0-pdaf BUILD_DIR=build/tiegcm5.0-pdaf TGCM_RES=LOW make -j 8
```

# Configuration



