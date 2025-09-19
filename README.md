This NCAR HAO TIE-GCM fork was created at the Institute for Geodesy and Geoinformation (University of Bonn) by the Group of Astronomical, Physical, and Mathematical Geodesy.

This fork includes modification to combine TIE-GCM 3.0 with the parallel data assimilation framework (PDAF).

To compile, set the required paths in `Make.<Host>` and run `make`. As an alternative you can try to compile with the help of the pyhton scripts in tiegcmrun.

Main modifications
* PDAF integration (must be enabled by using `-DUSEPDAF` preprocessor flag)
* using `mpi_f08`
* some additional consitency checks/limits
* some variables are no longer hard coded, so they can be perturbed
* alternative makefile
