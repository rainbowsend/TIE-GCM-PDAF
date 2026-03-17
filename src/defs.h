!
! This software is part of the NCAR TIE-GCM.  Use is governed by the 
! Open Source Academic Research License Agreement contained in the file 
! tiegcmlicense.txt.
!
! Definitions of grid parameters for pre-processor.
! See parameters.h.
! magentic field resolutionis set by NRES_GRID: 5-> 2 deg, 6 -> 1 deg, 7 -> 0.5 deg
! -----------------------------------------------------------------------------
! This file was modified for the integration of the Parallel Data Assimilation
! Framework (PDAF)
! Armin Corbin, University of Bonn, Institute for Geodesy and Geoinformation
! 27 OCT 2021: control resolution via preprocessor LOWRES option
! 18 SEP 2025: merged with TIE-GCM 3.0
! 17 MAR 2026: option for altitude extension
! -----------------------------------------------------------------------------
!
!------------------------------------
#ifdef HIGH_RES
! 2.5 degree horizontal:
#define DLAT 2.5
#define DLON 2.5
#define GLON1 -180
#define DLEV .25
#define ZIBOT -7
#define NRES_GRID 5
#else
!
!------------------------------------
! 5.0 degree horizontal:
#define DLAT 5.
#define DLON 5.
#define GLON1 -180
#define DLEV .5
#define ZIBOT -7
#define NRES_GRID 5
#endif
!------------------------------------

#ifdef ALT_EXT
#define ZITOP 11
#else
#define ZITOP 7
#endif
