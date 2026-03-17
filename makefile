# control make options via a MAKE_MACHINE file
#  `$ MAKE_MACHINE=Make.example make`
#
# if MAKE_MACHINE is not defined, this makefiles looks for a file
# named Make.<hostname>. If this file is not found a generic configuration
# is used
#
#
# OPTIONS
# WITH_PDAF=TRUE make   ... if true compile TIE-GCM with PDAF coupling
# EXE_NAME=tiegcm make  ... controlls the name of the executable
# BUILD_DIR=build       ... controlls location of build directory
# HIGH_RES=FALSE        ... if true use 2.5° instead of 5.0° horizontal resolution
# ALT_EXT=FALSE         ... if true use altitude extension
#
#
# created on 27 OCT 2022
# Armin Corbin
# Astronomical, Mathematical and Physical Geodesy Group
# Institute for Geodesy and Geoinformation
# University of Bonn

bold := $(shell tput bold)
sgr0 := $(shell tput sgr0)

# default value for WITH_PDAF, may be overwritten by MAKE_MACHINE
ifeq ($(WITH_PDAF),)
	WITH_PDAF=TRUE
endif

# default value for EXE_NAME, may be overwritten by MAKE_MACHINE
ifeq ($(EXE_NAME),)
	EXE_NAME=tiegcm-pdaf
endif

ifeq ($(BUILD_DIR),)
	BUILD_DIR=build
endif

ifeq ($(HIGH_RES),)
	HIGH_RES=FALSE
endif

ifeq ($(ALT_EXT),)
	ALT_EXT=FALSE
endif

ifeq ($(MAKE_MACHINE),)
MAKE_MACHINE = Make.$(shell hostname)
ifeq ("$(wildcard $(MAKE_MACHINE))","")
    $(info $(bold)No host dependend file was found. Use generic setup$(sgr0))
    MAKE_MACHINE = Make.gfortran
endif
endif
$(info $(bold)using configuration in $(MAKE_MACHINE)$(sgr0))
include $(MAKE_MACHINE)

MAKE = make

ifeq ($(HIGH_RES),TRUE)
	FFLAGS+=-DHIGH_RES
endif

ifeq ($(ALT_EXT),TRUE)
	FFLAGS+=-DALT_EXT
endif

FFLAGS+= -ffixed-line-length-80 -DMPI
FFLAGS += $(OPTIM)

WARNINGS= -Waliasing -Wampersand -Wconversion -Wsurprising -Wintrinsic-shadow -Winteger-division -Wreal-q-constant -Wmaybe-uninitialized

BIND_SRC_DIR := deps/pdaf-binding-tiegcm/src
TGCM_SRC_DIR := src

INCLUDE:= $(INC_NETCDF) \
          $(INC_MPI) \
          $(ESMF_F90COMPILEPATHS) \
          -I$(TGCM_SRC_DIR)

LIB= $(LIB_NETCDF) \
     $(LIB_ESMF)  \
     $(LIB_MPI) \
     $(LIB_LAPACK)

ifeq ($(WITH_PDAF),TRUE)
       LIB += $(LIB_PDAF)
       LIB += -L deps/geodetic-fortran-utilities/lib -lgfu
       INCLUDE += $(INC_PDAF)
       INCLUDE += -I$(BIND_SRC_DIR)
       INCLUDE += -I deps/geodetic-fortran-utilities/include
       FFLAGS += -DUSE_PDAF
endif


LDFLAGS  := $(ESMF_F90LINKOPTS) $(ESMF_F90LINKPATHS) $(ESMF_F90LINKRPATHS) $(ESMF_F90ESMFLINKLIBS)

OBJDIR := $(BUILD_DIR)
MODDIR := $(OBJDIR)
BINDIR := bin

COMPILE.f18 = $(FC) $(FFLAGS) $(INCLUDE) -std=f2018 -ffree-form -fall-intrinsics -Wall -pedantic -c -o $@ -J $(MODDIR)
COMPILE.f77 = $(FC) $(FFLAGS) $(INCLUDE) -std=legacy -ffixed-form $(WARNINGS) -c -o $@ -J $(MODDIR)
COMPILE.f90 = $(FC) $(FFLAGS) $(INCLUDE) -std=legacy -ffree-form $(WARNINGS) -c -o $@ -J $(MODDIR)

TGCM_SRCS :=	addfld.F         comp_ar.F   duv.F       hist.F           minor.F       pdynamo.F     soldata.F     \
		addiag.F         comp.F      dynamics.F  imf.F            mkhvols.F     qinite.F      sphpac.F      \
		advance.F        comp_n2d.F  dyndiag.F   init.F           mk_polelat.F  qjion.F       swdot.F       \
		advec.F          comp_n4s.F  elden.F     input.F          mpi.F         qjnno.F       tgcm.F        \
		allocdata.F      comp_no.F   esmf.F      input_read.F     mudcom.F      qjoule.F      timing.F      \
		amie.F           comp_o2o.F  fft9.F      ionvel.F         mud.F         qrj.F         timing_mpi.F  \
		amieoutput.F     cons.F      fields.F    lamdas.F         mudmod.F      rdsource.F    trsolv.F      \
		aurora.F         cpktkm.F    geopack.F   laplacian.F      muh2cr.F      rgrd1.F       util.F        \
		bgrd_data.F      ctmt.F      getapex.F   lbc.F            nchist.F      rgrd2.F       vtsetup.F     \
		calculate_ecf.F  dates.F     getfile.F   lsqdsq.F         newton.F      rgrd3.F       wei05sc.F     \
		chapman.F        diags.F     gpi.F       mage_coupling.F  numfiles.F    ringfilter.F  wrhist.F      \
		chemrates.F      dispose.F   gswm.F      mage_oneway.F    oplus.F       saber_tidi.F                \
		cism_coupling.F  divrg.F     hdif.F      magfield.F       output.F      settei.F                    \
		colath.F         dt.F        heelis.F    magpres_g.F      params.F      smooth.F


