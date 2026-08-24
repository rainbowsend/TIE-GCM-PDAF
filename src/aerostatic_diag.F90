!
! This software is part of the NCAR TIE-GCM.  Use is governed by the
! Open Source Academic Research License Agreement contained in the file
! tiegcmlicense.txt.
!
! -----------------------------------------------------------------------------
! This file was added for the integration of the Parallel Data Assimilation
! Framework (PDAF)
! Armin Corbin, University of Bonn, Institute for Geodesy and Geoinformation
!
! 24 AUG 2026: initial version, ported from addiag.F and dt.F
! -----------------------------------------------------------------------------
!
! Defines elemental function for frequently used neutral gas calculations.
! Computes diagnostic fields (geopotential/geometric height, pressure, neutral density) from TIE-GCM state, ported from addiag/dt.F.

module aerostatic_diag

implicit none

contains

elemental function molecular_nitrogen(o2,o1,he) result (n2)

  implicit none

  ! input arguments
  real, intent(in) :: &
      o2, &! mass fraction molecular molecular oxygen ()
      o1, &! mass fraction molecular atomic oxygen ()
      he   ! mass fraction molecular helium ()

  real :: n2  ! mass fraction molecular nitrogen ()

  n2 = 1.0-o1-o2-he;

end function molecular_nitrogen

elemental function mean_molar_mass(o2,o1,he,n2) result(barm)

  ! tie-gcm
  use cons_module, only: rmassinv_o2, rmassinv_o1, rmassinv_he, rmassinv_n2

  implicit none

  ! input arguments
  real, intent(in) :: &
      o2, &! mass fraction molecular molecular oxygen ()
      o1, &! mass fraction molecular atomic oxygen ()
      he, &! mass fraction molecular helium ()
      n2   ! mass fraction molecular nitrogen ()

  ! result
  real:: barm ! mean molar Mass  \bar{M} (g/mol)

  ! compute mean molecular weight
  barm = 1./ (o2*rmassinv_o2+o1*rmassinv_o1+he*rmassinv_he+n2*rmassinv_n2)

end function mean_molar_mass

elemental function pressure_scale_height(neutral_temperature,mean_molecular_mass,g) result(H)

  ! if g is provided in cm s-2 H has units cm, If g is provided in m s-2 H has units m.

  ! tie-gcm
  use cons_module, only: gask

  implicit none

  ! input arguments
  real, intent(in) :: &
      neutral_temperature, & ! temperature of neutral gas (K)
      mean_molecular_mass, & ! mean molar/molecular mass of the neutral gas (g/mol)
      g ! gravitaional acceleration (cm/s^2 in this codebase, see note above)

  ! result
  real:: H ! pressure scale height (cm in this codebase, see note above)

  H = gask*neutral_temperature/(mean_molecular_mass*g)

end function pressure_scale_height

elemental function neutral_mass_density(pressure,mean_molecular_mass,neutral_temperature) result(mass_density)
  ! computes neutral mass density under the assumption of aerostaic equilibrium and ideal gas
  ! rho = P * M/ (R * T)

  ! tie-gcm
  use cons_module, only: gask

  implicit none

  ! input arguments
  real,intent(in) ::pressure, mean_molecular_mass, neutral_temperature

  ! result
  real :: mass_density ! neutral density (g/cm3)

  mass_density = pressure * mean_molecular_mass / (gask*neutral_temperature)

end function

elemental function pressure_mid(k) result(P_mid)
  ! pressure at midpoint level k: p(k) = p0*exp(-lev(k))

  ! tie-gcm
  use cons_module, only: expz, p0
  use fields_module, only: levd1
  use params_module, only: dlev

  implicit none

  ! input arguments
  integer,intent(in) :: k ! midpoint level index

  ! result
  real :: P_mid ! pressure (microbars)

  if (k == levd1) then
    ! expz(levd1) is zero, so it must be computed manually here
    P_mid = p0*expz(k-1)*exp(-dlev)
  else
    P_mid = p0*expz(k)
  end if

