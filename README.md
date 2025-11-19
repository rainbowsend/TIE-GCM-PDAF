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

TIEGCM settings are controlled by a [namelist file](https://www.hao.ucar.edu/modeling/tgcm/tiegcm2.0/userguide/html/namelist.html#example-namelist-input-files). The path to this file is the first argument to the executable. When using TIE-GCM-PDAF the executable has a second argument which is the path to another namelist file that controlles the assimilation setup. The namelist parameters are explained in the following:

## Output

In addition to the history files TIE-GCM-PDAF has its own writer, whcih is controlled by this group.

### OUTPUT%RESULT_FILE_NAME_TAG
  Name of the NetCDF file(s). ".nc" is added autmatically.

  Type: string

  Default: `"results"`

  Example: `OUTPUT%RESULT_FILE_NAME_TAG="test"`

### OUTPUT%SAVED_FIELDS
  List of quantities that are included in result file. Maximum supported number of quantities is 20.

  Type: string array

  Default: empty

  Example: `OUTPUT%RESULT_FILE_NAME_TAG='DEN', 'O1', 'O2', 'HE', 'TN', 'NE',`

### OUTPUT%SAVE_STATE
  If true, in addition to the quantities specified in OUTPUT%SAVED_FIELDS, all quantities of the state vector at time step i are also written.

  Type: logical

  Default: `.false.`

  Example: `OUTPUT%SAVE_STATE=.true.`

### OUTPUT%SAVE_STATE_NM
  If true, in addition to the quantities specified in OUTPUT%SAVED_FIELDS, all quantities of the state vector at time step i-1 are also written.

  Type: logical

  Default: `.false.`

  Example: `OUTPUT%SAVE_STATE_NM=.true.`

### OUTPUT%SAVE_OBS
  If true, in addition to the quantities specified in OUTPUT%SAVED_FIELDS, all observed quantities also written.

  Type: logical

  Default: `.true.`

  Example: `OUTPUT%SAVE_OBS=.true.`

### OUTPUT%SAVE_MEMBERS
  Write all ensemle members to the file. This may result in very large files.

  Type: logical

  Default: `.false.`

  Example: `OUTPUT%SAVE_MEMBERS=.true.`

### OUTPUT%SAVE_UNCONSTRAINED_ANALYSIS
  Write the results of the analysis step before the constraints are applied. The constrained quantites are written regardless of this option.

  Type: logical

  Default: `.false.`

  Example: `OUTPUT%SAVE_UNCONSTRAINED_ANALYSIS=.true.`

### OUTPUT%SYNC_EVERY
  Syncing the nc files is a costly operation. This parameter controlls after how many time steps with a writing operation the file is sync. If the model crashes befor data was syncronized it is lost.

  Type: integer

  Default: 10

  Example: `OUTPUT%SYNC_EVERY=100`

### OUTPUT%OUTPUT_STRATEGY
  1: single writer - single file (recommended)
  2: multiple writeres - multiples files

  Type: integer

  Default: 1

  Example: `OUTPUT%OUTPUT_STRATEGY=1`

### OUTPUT%MAX_MOMENT
  Determines which (central) statistical moments are computed
  1: mean
  2: mean, standard deviation
  3: mean, standard deviation, skewness
  4: mean, standard deviation, skewness, excess kurtosis

  Type: integer

  Default: 2

  Example: `OUTPUT%MAX_MOMENT=3`

### OUTPUT%SUPRESS_TIEGCM_OUTPUT
  This option supress the generation of TIEGCM intern history files.

  Type: logical

  Default: `.true.`

  Example: `OUTPUT%SUPRESS_TIEGCM_OUTPUT=.true.`

### OUTPUT%USE_DOUBLE_PRECISION
  If true use 8 byte floating point numbers, else use 8 byte.

  Type: logical

  Default: `.true.`

  Example: `OUTPUT%USE_DOUBLE_PRECISION=.true.`

### OUTPUT%WRITE_EVERY_SEC
  Determines how frequent data is written. The duration in seconds is converted to number of model steps.
  If negative, every time step is saved (not recommended).

  Type: integer

  Default: -1

  Example: `OUTPUT%WRITE_EVERY_SEC=60`

### OUTPUT%FORCE_WRITE_ON_UPDATE
  Write every analysis regardless of writing frequency determined in OUTPUT%WRITE_EVERY_SEC

  Type: logical

  Default: `.true.`

  Example: `OUTPUT%FORCE_WRITE_ON_UPDATE=.true.`

### OUTPUT%LOCK_NC_TIME
  If true all variables in the NetCDF file have the same temporal dimension. With this setting it is not possible to write variables with different temporal resolution.

  Type: logical

  Default: `.true.`

  Example: `OUTPUT%LOCK_NC_TIME=.true.`