TGCM_SRCS_90 := apex.F90 char.F90 current.F90 eclipse.F90  he_coefs.F90  interp.F90  matutil.F90  nudge.F90  subaur.F90

TGCM_OBJS := $(TGCM_SRCS:%.F=$(OBJDIR)/%.o)
TGCM_OBJS_90 := $(TGCM_SRCS_90:%.F90=$(OBJDIR)/%.o)

BIND_SRC := 	trajectory_data.F90            model_parameters.F90 \
		assimilate_pdaf.F90            model_parameters_handling.F90 \
		calc_diagnostics.F90           mod_parallel_pdaf.F90 \
		callback_obs_pdafomi.F90       mpi_moments.F90 \
		cell_id_coordinate_system.F90  nc_functionality.F90 \
		collect_state_pdaf.F90         next_observation_pdaf.F90 \
		configuration.F90              obs_satellite_pdafomi.F90 \
		constraints.F90                observations.F90 \
		debugFun.F90                   obs_tgcm_pdaf_omi.F90 \
		default_lapack_interface.F90   obs_tme_grid_pdafomi.F90 \
		distribute_state_pdaf.F90      obs_type_omi.F90 \
		ensemble.F90                   optimized_interpolator.F90 \
		field_bundle.F90               parser_mpi.F90 \
		finalize_pdaf.F90              prepoststep_ens_pdaf.F90 \
		g2l_state_pdaf.F90             print_parallel_info.F90 \
		georeferenced_data.F90 \
		grid_observation.F90           quantity_computation.F90 \
		init_dim_l_pdaf.F90            quantity_info.F90 \
		init_ens.F90                   quantity_set.F90 \
		init_n_domains_pdaf.F90        result_file_writer.F90 \
		init_parallel_pdaf.F90         result_file_writer_frontend.F90 \
		init_pdaf.F90                  set_pdaf_omi_domain_limits.F90 \
		init_pdaf_info.F90             state.F90 \
		init_pdaf_parse.F90            subdomain.F90 \
		l2g_state_pdaf.F90             task_distribution.F90 \
		mapping.F90                    time.F90 \
		mod_assimilation.F90           uset.F90 \
		model_parameter_IO.F90

BIND_OBJS := $(BIND_SRC:%.F90=$(OBJDIR)/%.o)

.phony: exe
exe: $(BINDIR)/$(EXE_NAME)

.Phony: all
all: Depends exe

.Phony:
Depends:
	./mkdepends $(BIND_SRC_DIR) $(TGCM_SRC_DIR) $(OBJDIR)
	
ifeq ($(WITH_PDAF),TRUE)
$(BIND_OBJS) : $(OBJDIR)/%.o: $(BIND_SRC_DIR)/%.F90 | gitversion objdir moddir
	$(info $(bold)compile $<$(sgr0)  target: $@ )
	$(COMPILE.f18) $<
endif
	
$(TGCM_OBJS) : $(OBJDIR)/%.o: $(TGCM_SRC_DIR)/%.F | objdir moddir
	$(info $(bold)compile $<$(sgr0))
	$(COMPILE.f77) $<
	
$(TGCM_OBJS_90):  $(OBJDIR)/%.o: $(TGCM_SRC_DIR)/%.F90 | objdir moddir
	$(info $(bold)compile $<$(sgr0))
	$(COMPILE.f90) $<

$(OBJDIR)/util.o: $(TGCM_SRC_DIR)/util.F
	$(COMPILE.f77) -fallow-invalid-boz -DLINUX $(CPPFLAGS) $(ESMF_F90COMPILEPATHS) $<


PROG_DEPS = $(TGCM_OBJS) $(TGCM_OBJS_90)
ifeq ($(WITH_PDAF),TRUE)
	PROG_DEPS += $(BIND_OBJS)
endif

$(BINDIR)/$(EXE_NAME): $(PROG_DEPS) | bindir
	$(info $(bold)linking $@$(sgr0))
	$(FC) -o $@ $(PROG_DEPS) $(LIB) $(LDFLAGS)
	chmod u=rwx $@

$(TGCM_SRC_DIR)/svn_revision.inc:
	@rm -rf $(TGCM_SRC_DIR)/svn_revision.inc
	@echo "! This file is auto-generated by the TIEGCM build process" >$@
	@echo "      character(len=16) :: svn_revision = 'not tracked'" >>$@
	
$(TGCM_SRC_DIR)/nchist.F: $(TGCM_SRC_DIR)/svn_revision.inc


.phony: gitversion
gitversion: $(BIND_SRC_DIR)/gitversion.inc

$(BIND_SRC_DIR)/gitversion.inc: .git/HEAD .git/index
	@printf "! This file is auto-generated by the TIEGCM build process\ncharacter(len=40) :: gitversion = '$(shell git rev-parse HEAD)'" > $@

.Phony:	bindir moddir objdir
bindir:
	@mkdir -p $(BINDIR)

moddir:
	@mkdir -p $(MODDIR)
	
objdir:
	@mkdir -p $(OBJDIR)

.Phony: clean veryclean
clean :
	rm -rf $(OBJDIR)/*.o
	rm -rf $(MODDIR)/*.mod
	rm -rf $(BINDIR)/*.a

veryclean: clean
	rm -rf $(OBJDIR)
	rm -rf $(MODDIR)
	rm -rf $(BINDIR)
	rm -rf Depends
	
include Depends