end function pressure_mid

elemental function pressure_int(k) result(P_int)
  ! pressure at interface level k, i.e. pressure_mid(k) transformed from
  ! midpoints to interfaces via expzmid_inv

  ! tie-gcm
  use cons_module, only: expzmid_inv

  implicit none

  ! input arguments
  integer,intent(in) :: k ! interface level index

  ! result
  real :: P_int ! pressure (microbars)

  P_int = pressure_mid(k)*expzmid_inv

end function pressure_int

!> Computes optional diagnostics (geometric/geopotential height, neutral density, pressure-conversion factor) from TIE-GCM temperature and major species mass fractions.
!!
!! Only requested (present) output arguments are computed. Bounds correspond to TIE-GCM field
!! bounds; lev0 must always be the lower TIE-GCM level, and lon/lat may be a subdomain.
subroutine calc_diag(lon0,lon1,lev0,lev1,lat0,lat1,tn,o2,o1,he,zg,rho,rhomid,xnmbar)

  ! tie-gcm
  use cons_module, only: boltz, expz, p0

  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1

  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      tn, &! neutral temperature (deg K)
      o2, &! molecular oxygen (mmr)
      o1, &! atomic oxygen (mmr)
      he   ! helium (mmr)
           !!! all inputs are on MIDPOINTS !!!

  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),&
  intent(out), optional :: zg, &   ! geometric height (cm) at interfaces
                           rho, & ! neutral density g/cm³ at interfaces
                           rhomid, & ! neutral density g/cm³ at midpoints
                           xnmbar ! conversion factor mmr to 1/cm³

  ! local
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1) :: n2, & ! mass fraction molecular nitrogen () on midpoints
                                                   barm  ! mean molecular weight (g/mol) on midpoints

  ! not required for all calls, thus only allocated when necessary
  real,dimension(:,:,:),allocatable :: z, & ! geopotential height on interface (cm)
                                       barm_filtered ! gauss filter applied to mean molecular mass

  integer :: k

  ! compute mass fraction of molecular nitrogen on midpoints
  n2 = molecular_nitrogen(o2,o1,he)

  ! compute mean molar mass on midpoints
  barm = mean_molar_mass(o2,o1,he,n2)

  ! TODO this is adopted from TIE-GCM. But was their intention really applying a gauss filter?
  if( present( zg ) .or.  present( xnmbar ) ) then
    allocate( barm_filtered(lev0:lev1,lon0:lon1,lat0:lat1) )
    call apply_gauss_kernel(lon0,lon1,lev0,lev1,lat0,lat1, barm, barm_filtered)
  else
    ! allocate with size zero (to prevent compiler warning and possible annoying errors)
    allocate(barm_filtered(0,0,0))
  end if

  if( present( zg ) ) then
    allocate( z(lev0:lev1,lon0:lon1,lat0:lat1) ) ! on interfaces

    call calc_geopotential_height(lon0,lon1,lev0,lev1,lat0,lat1,&
                                      tn,barm_filtered,z)

    call calc_geometric_height(lon0,lon1,lev0,lev1,lat0,lat1,&
                                      tn,barm,z,zg)
  end if

  if( present( rho ) ) then
    call calc_neutral_density(lon0,lon1,lev0,lev1,lat0,lat1, &
                                      tn,barm,rho)
  end if

  if( present( rhomid ) ) then
     call calc_neutral_density_mid(lon0,lon1,lev0,lev1,lat0,lat1, &
                                      tn,barm,rhomid)
  end if

  if( present( xnmbar ) ) then
    ! same as in settei.F line 405
    do k=lev0, lev1
      xnmbar(k,:,:) = p0*expz(k)*barm_filtered(k,:,:) / (boltz*tn(k,:,:))
    end do
  end if

  if (allocated (barm_filtered)) deallocate(barm_filtered)
  if (allocated (z)) deallocate(z)

end subroutine

