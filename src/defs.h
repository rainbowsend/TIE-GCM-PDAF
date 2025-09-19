!
! This software is part of the NCAR TIE-GCM.  Use is governed by the 
! Open Source Academic Research License Agreement contained in the file 
! tiegcmlicense.txt.
!
! Definitions of grid parameters for pre-processor.
! See parameters.h.
! -----------------------------------------------------------------------------
! This file was modified for the integration of the Parallel Data Assimilation
! Framework (PDAF)
! Armin Corbin, University of Bonn, Institute for Geodesy and Geoinformation
! 27 OCT 2021: control resolution via preprocessor LOWRES option
! 18 SEP 2025: merged with TIE-GCM 3.0
! -----------------------------------------------------------------------------
!
!------------------------------------
#ifdef LOWRES
! 5.0 degree horizontal:
#define DLAT 5.
#define DLON 5.
#define GLON1 -180
#define DLEV .5
#define ZIBOT -7
#define ZITOP 7
#define NRES_GRID 6
!
!------------------------------------
#else
! 2.5 degree horizontal:
#define DLAT 2.5
#define DLON 2.5
#define GLON1 -180
#define DLEV .25
#define ZIBOT -7
#define ZITOP 7
#define NRES_GRID 6
#endif
!------------------------------------

