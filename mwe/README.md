# TIE-GCM-PDAF Minimal Working Example

This is a small, self-contained example for running TIE-GCM-PDAF. Run it with
`./run.sh`.

## Limitations

> [!Warning]
> This setup is **not recommended for productive runs** -- results won't be
> accurate.

This is because:

* No external data is read for the lower boundary condition and external
  forcing, making them inaccurate
* HEELIS is used instead of WEIMER, since it does not require an external
  data file
* The spin-up phase (generating the ensemle spread) lasts only for one day
* The ensemble is too small to sufficiently represent model uncertainty

## Running

`run.sh` performs two consecutive TIE-GCM-PDAF runs:

### 1. Ensemble initialization (`ensemble_initalization/`)

An open-loop run from **1 April 2010, 00:00 UT to 3 April 2010, 00:00 UT**
(2 days), that propagates the ensemble to generate the ensemble spread. This
period covers both the day before the assimilation run and the assimilation
run's own period. Produces:

* `ensemble_initalization.nc` -- the assimilation system's own result file
* `ens_*_ensemble_init_prim.nc`, `ens_*_ensemble_init_sech.nc` -- one primary
  and one secondary TIE-GCM history file per ensemble member

### 2. Assimilation (`assimilation/`)

The actual assimilation run, from **2 April 2010, 00:00 UT to 3 April 2010,
00:00 UT** (1 day), using the ensemble state that step 1 has reached by
2 April 2010, 00:00 UT as its initial state. Produces:

* `assimilation.nc` -- the assimilation system's own result file

Both stages assimilate CHAMP mass density observations from
`data/champ_denswind_v3_4_2010-04.nc`.

## Plotting

`plot_champ_density.py` plots the along-orbit CHAMP mass density (ensemble
mean) from both runs in a single panel, over their common time period. It
requires `xarray`, `netCDF4` and `matplotlib`. Run it after `run.sh`
has completed:

```
python3 plot_champ_density.py
```

This writes `champ_density_comparison.png`.

## Adjusting the ensemble size

Depending on your machine, you may want to change the ensemble size or the
number of cores per member. Both are set at the top of `run.sh`:

```
cores_per_member=4
n_ensemble_members=2
```

`run.sh` computes `npes` (the total number of MPI ranks) as their product,
and automatically updates `ensemble%ensemble_size` in both
`ensemble_initalization/ensemble_initalization.cfg` and
`assimilation/assimilation.cfg` to match `n_ensemble_members` before running
-- there is no need to edit the `.cfg` files by hand. Your machine must have
at least `cores_per_member * n_ensemble_members` threads available (see the
comments in `run.sh` for the `--oversubscribe` workaround).

> [!Important]
> The ensemble size cannot exceed **32**, since `data/perturbations_mwe_2010.nc`
> only provides perturbations for 32 members.