!> Integrates geopotential height from the lower boundary upward using neutral temperature and mean molar mass (implementation follows TIE-GCM's addiag.F).
subroutine calc_geopotential_height(lon0,lon1,lev0,lev1,lat0,lat1,&
                                    tn,barm,z)

  ! tie-gcm
  use cons_module,&
      only: dz, &
            dzgrav ! grav/gask
  use fields_module,&
      only: lond0, lond1, latd0, latd1
  use lbc,&
      only: z_lbc

  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      tn, &! neutral temperature (deg K) at midpoints
      barm ! mean molar mass (g/mol)     at midpoints
  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out):: z ! geopotential height (cm) at interfaces

  ! local
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1) ::  w ! (cm)

  ! z_lbc is not distributed (all ranks have all values) and has size (nlonp4,nlat)
  ! z_lbc_ghost has the same shape as in field module
  real :: z_lbc_ghost(lond0:lond1,latd0:latd1)

  integer :: k;

  !
  ! Z(k) = R/g0 integral T/M dk
  !

  ! this integral is solved using Trapezoidal rule
  ! The surface area of a single trapez is
  ! T = (b-a) (f(a)+f(b))/2
  !
  ! (f(a)+f(b))/2 correspond to the value at mipoints
  ! Thus tn and barm must be located on midpoints

  z_lbc_ghost = 0.0
  z_lbc_ghost(lond0+2:lond1-2,latd0+2:latd1-2) = z_lbc(lond0+2:lond1-2,latd0+2:latd1-2)

  z(lev0,:,:) = z_lbc_ghost(lon0:lon1,lat0:lat1)
  w = (dz/dzgrav) * tn/barm

  do k=lev0, lev1-1
    z(k+1,:,:) = z(k,:,:) + w(k,:,:)
  end do

end subroutine calc_geopotential_height

!> Converts geopotential height z (constant gravity) to geometric height zg, accounting for
!! the latitude/altitude dependence of gravity (ported from calczg in addiag.F)
!! optionally, also Returns pressure scale height
subroutine calc_geometric_height(lon0,lon1,lev0,lev1,lat0,lat1,tn,barm,z,zg,H)

  ! tie-gcm
  use fields_module,&
      only: latd0,latd1
  use params_module,&
      only: dz,glat

  implicit none
  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      tn, &! neutral temperature (deg K)
      barm, & ! mean molar mass (g/mol)
      z ! geopotential height

  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out):: zg
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out),optional:: &
      H ! pressure scale height (cm), using the same position-dependent
        ! effective gravity g as zg

  ! local

  real,parameter :: dgtr=0.017453292519943295

  real, dimension(lon0:lon1,lat0:lat1):: c2
  real, dimension(lon0:lon1,lat0:lat1):: g0
  real, dimension(lon0:lon1,lat0:lat1):: r0

  real, dimension(lon0:lon1,lat0:lat1):: H_lev


  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1) :: g

  real, dimension(latd0:latd1) :: glat_ghost

  integer :: nlon
  integer :: k

  zg=0.0

  ! glat is not distributed (all values are on all tasks)
  ! glat ghost has same dimension as fields
  glat_ghost = 0
  glat_ghost(latd0+2:latd1-2)=glat(latd0+2:latd1-2)

  nlon = lon1-lon0+1

  c2 = transpose(spread( cos(2.*dgtr*glat_ghost(lat0:lat1)), 2,nlon))
  g0 = 980.616*(1.-.0026373*c2)
  r0 = 2.*g0/(3.085462e-6 + 2.27e-9*c2) ! effective earth radius

  ! g(z) = g0*(r0/(g0+z))**2

  ! integral is solved using Trapezoidal rule
  ! Thus z is interpolated to mid points

  g(lev0,:,:) = g0*(r0/(r0+0.5*(z(lev0,:,:)+z(lev0+1,:,:))))**2

  zg(lev0,:,:) = z(lev0,:,:)

  H_lev = pressure_scale_height(tn(lev0,:,:), barm(lev0,:,:), g(lev0,:,:))
  if (present(H)) H(lev0,:,:) = H_lev

  ! same as in calc_geopotential_height but with variable gravitaional acceleration
  ! Z = R integral  T/(M g) dz
  do k = lev0+1,lev1-1
    zg(k,:,:) = zg(k-1,:,:) + dz * H_lev
    g(k,:,:) = g0*(r0/(r0+0.5*(zg(k,:,:)+z(k+1,:,:))))**2
    H_lev = pressure_scale_height(tn(k,:,:), barm(k,:,:), g(k,:,:))
    if (present(H)) H(k,:,:) = H_lev
  end do

  ! interpolate upper level
  zg(lev1,:,:) = 2.0*zg(lev1-1,:,:)-zg(lev1-2,:,:)
  if (present(H)) H(lev1,:,:) = 2.0*H(lev1-1,:,:)-H(lev1-2,:,:)

