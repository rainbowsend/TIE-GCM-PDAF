#!/bin/bash

exec=../bin/tiegcm-pdaf
npes=12
tiegcm_nml=../cfg/tiegcm.inp
pdaf_nml=
mpiruncmd=mpirun
output=./out

debug="file_per_rank"

exec=$(realpath ${exec})
tiegcm_nml=$(realpath ${tiegcm_nml})
pdaf_nml=$(realpath ${pdaf_nml})
mpiruncmd=$(realpath ${mpiruncmd})
output=$(realpath ${output})

mkdir -p results
cd results

case ${debug} in
    "gdb")
    ${mpiruncmd} --use-hwthread-cpus -np ${npes} xterm -e gdb \
    -ex 'set debuginfod enabled on' \
    -ex 'set max-value-size unlimited' \
    -ex ' set pagination off set non-stop on' \
    -ex 'run' --args ${exec} ${tiegcm_nml} ${pdaf_nml}
    ;;
    "mcheck")
    ${mpiruncmd} -np ${npes} --use-hwthread-cpus valgrind --leak-check=full -v --track-origins=yes --show-leak-kinds=all --log-file="${output}.vg.%p" ${exec} ${tiegcm_nml} ${pdaf_nml}
    ;;
    "massif")
    ${mpiruncmd} -np ${npes} --use-hwthread-cpus valgrind --tool=massif --max-snapshots=500 --threshold=0.05 --pages-as-heap=no ${exec} ${tiegcm_nml} ${pdaf_nml}
    ;;
    "file_per_rank")
    ${mpiruncmd} -np ${npes} --use-hwthread-cpus --output-filename ${output} --merge-stderr-to-stdout ${exec} ${tiegcm_nml} ${pdaf_nml}
    ;;
    "scorep")
    # requires that the application is compiled with scorep
    export SCOREP_ENABLE_TRACING=TRUE
    mpiexec -np ${npes} --use-hwthread-cpus ${exec} ${tiegcm_nml} ${pdaf_nml}
    ;;
    *)
    ${mpiruncmd} -np ${npes} --use-hwthread-cpus ${exec} ${tiegcm_nml} ${pdaf_nml}
    ;;
esac
