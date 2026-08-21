#!/bin/bash
#
# Minimal working example for TIE-GCM-PDAF.
# Runs two consecutive stages: an open-loop ensemble initialization, followed
# by an assimilation run that uses its result as the initial ensemble state.
# See README.md for details. Usage: ./run.sh

# For this example an executable build with 5.0 degree horizontal resolution and with PDAF coupling is required
# `WITH_PDAF=TRUE EXE_NAME=tiegcm5.0-pdaf BUILD_DIR=build/tiegcm5.0-pdaf HIGH_RES=FALSE make -j 8`
exec=../bin/tiegcm-pdaf

# each ensemble member/model instance runs in parallel.
# typically on 4, 8 or 16 threads. For more threads the efficiency gain is negligible.
cores_per_member=4

# ensemble size. Maximum number in this example is 32 (there are not more samples in perturbations_mwe_2010.nc), but for productive runs 96 or more members have been used. Must be at least two, otherwise model variance cannot be computed.
n_ensemble_members=2

# Note due to the fully parallel implementation your machine must have at least cores_per_member * n_ensemble_members threads to run this example. You can use the MPI `--oversubscribe` option to ignore this limitation. However this will heavily degrade performance.

mpiruncmd=mpirun

# `--output-filename ./out --merge-stderr-to-stdout` writes the output of each rank to an individual file, which makes reading it much easier
# `--use-hwthread-cpus` should not be used for productive runs. Here it allows to run mpi also with virtual cores of the CPU. Helpful if your machine has a limited number of cores
mpiexec_additional_args="--output-filename ./out --merge-stderr-to-stdout --use-hwthread-cpus"

exec=$(realpath ${exec})
mwe_dir=$(pwd)

npes=$((cores_per_member * n_ensemble_members))
# Make sure the ensemble size configured for both stages matches n_ensemble_members
for cfg_file in $mwe_dir/ensemble_initalization/ensemble_initalization.cfg $mwe_dir/assimilation/assimilation.cfg; do
    sed -i -E "s/(ensemble%ensemble_size[[:space:]]*=[[:space:]]*)[0-9]+/\1${n_ensemble_members}/" ${cfg_file}
done

# First perform an open loop run to generate the ensemble spread
cd $mwe_dir/ensemble_initalization

tiegcm_nml=$(realpath tiegcm.inp)
pdaf_nml=$(realpath ensemble_initalization.cfg)

mkdir -p results
cd results

${mpiruncmd} -np ${npes} ${mpiexec_additional_args} ${exec} ${tiegcm_nml} ${pdaf_nml}

# Perform assimilation run. Use results of open loop simulation as initial state ensemble
cd $mwe_dir/assimilation

tiegcm_nml=$(realpath tiegcm.inp)
pdaf_nml=$(realpath assimilation.cfg)

mkdir -p results
cd results

${mpiruncmd} -np ${npes} ${mpiexec_additional_args} ${exec} ${tiegcm_nml} ${pdaf_nml}

cd $mwe_dir/