end subroutine calc_geometric_height

!> Computes neutral mass density at interface levels from temperature, molar mass, and pressure (ported from TIE-GCM's dt.F).
subroutine calc_neutral_density(lon0,lon1,lev0,lev1,lat0,lat1,&
                                    tn,barm,rho)

  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      tn, & ! neutral temperature at midpoints (deg K)
      barm ! mean molar mass (g/mol)
  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out):: rho ! neutral density (g/cm3)

  ! local
  integer :: k
  real :: pressure(lev0:lev1) ! pressure at interface level
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1) :: barmi, &
                                                   tni ! tn at interface (K)

  ! interpolate mean molecular weight to interface
  barmi = mid_to_int(lon0,lon1,lev0,lev1,lat0,lat1,&
                     barm)

  ! interpolate temperature to interface
  tni = calc_neutral_temperature_at_interface(lon0,lon1,lev0,lev1,lat0,lat1,tn)

  call calc_pressure(lev0,lev1,P_int=pressure)

  do k=lev0, lev1
    rho(k,:,:) = neutral_mass_density(pressure(k), barmi(k,:,:), tni(k,:,:))
  end do

end subroutine calc_neutral_density

!> Computes neutral mass density at midpoint levels from temperature, molar mass, and pressure.
subroutine calc_neutral_density_mid(lon0,lon1,lev0,lev1,lat0,lat1,&
                                    tn,barm,rho)

  ! tie-gcm
  use cons_module, only: gask
  use params_module, only: spval

  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      tn, & ! neutral temperature at midpoints (deg K)
      barm ! mean molar mass (g/mol)

  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out):: rho ! neutral density (g/cm3)

  ! local
  integer :: k
  real :: pressure(lev0:lev1) ! pressure at midpoints level

  call calc_pressure(lev0,lev1,P_mid=pressure)

  do k=lev0, lev1
    ! on halo cells tn is sometimes zero. To avoid invalid operations
    ! only calculate for cells where tn>0. This allows us to use
    ! -ffpe-trap=invalid,zero,overflow compile flags, without stopping here
    where(tn(k,:,:)>0)
      rho(k,:,:) = neutral_mass_density(pressure(k), barm(k,:,:), tn(k,:,:))
    else where
      rho(k,:,:) = spval
    end where
  end do

end subroutine calc_neutral_density_mid

!> Computes the hydrostatic pressure profile at midpoint and/or interface levels from the reference pressure p0.
subroutine calc_pressure(lev0,lev1,P_mid,P_int)

  implicit none

  ! input arguments
  integer,intent(in) :: lev0,lev1

  ! output arguments
  real,dimension(lev0:lev1),intent(out), optional:: P_mid, P_int ! pressure (microbars)

  ! local
  integer :: k
  integer,dimension(lev0:lev1) :: klev

  klev = [(k, k=lev0,lev1)]

  if( present(P_mid)) then
    P_mid = pressure_mid(klev)
  end if

  if(present(P_int)) then
    P_int = pressure_int(klev)
  end if

