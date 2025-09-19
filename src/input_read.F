      subroutine inp_read
! -----------------------------------------------------------------------------
! This file was modified for the integration of the Parallel Data Assimilation
! Framework (PDAF)
! Armin Corbin, University of Bonn, Institute for Geodesy and Geoinformation
!
! 06 NOV 2019: replaced MPI_COMM_WORLD with COMM_model
! 19 NOV 2021: use Fortran 2008 MPI interface
! 18 SEP 2025: merged with TIE-GCM 3.0
! -----------------------------------------------------------------------------
!
! Namelist read. 
!
! This assumes the model executable has been given the path to
!   the namelist input file via a single program argument, e.g.:
!   mpirun -np $nproc $model $input >&! $output
! The path to the input file is accessed with fortran intrinsic getarg, 
!   then broadcast to all tasks, which open the file on unit 10, do the 
!   namelist read, and close the unit.
! This subroutine is in a separate file, instead of in input.F, to avoid
!   circular dependencies.
!
      use input_module,only: tgcm_input
      use mpi_f08
      use mpi_module, only: TIEGCM_WORLD
      implicit none
      character(len=1024) :: inputfile,line
      integer :: ier,stat

      inputfile = ' '
      call getarg(1,inputfile)
      write(6,"(/,'Reading namelist input data from ',a)") 
     |  trim(inputfile)

      call mpi_bcast(inputfile,1024,MPI_CHARACTER,0,TIEGCM_WORLD,ier)

      open(10,file=trim(inputfile)) 
!
! Do the namelist read:
      read(10, nml=tgcm_input)
!
! Print namelist file to stdout:
      rewind(10)
      line = ' '
      do
        read(10,"(a)",iostat=stat) line 
        if (stat < 0) exit
        write(6,"(a)") trim(line)
      enddo
      close(10)
      write(6,"('Completed successful read of namelist inputs.',/)")
      end subroutine inp_read
