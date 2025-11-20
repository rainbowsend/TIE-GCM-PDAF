This NCAR HAO TIE-GCM fork was created at the Institute for Geodesy and Geoinformation (University of Bonn) by the Group of Astronomical, Physical, and Mathematical Geodesy.

This fork includes modifications to combine TIE-GCM 3.0 with the parallel data assimilation framework (PDAF).



# Main modifications
* PDAF integration (must be enabled by using `-DUSEPDAF` preprocessor flag)
* using `mpi_f08`
* some additional consistency checks/limits
* some variables are no longer hard-coded, so they can be perturbed
* alternative makefile

# Installation

You need
* a compiler supporting Fortran 2018 features (e.g., GCC 11)
* a MPI implementation supporting mpi_f08 interface (e.g., openMPI 4.1.4)
* a LAPACK implementation (e.g., OpenBLAS-0.3.20)
* NetCDF-fortran with nc4 support and parallel IO (requires HDF)

## Install submodules

pull dependencies, e.g., using `git submodule update --init`

### esmf
Follow the [installation instructions](https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/node10.html)

### pdaf
Follow the [installation instructions](https://pdaf.awi.de/trac/wiki/CompilingPdaf)

### geodetic-fortran-utilities
`cd deps/geodetic-fortran-utilities`

First, you need to set the correct paths in `Make.hostname`. `hostname` is the name of the computer where you compile the program. Use the file `Make.gfortran` as template.
Here, you have to set only three variables, e.g.,
``` bash
FC:=gfortran
CXX:=g++
OPTIM:=-O3 -g -march=native
```

` make -j 8`

## Install TIE-GCM
Change the path to the root directory of the repository.

First, you need to set the correct paths in `Make.hostname`. `hostname` is the name of the computer where you compile the program. Use the file `Make.gfortran` as a template.

Try first to install TIE-GCM without PDAF binding using
`WITH_PDAF=FALSE EXE_NAME=tiegcm5.0 BUILD_DIR=build/tiegcm5.0 TGCM_RES=LOW make`

If no error occurs install TIE-GCM with PDAF binding

```
rm -rf Depends
WITH_PDAF=TRUE EXE_NAME=tiegcm5.0-pdaf BUILD_DIR=build/tiegcm5.0-pdaf TGCM_RES=LOW make -j 8
```

# Configuration

TIEGCM settings are controlled by a [namelist file](https://www.hao.ucar.edu/modeling/tgcm/tiegcm2.0/userguide/html/namelist.html#example-namelist-input-files). The path to this file is the first argument to the executable. When using TIE-GCM-PDAF, the executable has a second argument, which is the path to another namelist file that controls the assimilation setup. The namelist parameters are explained in the following:

## Output

In addition to the history files, TIE-GCM-PDAF has its own writer, which is controlled by this group.

### OUTPUT%RESULT_FILE_NAME_TAG
  Name of the NetCDF file(s). ".nc" is added automatically.

  **Type**: string

  **Default**: `"results"`

  **Example**: `OUTPUT%RESULT_FILE_NAME_TAG="test"`

### OUTPUT%SAVED_FIELDS
  List of quantities that are included in the result file. The maximum supported number of quantities is 20.

  **Type**: string array

  **Default**: empty

  **Example**: `OUTPUT%RESULT_FILE_NAME_TAG='DEN', 'O1', 'O2', 'HE', 'TN', 'NE',`

### OUTPUT%SAVE_STATE
  If true, in addition to the quantities specified in OUTPUT%SAVED_FIELDS, all state vector quantities at time step i are also written.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `OUTPUT%SAVE_STATE=.true.`

### OUTPUT%SAVE_STATE_NM
  If true, in addition to the quantities specified in OUTPUT%SAVED_FIELDS, all quantities of the state vector at time step i-1 are also written.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `OUTPUT%SAVE_STATE_NM=.true.`

### OUTPUT%SAVE_OBS
  If true, in addition to the quantities specified in OUTPUT%SAVED_FIELDS, all observed quantities are also written.

  **Type**: logical

  **Default**: `.true.`

  **Example**: `OUTPUT%SAVE_OBS=.true.`

### OUTPUT%SAVE_MEMBERS
  Write all ensemble members to the file. This may result in very large files.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `OUTPUT%SAVE_MEMBERS=.true.`

### OUTPUT%SAVE_UNCONSTRAINED_ANALYSIS [expert]
  Write the results of the analysis step before applying the constraints. The constrained quantities are written regardless of this option.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `OUTPUT%SAVE_UNCONSTRAINED_ANALYSIS=.true.`

### OUTPUT%SYNC_EVERY
  Syncing the nc files is a costly operation. This parameter controls how many time steps after a writing operation the file is synced. If the model crashes before the data is synchronized, it is lost.

  **Type**: integer

  **Default**: 10

  **Example**: `OUTPUT%SYNC_EVERY=100`

### OUTPUT%OUTPUT_STRATEGY [expert]
  1: single writer - single file (recommended)

  2: multiple writers - multiple files

  **Type**: integer

  **Default**: 1

  **Example**: `OUTPUT%OUTPUT_STRATEGY=1`

### OUTPUT%MAX_MOMENT
  Determines which (central) statistical moments are computed

  1: mean

  2: mean, standard deviation

  3: mean, standard deviation, skewness

  4: mean, standard deviation, skewness, excess kurtosis

  **Type**: integer

  **Default**: 2

  **Example**: `OUTPUT%MAX_MOMENT=3`

### OUTPUT%SUPRESS_TIEGCM_OUTPUT
  This option suppresses the generation of TIEGCM intern history files.

  **Type**: logical

  **Default**: `.true.`

  **Example**: `OUTPUT%SUPRESS_TIEGCM_OUTPUT=.true.`

### OUTPUT%USE_DOUBLE_PRECISION
  If true, use 8-byte floating-point numbers; else, use 4-byte floating-point numbers.

  **Type**: logical

  **Default**: `.true.`

  **Example**: `OUTPUT%USE_DOUBLE_PRECISION=.true.`

### OUTPUT%WRITE_EVERY_SEC
  Determines how frequently data is written. The duration in seconds is converted to the number of model steps.
  If negative, every time step is saved (not recommended).

  **Type**: integer

  **Default**: -1

  **Example**: `OUTPUT%WRITE_EVERY_SEC=60`

### OUTPUT%FORCE_WRITE_ON_UPDATE
  Write every analysis regardless of writing frequency determined in OUTPUT%WRITE_EVERY_SEC

  **Type**: logical

  **Default**: `.true.`

  **Example**: `OUTPUT%FORCE_WRITE_ON_UPDATE=.true.`

### OUTPUT%LOCK_NC_TIME
  If true, all variables in the NetCDF file have the same temporal dimension. With this setting, it is not possible to write variables with different temporal resolutions.

  **Type**: logical

  **Default**: `.true.`

  **Example**: `OUTPUT%LOCK_NC_TIME=.true.`

## calibration

### CALIBRATION%APPLY
  Enables co-estimation of model parameters. The parameters are selected in the `parameters` group.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `CALIBRATION%APPLY=.true.`

### CALIBRATION%LOCALIZATION_TAPERING
  Tapering factor applied in the update step for the co-estimated parameters.

  **Type**: real

  **Default**: `1.0`

  **Example**: `CALIBRATION%LOCALIZATION_TAPERING=1.0`

### CALIBRATION%EVERY
  Controls how often the parameters are co-estimated. `1 ` indicates that parameters are co-estimated at every analysis step, `2` indicates they are estimated every second analysis step, and so on.

  **Type**: integer

  **Default**: `1`

  **Example**: `CALIBRATION%EVERY=10`

## constraints
After each analysis step, constraints are applied to ensure the state is physically consistent.

### CONSTRAINTS%QUASI_NEUTRAL_IONOSPHERE [expert, experimental]
  Replaces electron density with the sum of all ions. Not recommended.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `CONSTRAINTS%QUASI_NEUTRAL_IONOSPHERE=.false.`

## parameters

### PARAMETERS%ENSEMBLE_FILE
  Default path to NetCDF file containing the parameter perturbations for all ensemble members.

  **Type**: string

  **Default**: `""`

  **Example**: `PARAMETERS%ENSEMBLE_FILE="./perturbations.nc"`

### paramter setup
Currently, the following parameters can be controlled:

* f107
* ctpoten
* hspower
* tlbc
* zlbc
* ulbc
* vlbc
* alfac
* alfad
* colfac
* joulefac
* swden
* swvel
* imfbx
* imfby
* imfbz
* imfbf
* igrf_sh
* co2u

Each parameter has two settings

#### HANDLING
  Controls how the program handles a parameter:

  "none": the parameter is not influenced by the assimilation system

  "perturb": Perturb the parameter according to the perturbations in the specified ensemble file.

  "calibrate": Co-estimate the parameter

  "overwrite": overwrite the parameter by the values (not perturbations) specified inthe  ensemble file

  "mean": replace the parameter with the ensemble mean specified in the ensemble file

  **Type**: string

  **Default**: `"none"`

  **Example**:  `PARAMETERS%F107%HANDLING="perturb"`

#### ENSEMBLE_FILE
  Either the path to an ensemble file or "default". In case of default, the file specified in `PARAMETERS%ENSEMBLE_FILE` is used.

  **Type**: string

  **Default**: `"default"`

  **Example**:  `PARAMETERS%F107%ENSEMBLE_FILE="./some_file"`

## filter
Controls the Kalman filter

### FILTER%OPEN_LOOP
  In an open-loop simulation, all ensemble members are propagated and perturbed, but observations are not assimilated. The filter is not applied.

  **Type**: logical

  **Default**: `.false.`

  **Example**: ` FILTER%OPEN_LOOP=.true.`


### FILTER%SPLINE_DEGREE
  Controls how the observation operator interpolates the state to the observation space.

  1 linear interpolation

  2 quadratic B-spline

  3 cubic B-spline

  4 quartic B-spline

  5 quintic B-spline

  **Type**: integer

  **Default**: 3

  **Example**: `FILTER%SPLINE_DEGREE=3`

### FILTER%FIRST_ANALYSIS_STEP_SEC

  Specifies how many seconds after initializing the model, the first analysis step is performed

  **Type**: integer

  **Default**: 0

  **Example**: `FILTER%FIRST_ANALYSIS_STEP_SEC=60`

### FILTER%FORECAST_DURATION_SEC

  Specifies the duration in seconds between two subsequent analysis steps

  **Type**: integer

  **Default**: 0

  **Example**: `FILTER%FORECAST_DURATION_SEC=120`


### FILTER%FILTERTYPE

  Specifies the filter algorithm used by PDAF. Currently, only the following two filters are implemented.

  6: global ESTKF

  7: localized ESTKF

  **Type**: integer

  **Default**: 6

  **Example**: `FILTER%FILTERTYPE=7`

### FILTER%SUBTYPE [expert]

  Specifies the sub type ([see PDAF wiki](https://pdaf.awi.de/trac/wiki/AvailableOptionsforInitPDAF))

  **Type**: integer

  **Default**: 0

  **Example**: `FILTER%SUBTYPE=0`

### FILTER%TYPE_TRANS [expert]

  Specifies the type of ensemble transformation matrix ([see PDAF wiki](https://pdaf.awi.de/trac/wiki/AvailableOptionsforInitPDAF))

  **Type**: integer

  **Default**: 0

  **Example**: `FILTER%TYPE_TRANS=0`

### FILTER%TYPE_FORGET [expert]

  Specifies the type of forgetting factor ([see PDAF wiki](https://pdaf.awi.de/trac/wiki/AvailableOptionsforInitPDAF))

  **Type**: integer

  **Default**: 0

  **Example**: `FILTER%TYPE_FORGET=0`

### FILTER%TYPE_SQRT [expert]

  Specifies the type of transformation matrix square root ([see PDAF wiki](https://pdaf.awi.de/trac/wiki/AvailableOptionsforInitPDAF))

  **Type**: integer

  **Default**: 0

  **Example**: `FILTER%TYPE_SQRT=0`

### FILTER%LOCWEIGHT

  Specifies how the distance between observations and states is weighted when using localization

  0: unit weight

  1: exponential

  2: finite function mimicking a Gaussian

  **Type**: integer

  **Default**: 1

  **Example**: `FILTER%LOCWEIGHT=0`

### FILTER%cutoff_radius

  Specifies the cutoff radius for localization in zonal, meridional, and vertical directions. Units depend on `filter%localization_coord_sys`

  **Type**: real array

  **Default**: 0,0,0

  **Example**: `FILTER%CUTOFF_RADIUS= 1000E+3,1000E+3,50E+3`

### FILTER%SUPPORT_RADIUS

  Specifies the support radius for localization in zonal, meridional, and vertical directions. Units depend on `filter%localization_coord_sys`

  **Type**: real array

  **Default**: 0,0,0

  **Example**: `FILTER%SUPPORT_RADIUS= 1000E+3,1000E+3,50E+3`

### FILTER%LOCALIZATION_COORD_SYS

  Specifies how the distance between observations and states is measured

  1: distance in meters computed using the haversine formula

  2: distance in number of grid cells

  **Type**: integer

  **Default**: 1

  **Example**: `FILTER%LOCALIZATION_COORD_SYS=1`

### FILTER%SUB_DOMAIN_SIZE_VERTICAL

  vertical extent of sub-domains (number of grid cells)

  **Type**: integer

  **Default**: 3

  **Example**: `FILTER%SUB_DOMAIN_SIZE_VERTICAL=1`

### FILTER%SUB_DOMAIN_SIZE_ZONAL

  zonal extent of sub-domains (number of grid cells)

  **Type**: integer

  **Default**: 3

  **Example**: `FILTER%SUB_DOMAIN_SIZE_ZONAL=1`

### FILTER%SUB_DOMAIN_SIZE_MERIDIONAL

  meridional extent of sub-domains (number of grid cells)

  **Type**: integer

  **Default**: 3

  **Example**: `FILTER%SUB_DOMAIN_SIZE_MERIDIONAL=1`

## state
Controls the composition of the state vector

### STATE%O2
  Add molecular Oxygen mass fraction to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%O2=.true.`

### STATE%O1
  Add atomic Oxygen mass fraction to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%O1=.true.`

### STATE%HE
  Add atomic Helium mass fraction to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%HE=.true.`

### STATE%TN
  Add neutral temperature to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%TN=.true.`

### STATE%NE
  Add electron number density to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%NE=.true.`

### STATE%ZONAL_WIND
  Add zonal wind velocity to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%ZONAL_WIND=.true.`

### STATE%MERIDIONAL_WIND
  Add meridional wind velocity to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%MERIDIONAL_WIND=.true.`

### STATE%ATOMIC_OXYGEN_ION_DENSITY
  Add atomic oxygen ion number density to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%ATOMIC_OXYGEN_ION_DENSITY=.true.`

### STATE%MOLECULAR_OXYGEN_ION_DENSITY
  Add molecular oxygen ion number density to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%MOLECULAR_OXYGEN_ION_DENSITY=.true.`

### STATE%MERIDIONAL_WIND
  Add meridional wind velocity to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%MERIDIONAL_WIND=.true.`

### STATE%ATOMIC_ARGON
  Add mass fraction of atomic argon to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%ATOMIC_ARGON=.true.`

### STATE%NITRIC_OXIDE
  Add mass fraction of nitric oxide to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%NITRIC_OXIDE=.true.`

### STATE%EXCITED_ATOMIC_NITROGEN_4S
  Add mass fraction of excited Nitrogen in 4S atomic state to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%EXCITED_ATOMIC_NITROGEN_4S=.true.`

### STATE%EXCITED_ATOMIC_NITROGEN_2D
  Add mass fraction of excited Nitrogen in 2D atomic state to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%EXCITED_ATOMIC_NITROGEN_2D=.true.`

### STATE%ELECTRON_TEMPERATURE
  Add electron temperature to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%ELECTRON_TEMPERATURE=.true.`

### STATE%ION_TEMPERATURE
  Add ion temperature to the state vector

  **Type**: logical

  **Default**: `.false.`

  **Example**: `STATE%ION_TEMPERATURE=.true.`

## ensemble

### ENSEMBLE%ENSEMBLE_SIZE

  controls the ensemble size/number of ensemble members

  **Type**: integer

  **Default**: 0

  **Example**: `ENSEMBLE%ENSEMBLE_SIZE=96`

### ENSEMBLE%OVERWRITE_SOURCE

  If disabled, the initial state is initialized according to the TIEGCM input file. When enabled, the state of each member is initialized according to `ENSEMBLE%SOURCE_PATH` and `ENSEMBLE%SOURCE_NAME`.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `ENSEMBLE%OVERWRITE_SOURCE=.true.`

### ENSEMBLE%SOURCE_PATH

  Path to the directory containing a TIEGCM primary history file for each member. The files have to start with `ens_xxxx_`, where xxxx is the index of the ensemble member, padded with leading zeros. The files can be created by conducting an open-loop simulation. The assimilation system will then automatically generate the history files with the correct naming schema.

  **Type**: string

  **Default**: `""`

  **Example**: `ENSEMBLE%SOURCE_PATH=/path/to/the/primary/history/files/for/each/member`


### ENSEMBLE%SOURCE_NAME

  The constant part of the history file name after `ens_xxxx_`
  **Type**: string

  **Default**: `""`

  **Example**: `ENSEMBLE%SOURCE_NAME=init`

## observations

### OBSERVATION%SATELLITE()

This is for observations along a satellite's orbit. Data from multiple satellites can be assimilated simultaneously. Currently, only total mass densities can be assimilated.

#### OBSERVATION%SATELLITE()%APPLY
  assimilate this observation

  **Type**: logical

  **Default**: `.false.`

  **Example**: `OBSERVATION%SATELLITE(1)%APPLY=.true.`

#### OBSERVATION%SATELLITE()%ALWAYS_SAVE
  interpolate the model grid to the location of the observation and save it to the result file, even when it is not assimilated. Useful for open-loop simulations.

  **Type**: logical

  **Default**: `.false.`

  **Example**: `OBSERVATION%SATELLITE(1)%ALWAYS_SAVE=.true.`

#### OBSERVATION%SATELLITE()%FILE_FORMAT
  Format of the file containing the observations

  "igg" https://doi.pangaea.de/10.1594/PANGAEA.931347

  "toleos" http://thermosphere.tudelft.nl/page1.html

  "toleos_reduced" some toleos files store data with reduced accuracy

  **Type**: string

  **Default**: igg

  **Example**: `OBSERVATION%SATELLITE(1)%FILE_FORMAT="igg"`

#### OBSERVATION%SATELLITE()%FILE
  Path to the file containing the observations in the format specified in `OBSERVATION%SATELLITE()%FILE_FORMAT`.  Bash shell wildcards, e.g., `*` or `[]`, are supported and should be used if the data is distributed across multiple files.

  **Type**: string

  **Default**: igg

  **Example**: `OBSERVATION%SATELLITE(1)%FILE="/locatio/of/the/file"`

#### OBSERVATION%SATELLITE()%NAME
  name used to save the data in the result file.

  **Type**: string

  **Default**: igg

  **Example**: `OBSERVATION%SATELLITE(1)%FILE="satellitename"`

#### OBSERVATION%SATELLITE()%WEIGHT
  Currently, it is assumed that the uncertainty is 10% of the value itself. The standard deviation is divided by the weight factor.

  **Type**: real

  **Default**: 1.0

  **Example**: `OBSERVATION%SATELLITE(1)%WEIGHT=2.0`

#### OBSERVATION%SATELLITE()%WRITE_EVERY_SEC
  Determines how frequently data at the location of the observation is written. The duration in seconds is converted to the number of model steps.
  If negative, every time step is saved (not recommended).

  **Type**: integer

  **Default**: -1

  **Example**: `OBSERVATION%SATELLITE(1)%WRITE_EVERY_SEC=600`

#### OBSERVATION%SATELLITE()%FORCE_WRITE_ON_UPDATE
  Write every analysis regardless of writing frequency determined in `OBSERVATION%SATELLITE()%WRITE_EVERY_SEC`

  **Type**: logical

  **Default**: `.true.`

  **Example**: `OBSERVATION%SATELLITE(1)%FORCE_WRITE_ON_UPDATE=.false.`

## logger

### LOGGER%VERBOSE_LEVEL
  Controls how verbose the output is. Currently there are only two options 0 and 1.

  **Type**: integer

  **Default**: 0

  **Example**: `LOGGER%VERBOSE_LEVEL=0`
