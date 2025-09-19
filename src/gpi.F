!
      module gpi_module
!
! This software is part of the NCAR TIE-GCM.  Use is governed by the 
! Open Source Academic Research License Agreement contained in the file 
! tiegcmlicense.txt.
!
! -----------------------------------------------------------------------------
! This file was modified for the integration of the Parallel Data Assimilation
! Framework (PDAF)
! Armin Corbin, University of Bonn, Institute for Geodesy and Geoinformation
!
!   28 OCT 2019: dynamic allocation of gpi fields
!   29 OCT 2019: kp ncvars are read from namelist. It is possible to use
!                hp30, hp60 and hp90 instead of kp
!   20 MAR 2020: enabled perturbation of f107
!   13 JAN 2021: enabled perturbation of ctpoten and hemispheric power
!   07 JUL 2023: commented routines that are not called by model
!   18 SEP 2025: merged with TIE-GCM 3.0
! -----------------------------------------------------------------------------
!
! Module to use NGDC data for geophysical indices f107, f107a, 
!   power, and/or ctpoten. These 4 variables are optionally provided
!   by the user at input. Any of these that are NOT provided by
!   the user are calculated here from the gpi data file at each 
!   model time step.
!
! The data file used (GPI_NCFILE) is a netcdf file, made from
!   NGDC ascii data obtained from the web. The default path to this 
!   file is gpi_ncfiledef (see input). The user may optionally 
!   override the default be providing their own GPI_NCFILE at input. 
!
! The source of the original NGDC ascii data is:
!   ftp://ftp.ngdc.noaa.gov/STP/GEOMAGNETIC_DATA/INDICES/KP_AP/
!   The netcdf file is made from the NGDC ascii data by a separate
!   program, using subs mkncgpi, wrncgpi, idate2iyd, and ichdate
!   (see ~foster/tgcminp/nc_gpi). These subs are included below for 
!    documentation only -- they are NOT called by the model. 
!
! The solar fluxes f107 and f107a are interpolated to the current
!   model time at each time step using gpi from 2 days previous and
!   2 days following the current day. Hemispheric power (power), and 
!   cross-tail potential (ctpoten) are calculated from the gpi
!   3-hourly kp(8). First, fkp = interpolation of 3-hourly kp to
!   current model time (using previous and next days), then:
!   power = max(3.,-2.78+9.33*fkp)
!   ctpoten = 29.+11.*fkp
!
      implicit none
!
#include <netcdf.inc>
! 
! Global gpi data read from gpi data file:
      integer :: 
     |  ngpidays,             ! number of days of gpi data
     |  ngpikp,               ! number of kp intervals per day of gpi data
     |  iyd_beg,iyd_end       ! beginning and ending year-dates on gpi 
                              ! data file

      integer, dimension(:), allocatable ::
     |  gpi_iyd               ! yearday (7-digit) of gpi data

      real, dimension(:), allocatable ::
     |  gpi_f107d,            ! daily 10.7 cm flux
     |  gpi_f107a             ! 81-day average 10.7 cm flux
     
      real, dimension(:,:), allocatable ::
     |  gpi_kp                ! kp index or kp-like index e.g. HP-index

      real :: fkp             ! kp from gpi file, interpolated to model time
!
      contains
!-----------------------------------------------------------------------
      subroutine deallocate_gpi_module
        write(6,"('RDGPI: deallocate_gpi_module')")
        if (allocated (gpi_kp)) deallocate (gpi_kp)
        if (allocated (gpi_iyd)) deallocate (gpi_iyd)
        if (allocated (gpi_f107d)) deallocate (gpi_f107d)
        if (allocated (gpi_f107a)) deallocate (gpi_f107a)
      end subroutine deallocate_gpi_module
!-----------------------------------------------------------------------
      subroutine rdgpi
!
! Obtain and read gpi_ncfile netcdf data file containing f107d, f107a, 
! and kp. These data are obtained in ascii format from NGDC. See comments 
! below.  If mpi job, only the master task executes this routine.
!
      use input_module,only: gpi_ncfile,mxlen_filename,gpi_ncfile_kp_var
      use nchist_module,only: handle_ncerr
!
! Local:
      character(len=mxlen_filename) :: dskfile
      integer :: istat,ncid,nkp,i
      integer :: id_ndays,id_nkp,idv_iyd,idv_f107d,idv_f107a,idv_kp
!
! Acquire mss file:
      dskfile = ' '
      call getfile(gpi_ncfile,dskfile)
!
      write(6,"(/,72('-'))")
      write(6,"('RDGPI: read GPI data file:')")
!
! Open netcdf file:
      istat = nf_open(dskfile,NF_NOWRITE,ncid)
      if (istat /= NF_NOERR) then
        write(6,"(/,'>>> rdgpi: error opening netcdf gpi file ',
     |    a)") trim(dskfile)
        call shutdown('rdgpi')
      endif
