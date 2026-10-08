# TIE-GCM PDAF

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="logo/logo-dark-mode.svg">
    <img src="logo/logo.svg" alt="TIE-GCM PDAF logo" width="350">
  </picture>
</p>

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23102802.svg)](https://doi.org/10.5281/zenodo.23102802) [![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://rainbowsend.github.io/TIE-GCM-PDAF/)

**An ensemble data assimilation system for the upper atmosphere (thermosphere and ionosphere).**
TIE-GCM PDAF combines the Thermosphere-Ionosphere-Electrodynamics General Circulation Model (TIE-GCM) with ensemble-based Kalman filters from the [Parallel Data Assimilation Framework (PDAF)](https://pdaf.awi.de/trac/wiki). It supports assimilation of satellite observations, such as accelerometer-derived mass densities; gridded observations (for example, from empirical models); and integrated observations such as VTEC. Adding new observation types to the existing code is straightforward.

This fork of NCAR HAO's TIE-GCM 3.0 was developed at the Institute for Geodesy and Geoinformation (University of Bonn) by the [Group of Astronomical, Physical, and Mathematical Geodesy (APMG)](https://www.igg.uni-bonn.de/apmg/de). This software is part of the NCAR TIE-GCM. Use is governed by the [Open Source Academic Research License
Agreement contained in the file tiegcmlicense.txt.](./LICENSE).

> [!Tip]
> If you just want to try TIE-GCM PDAF hands-on, see the [minimal working example](mwe/README.md) in `mwe/`.

> [!Tip]
> An example of the outputs created by TIE-GCM PDAF can be found at [bonndata](https://doi.org/10.60507/FK2/QMNFKG).

# Citation
When using this software, please cite
* this [fork](https://doi.org/10.5281/zenodo.23102802),
* the [PDAF Binding for TIE-GCM](https://doi.org/10.5281/zenodo.23103186),
* the [thesis describing the assimilation system](https://doi.org/10.48565/bonndoc-596),
* the [original TIE-GCM](https://doi.org/10.5281/zenodo.20076374),
* its [associated paper](https://doi.org/10.1029/2025JA034219),
* and [PDAF](https://doi.org/10.5281/zenodo.7861812).

# Main modifications
<details>
  <summary>"fully parallel" PDAF integration</summary>
  
  * enables parallel execution of multiple TIE-GCM instances and performing data assimilation via PDAF
  * must be enabled by using `-DUSEPDAF` preprocessor flag
  * some variables are no longer hard-coded, so they can be perturbed
 </details>  
<details>
  <summary>makefile</summary>
  
  * directly builds the PDAF model binding
  * modernized the [makefile](https://github.com/rainbowsend/tiegcm/blob/7fdd3c9c7f52504f6d4333303f87f37e7b499dba/makefile)
  * reads the configuration for each host from a different file
  * controlled by environment variables
</details>

<details>
<summary>new module `aerostatic_diag`</summary>
  
  * elemental functions for repeated calculations
  * modernized functions for mass density, geopotential- and geometric height calculation 
</details>

 <details>
  <summary>some additional consistency checks/limits</summary>
   
  * upper limit for neutral temperature
  https://github.com/rainbowsend/tiegcm/blob/7fdd3c9c7f52504f6d4333303f87f37e7b499dba/src/dt.F#L395
   
  * non-negative hall conductivities
  https://github.com/rainbowsend/tiegcm/blob/7fdd3c9c7f52504f6d4333303f87f37e7b499dba/src/lamdas.F#L312

  * non-negative ion densities
  https://github.com/rainbowsend/tiegcm/blob/7fdd3c9c7f52504f6d4333303f87f37e7b499dba/src/qinite.F#L95
  https://github.com/rainbowsend/tiegcm/blob/7fdd3c9c7f52504f6d4333303f87f37e7b499dba/src/qrj.F#L208

</details>  
<details>
  <summary>ETA is calculated and written to console</summary>

  ```
  Step       30 of     1440 mtime= 90  0 30  0 secs/step (sys) =  2.93 | passed time=   1.3 minutes ETA=   59.7 minutes
  ```
  
  https://github.com/rainbowsend/tiegcm/blob/7fdd3c9c7f52504f6d4333303f87f37e7b499dba/src/advance.F#L502-L508
 </details>  

# Installation

You need
* a compiler supporting Fortran 2018 features (e.g., GCC 11)
* an MPI implementation supporting mpi_f08 interface (e.g., openMPI 4.1.4)
* OpenMP
* a LAPACK implementation (e.g., OpenBLAS-0.3.20)
* NetCDF-fortran with nc4 support and parallel IO (requires HDF)

> [!Important]
> This software has been tested and developed with **gfortran** (gcc) only. Other compilers may fail to compile it.

> [!Note]
> The model error is represented by an ensemble of TIE-GCM 3.0 instances. All instances are computed in parallel. A typical ensemble size is 72, which accordingly requires 72 cores. To exploit the parallelization of the TIE-GCM, even more cores are required. For example, 288 cores would be required to compute 72 instances, each running on 4 cores.

## Install submodules

Pull dependencies, e.g., using `git submodule update --init`

### esmf
Follow the [installation instructions](https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/node10.html)

### pdaf
Follow the [installation instructions](https://pdaf.awi.de/trac/wiki/CompilingPdaf)

### geodetic-fortran-utilities

Follow the [installation instructions](https://github.com/rainbowsend/geodetic-fortran-utilities). The short version is

```bash
cd deps/geodetic-fortran-utilities/deps
./get_deps.sh
cd ..
make
```
### pdaf-binding-tiegcm
[pdaf-binding-tiegcm](https://github.com/rainbowsend/pdaf-binding-tiegcm/) contains the source code for integrating PDAF into TIE-GCM. The Makefile of TIE-GCM PDAF builds the source code provided in pdaf-binding-tiegcm. Thus, this submodule does not require installation.


## Install TIE-GCM
Change to the root directory of this repository.

First, you need to set the correct paths in `Make.hostname`. `hostname` is the name of the computer where you compile the program. Use the file `Make.gfortran` as a template.

> [!NOTE]
> When using PDAF >= 3.1, TIE-GCM PDAF has to be compiled with `-fopenmp` flag

### makefile options
The make process is controlled by a few environment variables
| variable  | default      | description                                               |
| --------- | ------------ | ----------------------------------------------------------|
| WITH_PDAF | TRUE         | if true compile TIE-GCM with PDAF coupling                |
| EXE_NAME  | tiegcm-pdaf  | controls the name of the executable                       |
| BUILD_DIR | build        | controls the location of build directory                  |
| HIGH_RES  | FALSE        | If true use 2.5° instead of 5.0° horizontal resolution    |
| ALT_EXT   | FALSE        | if true use altitude extension                            |

Try first to install TIE-GCM without PDAF binding and using the lowest resolution
```
WITH_PDAF=FALSE EXE_NAME=tiegcm5.0 BUILD_DIR=build/tiegcm5.0 HIGH_RES=FALSE make
```

> [!TIP]
> You can speed up the execution of `make` using the `-j` option, enabling parallel compilation. For example, `make -j 8` will compile up to 8 files in parallel.

If no error occurs, install TIE-GCM with PDAF binding

```
WITH_PDAF=TRUE EXE_NAME=tiegcm5.0-pdaf BUILD_DIR=build/tiegcm5.0-pdaf HIGH_RES=FALSE make
```
# Data

> [!TIP]
> The minimal working example (`mwe`) works without downloading any additional data

## Data required by TIE-GCM
First, you need to gather all the data required to run the TIE-GCM. Currently, the data is available at [globus](https://app.globus.org/file-manager?origin_id=b2502c58-c3eb-470f-86d4-cbdcd0aeb6c8&origin_path=%2F) (see also https://github.com/NCAR/tiegcm/issues/54).

It is recommended to download at least
* a gpi file (containing geophysical indices)
* the Helium coefficients file
* GSWM files
* For a 'Weimer' run, you need IMF and Weimer coefficient files in addition

## Data required for assimilation runs
For open-loop and assimilation runs, further data is required.

### Perturbations
The perturbation file is a netCDF file that contains, for each ensemble member, the perturbation to all model inputs that should be perturbed.

<details>
  <summary>Exemplary structure of perturbation file</summary>
  
``` bash
netcdf file:perturbations_2026a_2024.nc {
    dimensions:
    bin = 37;
    lev = 29;
    n_igrf_coeff = 195;
    timeinvariant = 1;
    ensemble = 192;
    time = 8783;
    time_f107 = 365;
    time_co2u = 9;
  variables:
    double time(time=8783);
      :units = "seconds since 2024-01-01 00:00:00";

    double time_f107(time_f107=365);
      :units = "seconds since 2024-01-01 00:00:00";

    double time_co2u(time_co2u=9);
      :units = "seconds since 2024-01-01 00:00:00";

  group: perturbations {
    variables:
      double tlbc(timeinvariant=1, ensemble=192);
        :units = "Kelvin";

      double zlbc(timeinvariant=1, ensemble=192);
        :units = "cm";

      double ulbc(timeinvariant=1, ensemble=192);
        :units = "cm/s";

      double vlbc(timeinvariant=1, ensemble=192);
        :units = "cm/s";

      double gswm_delay(timeinvariant=1, ensemble=192);
        :units = "s";

      double alfac(timeinvariant=1, ensemble=192);
        :units = "keV";

      double alfad(timeinvariant=1, ensemble=192);
        :units = "keV";

      double colfac(timeinvariant=1, ensemble=192);
        :units = "";

      double joulefac(timeinvariant=1, ensemble=192);
        :units = "";

      double igrf_sh(timeinvariant=1, ensemble=192, n_igrf_coeff=195);
        :units = "nT";

      double co2u(time_co2u=9, ensemble=192);
        :units = "ppm";

      double swvel(time=8783, ensemble=192);
        :units = "km s-1";

      double swden(time=8783, ensemble=192);
        :units = "cm-3";

      double f107(time_f107=365, ensemble=192);
        :units = "sfu";

      double imfby(time=8783, ensemble=192);
        :units = "nT";

      double imfbz(time=8783, ensemble=192);
        :units = "nT";

      double imfbx(time=8783, ensemble=192);
        :units = "nT";

    // group attributes:
    :description = "ensemble of model input perturbations";
  }

  group: members {
    variables:
      double alfac(timeinvariant=1, ensemble=192);
        :units = "keV";

      double alfad(timeinvariant=1, ensemble=192);
        :units = "keV";

      double colfac(timeinvariant=1, ensemble=192);
        :units = "";

      double joulefac(timeinvariant=1, ensemble=192);
        :units = "";

      double co2u(time_co2u=9, ensemble=192);
        :units = "ppm";

      double swvel(time=8783, ensemble=192);
        :units = "km s-1";

      double swden(time=8783, ensemble=192);
        :units = "cm-3";

      double f107(time_f107=365, ensemble=192);
        :units = "sfu";

      double imfby(time=8783, ensemble=192);
        :units = "nT";

      double imfbz(time=8783, ensemble=192);
        :units = "nT";

      double imfbx(time=8783, ensemble=192);
        :units = "nT";

    // group attributes:
    :description = "ensemble of model inputs with applied perturbations";
  }

  group: mean {
    variables:
      double alfac(timeinvariant=1);
        :units = "keV";

      double alfad(timeinvariant=1);
        :units = "keV";

      double colfac(timeinvariant=1);
        :units = "";

      double joulefac(timeinvariant=1);
        :units = "";

      double co2u(time_co2u=9);
        :units = "ppm";

      double swvel(time=8783);
        :units = "km s-1";

      double swden(time=8783);
        :units = "cm-3";

      double f107(time_f107=365);
        :units = "sfu";

      double imfby(time=8783);
        :units = "nT";

      double imfbz(time=8783);
        :units = "nT";

      double imfbx(time=8783);
        :units = "nT";

    // group attributes:
    :description = "mean value of ensemble of model input perturbations";
  }

  group: std {
    variables:
      double alfac(timeinvariant=1);
        :units = "keV";

      double alfad(timeinvariant=1);
        :units = "keV";

      double colfac(timeinvariant=1);
        :units = "";

      double joulefac(timeinvariant=1);
        :units = "";

      double co2u(time_co2u=9);
        :units = "ppm";

      double swvel(time=8783);
        :units = "km s-1";

      double swden(time=8783);
        :units = "cm-3";

      double f107(time_f107=365);
        :units = "sfu";

      double imfby(time=8783);
        :units = "nT";

      double imfbz(time=8783);
        :units = "nT";

      double imfbx(time=8783);
        :units = "nT";

    // group attributes:
    :description = "standard deviation of the ensemble of model input perturbations";
  }
}
```

</details>  

* A toy perturbation file is included in this repository in `mwe`
* An example of a perturbation file used for productive runs is provided at https://doi.org/10.60507/FK2/QMNFKG (`perturbations_2026a_2024.nc`).

### Observations

* Mass density from [TOLEOS](https://thermosphere.tudelft.nl/index.html) project
* Mass density from [TND-IGG RL01](https://doi.pangaea.de/10.1594/PANGAEA.931347)
* Mass density from [ITSG](https://ftp.tugraz.at/pub/ITSG/satelliteOrbitProducts/operational/GRACEFO-1/neutralDensity/)

# Running

The executable takes two positional arguments: the [namelist file](https://www.hao.ucar.edu/modeling/tgcm/tiegcm2.0/userguide/html/namelist.html#example-namelist-input-files) containing the TIE-GCM configuration and the namelist file containing the assimilation system configuration (explained below in section [Configuration](#configuration)).

To execute the assimilation system, use

```
mpirun -np ${npes} bin/tiegcm5.0-pdaf ${tiegcm_nml} ${pdaf_nml}
```
with

*  the number of physical cores `${npes}`, 
*  the path to the TIE-GCM namelist file `${tiegcm_nml}`,
*  and the path to the assimilation system namelist file `${pdaf_nml}`

> [!Tip]
> Use the mpirun option `--output-filename ./out --merge-stderr-to-stdout` to write the output of each rank into a different file. This makes reading the log much easier.

> [!Note]
> At 2.5-deg resolution, it is not recommended to use more than 8 cores per model instance, as the speed-up is low above this number.

# Configuration

TIE-GCM settings are controlled by a [namelist file](https://www.hao.ucar.edu/modeling/tgcm/tiegcm2.0/userguide/html/namelist.html#example-namelist-input-files). The path to this file is the first argument to the executable. When using TIE-GCM PDAF, the executable takes a second argument: the path to another namelist file that controls the assimilation setup. All namelist parameters of the assimilation system are documented on the [configuration page](https://rainbowsend.github.io/TIE-GCM-PDAF/configuration.html).