end subroutine

!> Broadcasts the 1D pressure profile from calc_pressure over the full lon/lat domain.
subroutine calc_pressure_mat(lon0,lon1,lev0,lev1,lat0,lat1,P_mid,P_int)

  implicit none

  ! arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out), optional :: P_mid, P_int

  ! local
  real,dimension(lev0:lev1) :: P_profile_mid, P_profile_int

  call calc_pressure(lev0,lev1,P_profile_mid, P_profile_int)

  if(present(P_mid)) then
    P_mid = spread(  spread(P_profile_mid,2,(lon1-lon0)+1),  3,(lat1-lat0)+1)
  end if

  if(present(P_int)) then
    P_int = spread(  spread(P_profile_int,2,(lon1-lon0)+1),  3,(lat1-lat0)+1)
  end if

end subroutine

!> Interpolates neutral temperature from midpoints to interface levels, using the lower boundary condition at the bottom.
function calc_neutral_temperature_at_interface(lon0,lon1,lev0,lev1,lat0,lat1,tn) result(tni)

  ! tie-gcm
  use fields_module,only: tlbc ! Lower boundary conditions (bottom interface level) for t

  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: tn ! neutral temperature at midpoints (deg K)

  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1) :: tni ! neutral temperature at interfaces (deg K)

  ! local
  integer :: k

  ! interpolate temperature to interface
  do k=lev0+1,lev1-1
    tni(k,:,:) = .5*( tn(k,:,:)+tn(k-1,:,:) )
  enddo
  tni(lev0,:,:) = tlbc(lon0:lon1,lat0:lat1)
  tni(lev1,:,:) = tn(lev1-1,:,:)

end function calc_neutral_temperature_at_interface

!> Interpolates a field from midpoint levels to interface levels.
function mid_to_int(lon0,lon1,lev0,lev1,lat0,lat1,on_mid) result(on_int)
  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      on_mid ! field on midpoints
  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1):: on_int ! field on interface

  ! local
  integer :: k

  on_int(lev0,:,:) =  1.5*on_mid(lev0,:,:)-0.5*on_mid(lev0+1,:,:)
  do k=lev0+1, lev1
    on_int(k,:,:) = 0.5*( on_mid(k,:,:)+on_mid(k-1,:,:) )
  end do

end function

!> Interpolates a field from interface levels to midpoint levels.
function int_to_mid(lon0,lon1,lev0,lev1,lat0,lat1,on_int) result(on_mid)
  implicit none

  ! input arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: &
      on_int ! field on interface
  ! output arguments
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1):: on_mid ! field on midpoints

  ! local
  integer :: k

  ! interpolation as in mkdiag_ZGMID in diags.F
  do k=lev0,lev1-1
        on_mid(k,:,:) = 0.5*(on_int(k,:,:)+on_int(k+1,:,:))
  end do
  on_mid(lev1,:,:) = 2.0*on_mid(lev1-1,:,:)-on_mid(lev1-2,:,:)
end function int_to_mid

!> Applies a 3-point Gaussian smoothing kernel along the vertical level dimension, leaving boundary levels unchanged.
subroutine apply_gauss_kernel(lon0,lon1,lev0,lev1,lat0,lat1,&
                              field,field_filterd)
  implicit none

  ! arguments
  integer,intent(in) :: lon0,lon1,lev0,lev1,lat0,lat1
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(in):: field
  real,dimension(lev0:lev1,lon0:lon1,lat0:lat1),intent(out):: field_filterd

  ! local
  integer :: k

  do k=lev0+1, lev1-1
    field_filterd(k,:,:) = (field(k-1,:,:) + 2*field(k,:,:) + field(k+1,:,:))/4
  end do

  ! to be consistnet with tiegcm code the lower level does not change
  field_filterd(lev0,:,:) = field(lev0,:,:)
  field_filterd(lev1,:,:) = field(lev1,:,:)

end subroutine apply_gauss_kernel

end module