!
! Get ndays dimension:
      istat = nf_inq_dimid(ncid,'ndays',id_ndays)
      istat = nf_inq_dimlen(ncid,id_ndays,ngpidays)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting ndays dimension')

!
! Get kp dimension (nkp should be 8 for 3-hourly kp):

      istat = nf_inq_dimid(ncid,'n'//trim(gpi_ncfile_kp_var),id_nkp)
      istat = nf_inq_dimlen(ncid,id_nkp,ngpikp)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting nkp dimension')

     
      allocate(gpi_iyd(ngpidays))
      allocate(gpi_f107d(ngpidays))
      allocate(gpi_f107a(ngpidays))
     
!
! Get gpi_iyd:
      istat = nf_inq_varid(ncid,'year_day',idv_iyd)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting f107d var year_day')
      istat = nf_get_var_int(ncid,idv_iyd,gpi_iyd)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting variable year_day')
!
! Get f107d:
      istat = nf_inq_varid(ncid,'f107d',idv_f107d)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting f107d var id')
      istat = nf_get_var_double(ncid,idv_f107d,gpi_f107d)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting variable f107d')
!     write(6,"('rdgpi: f107d=',/(8f8.2))") (gpi_f107d(i),i=1,ngpidays)
!
! Get f107a:
      istat = nf_inq_varid(ncid,'f107a',idv_f107a)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting f107a var id')
      istat = nf_get_var_double(ncid,idv_f107a,gpi_f107a)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting variable f107a')
!     write(6,"('rdgpi: f107a=',/(8f8.2))") (gpi_f107a(i),i=1,ngpidays)
!
! Get kp:
      
      allocate(gpi_kp(ngpikp,ngpidays))

      istat = nf_inq_varid(ncid,gpi_ncfile_kp_var,idv_kp)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting kp var id')
      istat = nf_get_var_double(ncid,idv_kp,gpi_kp)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting variable kp')
!     write(6,"('rdgpi: kp=',/(8f8.2))") (gpi_kp(:,i),i=1,ngpidays)

!      write(6,"('size gpi_kp ',2i8)") size(gpi_kp,1), size(gpi_kp,2)
      
      
      if (any(gpi_kp < 0.)) then
        do i=1,ngpidays
          if (any(gpi_kp(:,i) < 0.)) then
            write(6,"('>>> WARNING rdgpi: bad kp at i=',i5,
     |        ' gpi_iyd(i)=',i6,' gpi_kp(:,i)=',/,8e12.4)")
     |        i,gpi_iyd(i),gpi_kp(:,i)
          endif
        enddo
      endif
      
!
! Get beginning and ending integer dates:
! (these should be gpi_iyd(3) and gpi_iyd(ngpidays-2) respectively,
!  to enable interpolation using previous 2 days or last 2 days
!  at the extremes of the dates available).
!
      istat = nf_get_att_int(ncid,NF_GLOBAL,"yearday_beg",iyd_beg)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting global attribute yearday_beg')
      istat = nf_get_att_int(ncid,NF_GLOBAL,"yearday_end",iyd_end)
      if (istat /= NF_NOERR) call handle_ncerr(istat,
     |  'rdgpi: Error getting global attribute yearday_end')
!
      write(6,"('Number of days on GPI data file = ',i8)") ngpidays
      write(6,"('First and last year-days = ',2i8)") iyd_beg,iyd_end
!
! Close the file:
      istat = nf_close(ncid)
      write(6,"('Completed read from GPI data file ',a)") trim(dskfile)
      write(6,"(72('-'),/)")
      end subroutine rdgpi
!-----------------------------------------------------------------------
      subroutine getgpi(iyear,iday,iutsec,iprint)
!
! Use gpi data read from gpi.dat file to return geophysical indices
! at current date and time. Return only those indices from input
! (f107, f107a, power, and/or ctpoten) which are spval.
!
      use params_module,only: spval
      use input_module,only: f107,f107a,power,ctpoten,gpi_ncfile,
     |  rd_f107,rd_f107a,rd_power,rd_ctpoten,ntimes_power,
     |  ntimes_ctpoten,rd_kp
!
! Args:
      integer,intent(in) :: iyear,iday,iutsec,iprint
!
! Local:
      integer :: i,iyd_cur,loc,ier,
     |  if107,if107a,ipower,ictpoten,isecmin,isecmax,isec0,isec1
      real :: f107_cur, f107a_cur, fkp_cur(ngpikp),  ! at current day
     |        f107_prv, f107a_prv, fkp_prv(ngpikp),  ! at previous day
     |        f107_p2d, f107a_p2d, fkp_p2d(ngpikp),  ! at 2nd previous day
     |        f107_nxt, f107a_nxt, fkp_nxt(ngpikp),  ! at next day
     |        f107_n2d, f107a_n2d, fkp_n2d(ngpikp)   ! at 2nd next day
      real :: fkp0,fkp1
      real :: dtkp
      integer,parameter :: isecnoon = 12*60*60   ! secs at noon 
! 
! External:
      real,external :: finterp,hp_from_kp,ctpoten_from_kp
!
      if (iprint > 0) then
        write(6,"(/,72('-'))")
        write(6,"('GETGPI: get geophysical indices from data file ',a
     |    )") trim(gpi_ncfile)

        write(6,"('Initial requested iyear=',i4,' iday=',i3,' iutsec=',
     |    i10)") iyear,iday,iutsec
      endif
!
! Determine which indices to return:
! (Check params originally read by namelist read)
!
      if107=0 ; if107a=0 ; ipower=0 ; ictpoten=0
      if (rd_f107   == spval) if107=1
      if (rd_f107a  == spval) if107a=1
      if (rd_power  == spval.and.ntimes_power==0) ipower=1
      if (rd_ctpoten== spval.and.ntimes_ctpoten==0) ictpoten=1
      if (if107==0.and.if107a==0.and.ipower==0.and.ictpoten==0) then
        write(6,"('>>> WARNING getgpi: gpi_vars already provided',
     |    ' by user -- gpi data NOT used.')")
        write(6,"('f107 =',e12.4,' f107a  =',e12.4)") f107,f107a
        write(6,"('power=',e12.4,' ctpoten=',e12.4)") power,ctpoten
        write(6,"(72('-'),/)")
        return
      endif
!
! Check that requested date is available:
      iyd_cur = iyear*1000+iday

!     if (iyd_cur < iyd_beg .or. iyd_cur > iyd_end) then
!       write(6,"(/,'>>> getgpi: requested year-day is not available',
!    |    ' from gpi data file:')")
!       write(6,"(4x,'Requested year-day=',i8,' iyd_beg=',i8,
!    |    ' iyd_end=',i8,/)") iyd_cur,iyd_beg,iyd_end
!       write(6,"(72('-'),/)")
!       call shutdown('GPI')
!     endif
!
! Get data for current day:
!
      call getdat(iyd_cur,f107_cur,f107a_cur,fkp_cur,loc)
!
! 2/24/16 btf: This is to allow a gpi run to day 366 (day 1 of the
!   next year) when the gpi file only goes to 365,23,0:
!   
      if (loc == 0) then
        f107 = gpi_f107d(ngpidays)
        f107a = gpi_f107a(ngpidays)
!       write(6,"(/,'>>> getgpi: error finding iyd_cur=',i8,' in GPI ',
!    |    'data: using last f107=',f8.2,' f107a=',f8.2)") iyd_cur,
!    |    f107,f107a
        goto 500
      endif
!
! This allows gpi run to progress beyond 2 days prior to end of
! gpi file, bypassing f107 interpolation that requires 2 days
! beyond current day.
!
      if (iyd_cur < iyd_beg .or. iyd_cur > iyd_end) then
        f107 = f107_cur
        f107a = f107a_cur
!       write(6,"('Note getgpi cannot interpolate: iyd_cur=',i8,
!    |    ' iyd_beg=',i8,' iyd_end=',i8,'  Using current f107=',
!    |    f8.2,' f107a=',f8.2)") 
!    |    iyd_cur,iyd_beg,iyd_end,f107,f107a
        goto 500
      endif
!
! Previous day's data:
      f107_prv  = gpi_f107d(loc-1)
      f107a_prv = gpi_f107a(loc-1)
      fkp_prv(:) = gpi_kp(:,loc-1)
!
! Next day's data:
      f107_nxt  = gpi_f107d(loc+1)
      f107a_nxt = gpi_f107a(loc+1)
      fkp_nxt(:) = gpi_kp(:,loc+1)
!
! 2nd day previous and 2nd day next (needed only for fluxes):
      if (if107 > 0 .or. if107a > 0) then
        if (loc <= 2 .or. loc >= ngpidays-1) then
          write(6,"('>>> WARNING getgpi: loc=',i6,' ngpidays=',i6,
     |      ' cannot get 2nd day prev or 2nd day next.')") loc,ngpidays
        endif
        f107_p2d  = gpi_f107d(loc-2)
        f107a_p2d = gpi_f107a(loc-2)
        fkp_p2d(:) = gpi_kp(:,loc-2)
!
        f107_n2d  = gpi_f107d(loc+2)
        f107a_n2d = gpi_f107a(loc+2)
        fkp_n2d(:) = gpi_kp(:,loc+2)
      endif
!
! Interpolate fluxes to current time:
! If ut = 12, then use value for current day
! If ut < 12, then use previous two days and current day
! If ut > 12, then use next two days and current day
!
! TODO createGPI.py interpolates values to 0 UTC -> should be 12 UTC?
!
!     subroutine timeterp(d1,d2,d3,d4,ipos,isec_dat,isec_req,fout,
!    |  iprnt,ier)
!
      if (if107 > 0 .or. if107a > 0) then
        if (iutsec==isecnoon) then      ! no interp
          if (if107  > 0) f107  = f107_cur
          if (if107a > 0) f107a = f107a_cur
        elseif (iutsec < isecnoon) then
          if (if107 > 0)
     |      call timeterp(f107_p2d,f107_prv,f107_cur,f107_nxt,
     |        2,isecnoon,iutsec,f107,0,ier)
          if (if107a > 0)
     |      call timeterp(f107a_p2d,f107a_prv,f107a_cur,f107a_nxt,
     |        2,isecnoon,iutsec,f107a,0,ier)
        else
          if (if107 > 0)
     |      call timeterp(f107_prv,f107_cur,f107_nxt,f107_n2d,
     |        2,isecnoon,iutsec,f107,0,ier)
          if (if107a > 0)
     |      call timeterp(f107a_prv,f107a_cur,f107a_nxt,f107a_n2d,
     |        2,isecnoon,iutsec,f107a,0,ier)
        endif
      endif
!
! If need power or ctpoten, interpolate kp to current time, and
! calculate power and/or ctpoten from the interpolated kp:
!
  500 continue      
      if (ipower > 0 .or. ictpoten > 0) then
!
! If constant namelist Kp was provided, use it instead of data:
        if (rd_kp /= spval) then
          fkp = rd_kp 
!         write(6,"('Note getgpi: Using the provided constant Kp = ',
!    |      f10.3)") fkp
!
! Otherwise (namelist Kp not provided), interpolate data to model time:
        else
          dtkp = 24./float(ngpikp)
          isecmin = int(dtkp/2.*3600.)
          isecmax = int((24.-dtkp/2.)*3600.)
        
          if (iutsec >= isecmin .and. iutsec <= isecmax) then ! current day
            do i=1,ngpikp-1
              isec0 = int((float(i-1)*dtkp+dtkp/2.)*3600.)
              isec1 = isec0 + isecmin*2
              if (iutsec >= isec0 .and. iutsec <= isec1) then
                fkp0 = fkp_cur(i)
                fkp1 = fkp_cur(i+1)
                exit
              endif            
            enddo
          elseif (iutsec < isecmin) then ! use previous day
            isec0 = -isecmin
            isec1 = isecmin
            fkp0 = fkp_prv(ngpikp)
            fkp1 = fkp_cur(1)
          else                           ! use next day
            isec0 = isecmax
            isec1 = isecmax+int(dtkp*3600.)
            fkp0 = fkp_cur(ngpikp)
            fkp1 = fkp_nxt(1)
          endif
          fkp = finterp(fkp0,fkp1,isec0,isec1,iutsec)
          !write(6,"('FKP INTER fkp',3f10.4,2i8)") fkp,fkp0,fkp1,isec0,isec1
            
          
!
! Kp has been known to go < 0 due to interpolation.
!
          if (fkp < 0.) then
            write(6,"('>>> WARNING getgpi: bad kp = ',e12.4,' iyear=',
     |        i4,' iday=',i4,' real(iutsec)/3600.=',f10.2)")
     |        fkp,iyear,iday,real(iutsec)/3600.
            write(6,"('I am setting kp to zero.')")
            fkp = 0.
          endif
        endif ! rd_kp == spval

!
! Use empirical formulas to calculate ctpoten and hemispheric power 
! from kp (functions are in util.F):
        if (ictpoten > 0) ctpoten = ctpoten_from_kp(fkp)
        if (ipower > 0) power = hp_from_kp(fkp)
      endif ! doing power or ctpoten
!
#ifdef USE_PDAF
! perturbe or overwrite gpi data
      call perturbe_gpi
#endif
      if (iprint > 0) then
        write(6,"('Obtained the following GPI at the requested ',
     |    'date and time:')")
        if (if107    > 0) write(6,"('  f107    = ',e12.4)") f107
        if (if107a   > 0) write(6,"('  f107a   = ',e12.4)") f107a
        if (ipower   > 0) write(6,"('  power   = ',e12.4)") power
        if (ictpoten > 0) write(6,"('  ctpoten = ',e12.4)") ctpoten
        write(6,"(72('-'),/)")
      endif
      end subroutine getgpi
!-----------------------------------------------------------------------
#ifdef USE_PDAF
      subroutine perturbe_gpi

      use input_module,only: f107,f107a,power,ctpoten

      use model_parameter_handling_module, only: param_f107,
     |                                           param_ctpoten,
     |                                           param_hspower

      implicit none

      call param_f107%handle(f107)
      call param_f107%handle(f107a)

      call param_ctpoten%handle(ctpoten)
      call param_hspower%handle(power)
      end subroutine
#endif
!-----------------------------------------------------------------------
      subroutine getdat(iyd,f107,f107a,rkp,loc)
!
! Search for iyd (7-digit year-day) in gpi_iyr(ngpidays) (which was
! read from gpi.dat by sub rdgpi). If found, return f107, f107a, and
! rkp for that day, and index to the gpi arrays in loc. If not found, 
! or more than one occurrence of iyd is found, return loc == 0.
!
! Args:
      integer,intent(in) :: iyd
      real,intent(out) :: f107,f107a,rkp(ngpikp)
      integer,intent(out) :: loc
!
! Local:
      integer :: icount
      integer,external :: ixfind
!
      loc = 0
      f107 = 0.
      f107a = 0.
      rkp(:) = 0.
!
      loc = ixfind(gpi_iyd,ngpidays,iyd,icount) 
      if (loc <= 0) then
        write(6,"('>>> WARNING getdat: target iyd ',i8,
     |    ' not found in gpi_iyd.')") iyd
        return
      endif
      if (icount > 1) then
        write(6,"('>>> WARNING getdat: iyd=',i8,' -- more than ',
     |    'one occurrence of iyd found in gpi_iyd: icount=',i3)")
     |    iyd,icount
        loc = 0
        return
      endif
      f107  = gpi_f107d(loc)
      f107a = gpi_f107a(loc)
      rkp(:) = gpi_kp(:,loc)
      end subroutine getdat      
!-----------------------------------------------------------------------
      subroutine timeterp(d1,d2,d3,d4,ipos,isec_dat,isec_req,fout,
     |  iprnt,ier)
c
c Interpolate from fields d1,d2,d3,d4 (at 4 consecutive days,
c   and all at time isec_dat) to time isec_req, returning fout
c On input:
c   d1,d2,d3,d4 = the field at 4 consecutive days
c                 (all are at time isec_dat)
c   ipos = 1,2,3 for interpolation between d1 & d2, d2 & d3, or
c          d3 & d4 (usually ipos = 2)
c   isec_dat = time of fields at each of the 4 days (secs)
c   isec_req = desired time for interpolation (secs)
c In output:
c   fout is defined at desired isec_req
c   ier = 0 if no error
c
! Args:
      integer,intent(in) :: ipos,isec_dat,isec_req,iprnt
      integer,intent(out) :: ier
      real,intent(in) :: d1,d2,d3,d4
      real,intent(out) :: fout
!
! Local:
      integer :: itim_dat(3),itim_req(3),ncalls
      real :: frac0,frac1
!
      data ncalls/0/ ! for print only
c
c Check position and times:
c
      ncalls = ncalls+1
      ier = 0
      if (ipos.lt.1.or.ipos.gt.3) then
        write(6,"('>>> timeterp: bad ipos =',i3,
     +    ' (must be 1, 2, or 3)')") ipos
        ier = 1
        return
      endif
      if (isec_dat.lt.0.or.isec_dat.gt.86399) then
        write(6,"('>>> timeterp: bad isec_dat=',3i4)") isec_dat
        ier = 2
        return
      endif
      if (isec_req.lt.0.or.isec_req.gt.86399) then
        write(6,"('>>> timeterp: bad isec_req=',3i4)") isec_req
        ier = 3
        return
      endif
      call isec2hms(isec_dat,itim_dat(1),itim_dat(2),itim_dat(3))
      call isec2hms(isec_req,itim_req(1),itim_req(2),itim_req(3))
c
c Do interpolation:
c (note isec_dat may be 12*3600 or 0*3600, i.e., data can be at
c  0 or 12 ut)
c
      frac0 = float(mod(isec_req-isec_dat+86400,86400))/86400.
      if (iprnt.gt.0) write(6,"('timeterp: ih:im:is (req)=',i2,':',
     +  i2,':',i2,' ih:im:is (dat)=',i2,':',i2,':',i2,' frac0=',
     +  f10.5,' ipos=',i2)") itim_req,itim_dat,frac0,ipos
      if (ipos.eq.1) then ! between d1 and d2
        fout = -(((frac0-1.)*(frac0-2.)*(frac0-3.)*d1)/6.) +
     +          ((frac0*(frac0-2.)*(frac0-3.)*d2)/2.) -
     +          ((frac0*(frac0-1.)*(frac0-3.)*d3)/2.) +
     +          ((frac0*(frac0-1.)*(frac0-2.)*d4)/6.)
      elseif (ipos.eq.2) then ! between d2 and d3
        frac1 = 1.-frac0
        fout = -((frac0*(1.-frac0)*(2.-frac0)*d1)/6.) +
     +          (((1.+frac0)*(1.-frac0)*(2.-frac0)*d2)/2.) +
     +          (((1.+frac1)*(1.-frac1)*(2.-frac1)*d3)/2.) -
     +          ((frac1*(1.-frac1)*(2.-frac1)*d4)/6.)
      elseif (ipos.eq.3) then ! between d3 and d4
        fout = -(((frac0-1.)*(frac0-2.)*(frac0-3.)*d4)/6.) +
     +          ((frac0*(frac0-2.)*(frac0-3.)*d3)/2.) -
     +          ((frac0*(frac0-1.)*(frac0-3.)*d2)/2.) +
     +          ((frac0*(frac0-1.)*(frac0-2.)*d1)/6.)
      endif
      end subroutine timeterp
!-----------------------------------------------------------------------
      subroutine isec2hms(isec,ih,im,is)
      implicit none
!
! Args:
      integer,intent(in) :: isec
      integer,intent(out) :: ih,im,is
!
! Local:
      integer :: nsec
c
c Given integer seconds isec (not including days), return
c integer hour, minute, seconds in ih,im,is:
c
      ih = isec/3600
      nsec = mod(isec,3600)
      im = nsec/60
      is = mod(nsec,60)
      end subroutine isec2hms

c !-----------------------------------------------------------------------
c !
c ! >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
c ! >>>>>>>>>>>>>>>>>> Routines below are NOT called <<<<<<<<<<<<<<<<<<<<<
c ! >>>>>>>>>>>>>>>>>>  They are informational only <<<<<<<<<<<<<<<<<<<<<<
c ! >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
c !
c ! The routines mkncgpi, wrncgpi, idate2iyd, and ichdate are NOT
c ! called by the model. They are provided here as a record of
c ! how the data is obtained and how the netcdf file /TGCM/data/gpi.nc
c ! is written. See /home/foster/tgcminp/nc_gpi.
c !
c !-----------------------------------------------------------------------
c       subroutine mkncgpi
c !
c ! Read NGDC ascii gpi data, and write netcdf file for use by the model:
c !
c       integer luin,mxdays,iq,nbad,imo,ida
c       parameter(mxdays=10000)
c       character*120 flnmin
c       real f107d(mxdays),f107a(mxdays),rkp(8,mxdays)
c       integer ii,i,iyd(mxdays),iy2,kp(8),ndays
c       data luin/20/
c !
c ! ngdc.1979-2000.dat is NGDC ascii yearly data files obtained
c ! from the following URL, and catted together into a single file:
c ! ftp://ftp.ngdc.noaa.gov/STP/GEOMAGNETIC_DATA/INDICES/KP_AP/
c !
c       flnmin = " "
c       flnmin = "ngdc.1979-2000.dat"
c       open(luin,file=trim(flnmin),status='OLD',err=900)
c       do i=1,mxdays
c         read(luin,"(3i2,6x,8i2,37x,f5.1,i1)",end=100) iy2,imo,ida,kp,
c      +    f107d(i),iq
c         iyd(i) = idate2iyd(imo,ida,iy2,i)
c         do ii=1,8
c           rkp(ii,i) = float(kp(ii)/10)+float(kp(ii)-kp(ii)/10*10)*.1
c         enddo
c         f107a(i) = 0.
c !       if (mod(i,10).eq.0) write(6,"('i=',i5,' iyd=',i8,' f107d=',
c !    +    f5.1,' rkp=',8f5.1)") i,iyd(i),f107d(i),(rkp(ii,i),ii=1,8)
c       enddo
c       write(6,"('>>> need to increase mxdays (did not reach eof',
c      +  ' with mxdays=',i5,') <<<')") mxdays
c       call shutdown('mxdays')
c  100  continue
c       ndays = i-1
c       write(6,"('Finished read: ndays=',i5)") ndays
c c
c c f107d == 0. if no observation was made (iq=3). Fill these in
c c by simple interpolation if possible:
c c
c       nbad = 0
c       do i=2,ndays-1
c         if (f107d(i).le.0.) then
c           if (f107d(i-1).le.0..or.f107d(i+1).le.0.)
c      +      write(6,"('>>> warning: 2 or more bad f107d at i=',
c      +        i5)") i
c           f107d(i) = .5*(f107d(i-1)+f107d(i+1))
c           nbad = nbad+1
c         endif
c       enddo
c       if (nbad.gt.0) write(6,"('>>> nbad f107d = ',i5)") nbad
c c
c c Find as many f107a (81-day ave) values as possible:
c c (leave rest zero)
c c
c       if (ndays.ge.81) then
c         do i=41,ndays
c           if (i+40.gt.ndays) then
c             ii = i-1
c             goto 101
c           endif
c           f107a(i) = 0.
c           do ii=i-40,i+40
c             f107a(i) = f107a(i) + f107d(ii)
c           enddo
c           f107a(i) = f107a(i)/81.
c         enddo
c  101    continue
c         write(6,"('Calculated 81-day ave f107a for days ',
c      +    '41 to ',i5)") ii
c !       write(6,"('f107a=',/(8f8.2))") (f107a(i),i=1,ndays)
c       endif
c !
c       close(luin)
c !
c ! Write netcdf file:
c       call wrncgpi(iyd,f107d,f107a,rkp,ndays)
c !
c       write(6,"('done')")
c       call shutdown('done')
c  900  write(6,"('>>> Error opening input file ',a)") trim(flnmin)
c       call shutdown('flnmin')
c       end subroutine mkncgpi
c !-----------------------------------------------------------------------
c       subroutine wrncgpi(iyd,f107d,f107a,rkp,ndays)
c       use nchist_module,only: handle_ncerr
c !
c ! Args:
c       integer,intent(in) :: ndays
c       real,intent(in) :: f107d(ndays),f107a(ndays),rkp(8,ndays)
c       integer,intent(in) :: iyd(ndays)
c !
c ! Local:
c       integer :: istat,ncid,ids1(1),ivar1(1),ids2(2)
c       integer :: id_ndays,id_kp,idv_iyd,idv_f107d,idv_f107a,idv_kp
c       character(len=32) :: ncfile
c       character(len=80) :: char80
c       character(len=120) :: char120
c !
c ! Open new netcdf dataset:
c       ncfile = " "
c       ncfile = "gpi.nc"
c       istat = nf_create(ncfile,NF_CLOBBER,ncid)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'opening new netcdf dataset')
c !
c ! Define ndays dimension:
c       istat = nf_def_dim(ncid,"ndays",ndays,id_ndays)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      +  'Error defining ndays dimension')
c !
c ! Define kp dimension:
c       istat = nf_def_dim(ncid,"nkp",8,id_kp)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      +  'Error defining kp dimension')
c !
c ! Define variables iyd, f107d, f107a, kp:
c !
c ! iyd:
c       ids1(1) = id_ndays
c       istat = nf_def_var(ncid,"year_day",NF_INT,1,ids1,idv_iyd)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining variable yearday')
c       write(char80,"('4-digit year followed by 3-digit day')")
c       istat = nf_put_att_text(ncid,idv_iyd,"long_name",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining long_name of variable year_day')
c ! f107d:
c       istat = nf_def_var(ncid,"f107d",NF_DOUBLE,1,ids1,idv_f107d)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining variable f107d')
c       write(char80,"('daily 10.7 cm solar flux')")
c       istat = nf_put_att_text(ncid,idv_f107d,"long_name",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining long_name of variable f107d')
c ! f107a:
c       istat = nf_def_var(ncid,"f107a",NF_DOUBLE,1,ids1,idv_f107a)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining variable f107a')
c       write(char80,"('81-day average 10.7 cm solar flux')")
c       istat = nf_put_att_text(ncid,idv_f107a,"long_name",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining long_name of variable f107a')
c ! kp:
c       ids2(1) = id_kp
c       ids2(2) = id_ndays
c       istat = nf_def_var(ncid,"kp",NF_DOUBLE,2,ids2,idv_kp)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining variable kp')
c       write(char80,"('3-hourly kp index')")
c       istat = nf_put_att_text(ncid,idv_kp,"long_name",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining long_name of variable kp')
c !
c ! Global file attributes:
c !
c ! Title:
c       write(char80,"('Geophysical Indices, obtained from NGDC')")
c       istat = nf_put_att_text(ncid,NF_GLOBAL,"title",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining global attribute title')
c !
c ! Beginning yearday:
c ! (make it the 3rd day, so model interpolation can use 1st 2 days)
c       ivar1(1) = iyd(3)
c       istat = nf_put_att_int(ncid,NF_GLOBAL,"yearday_beg",NF_INT,1,
c      |  ivar1)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining global attribute yearday_beg')
c !
c ! Ending yearday:
c ! (make it day ngpidays-2, so model interpolation can use last 2 days)
c       ivar1(1) = iyd(ndays-2)
c       istat = nf_put_att_int(ncid,NF_GLOBAL,"yearday_end",NF_INT,1,
c      |  ivar1)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining global attribute yearday_end')
c !
c ! NGDC URL where ascii data was acquired:
c       write(char80,"('ftp://ftp.ngdc.noaa.gov/STP/GEOMAGNETIC_DATA',
c      |  '/INDICES/KP_AP/')")
c       istat = nf_put_att_text(ncid,NF_GLOBAL,"data_source_url",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining global attribute data_source_url')
c !
c ! Local path to program that wrote the netcdf file:
c       write(char80,"('/home/foster/tgcminp/nc_gpi/mkncgpi.f')")
c       istat = nf_put_att_text(ncid,NF_GLOBAL,"hao_file_write_source",
c      |  len_trim(char80),trim(char80))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining global attribute hao_file_write_source')
c !
c ! Description:
c       write(char120,"('Yearly ascii data files obtained from ',
c      |  'data_source_url; nc file written by hao_file_write_source.')")
c       istat = nf_put_att_text(ncid,NF_GLOBAL,"info",
c      |  len_trim(char120),trim(char120))
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error defining global attribute info')
c !
c ! Exit define mode:
c       istat = nf_enddef(ncid)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      +  'Error return from nf_enddef')
c !
c ! Give values to variables:
c !
c ! iyd:
c       istat = nf_put_var_int(ncid,idv_iyd,iyd)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error giving values to variable iyd')
c ! f107d:
c       istat = nf_put_var_real(ncid,idv_f107d,f107d)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error giving values to variable f107d')
c ! f107a:
c       istat = nf_put_var_real(ncid,idv_f107a,f107a)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error giving values to variable f107a')
c ! kp:
c       istat = nf_put_var_real(ncid,idv_kp,rkp)
c       if (istat /= NF_NOERR) call handle_ncerr(istat,
c      |  'Error giving values to variable kp')
c
c       istat = nf_close(ncid)
c       end subroutine wrncgpi
c !-----------------------------------------------------------------------
c       integer function idate2iyd(imo,ida,iyr,irec)
c !
c ! 2/16/00: Return 7-digit iyd, i.e., 4-digit leading year followed
c !          by 3-digit day, e.g., 1999001,2000365
c !
c ! Args:
c       integer,intent(in) :: imo,ida,iyr,irec
c !
c ! Local:
c       integer :: i,ndmon(12),iday,iyear
c !
c !                 J  F  M  A  M  J  J  A  S  O  N  D
c       data ndmon/31,28,31,30,31,30,31,31,30,31,30,31/
c !
c ! given iyr (2-digit), imo, ida, convert to iyd (yyddd):
c !
c       if (ichdate(imo,ida,iyr).ne.0) then
c         write(6,"('>>> idate2iyd: bad idate iyr,imo,ida=',3i3,
c      |    ' irec=',i6)") iyr,imo,ida,irec
c         idate2iyd = 0
c         return
c       endif
c       ndmon(2) = 28
c       if (mod(iyr,4).eq.0) ndmon(2) = 29
c       iday = 0
c       do i=1,imo-1
c         iday = iday+ndmon(i)
c       enddo
c       if (iyr < 50) then ! assume 21st century
c         iyear = 2000+iyr
c       else               ! assume 20th century
c         iyear = 1900+iyr
c       endif
c       idate2iyd = iyear*1000+iday+ida
c       return
c       end function idate2iyd
c !-----------------------------------------------------------------------
c       integer function ichdate(im,id,iy)
c !
c ! Args:
c       integer,intent(in) :: im,id,iy
c !
c ! Local:
c       integer :: ndmon(12)
c !
c c                 J  F  M  A  M  J  J  A  S  O  N  D
c       data ndmon/31,28,31,30,31,30,31,31,30,31,30,31/
c c
c c Check validity of date im/id/iy
c c
c       ichdate = 0
c       if (im.lt.1.or.im.gt.12) then
c         write(6,"('>>> ichdate: bad month=',i3)") im
c         ichdate = 1
c         return
c       endif
c       if (iy.lt.0.or.iy.gt.2050) then
c         write(6,"('>>> ichdate: bad year=',i3)") iy
c         ichdate = 1
c         return
c       endif
c       ndmon(2) = 28
c       if (mod(iy,4).eq.0) ndmon(2) = 29
c       if (id.lt.1.or.id.gt.ndmon(im)) then
c         write(6 ,"('>>> ichdate: bad day=',i4,' (month=',i2,')')")
c      +    id,im
c         ichdate = 1
c         return
c       endif
c       return
c       end function ichdate

      end module gpi_module
!-----------------------------------------------------------------------
! Following is ncdump info for /TGCM/data/gpi_1979001-2001031.nc
!
!netcdf TGCM.data.gpi_1979001-2001031 {
!dimensions:
!        ndays = 8067 ;
!        nkp = 8 ;
!variables:
!        int year_day(ndays) ;
!                year_day:long_name = "4-digit year followed by 3-digit day" ;
!        double f107d(ndays) ;
!                f107d:long_name = "daily 10.7 cm solar flux" ;
!        double f107a(ndays) ;
!                f107a:long_name = "81-day average 10.7 cm solar flux" ;
!        double kp(ndays, nkp) ;
!                kp:long_name = "3-hourly kp index" ;
!
!// global attributes:
!                :title = "Geophysical Indices, obtained from NGDC" ;
!                :yearday_beg = 1979003 ;
!                :yearday_end = 2001029 ;
!                :ncar_mss_path = "/TGCM/data/gpi_1979001-2001031.nc" ;
!                :data_source_url = "ftp://ftp.ngdc.noaa.gov/STP/GEOMAGNETIC_DATA/INDICE
!S/KP_AP/" ;
!                :hao_file_write_source = "/home/foster/tgcminp/nc_gpi/mkncgpi.f" ;
!                :info = "Yearly ascii data files obtained from data_source_url; nc file
! written by hao_file_write_source." ;
!data:
!}
!-----------------------------------------------------------------------
