#!/usr/bin/env python3
"""
Plots the along-orbit CHAMP mass density (DEN) from the ensemble
initialization (open loop) and assimilation runs, over their common time
period, using the ensemble mean of each.

Usage: python3 plot_champ_density.py
"""

from pathlib import Path

import matplotlib.pyplot as plt
import xarray as xr

MWE_DIR = Path(__file__).resolve().parent
OPEN_LOOP_FILE = MWE_DIR / "ensemble_initalization" / "results" / "ensemble_initalization.nc"
ASSIM_FILE = MWE_DIR / "assimilation" / "results" / "assimilation.nc"
OUTPUT_FILE = MWE_DIR / "champ_density_comparison.png"

# Real neutral mass density is always far below this (order 1e-16 to 1e-11
# g/cm3 at satellite altitudes). Time steps without a matching along-track
# observation are instead written as NetCDF's default float fill value
# (~9.9692e+36), but without a _FillValue attribute for xarray to auto-mask,
# so it must be filtered out explicitly.
DEN_FILL_THRESHOLD = 1e-5


def load_champ_den(path):
    """Along-orbit ensemble-mean CHAMP mass density (DEN), indexed by time.

    The coordinates (time, lon, lat, alt) live in the "champ" group, while
    the ensemble-mean fields live in the child group "champ/mean"; xarray
    does not inherit them across groups, so they are opened separately and
    joined on the shared "n" (trajectory point) dimension.
    """
    coords = xr.open_dataset(path, group="champ")
    mean = xr.open_dataset(path, group="champ/mean")
    den = mean["DEN"].assign_coords(time=("n", coords["time"].values))
    den = den.where(den < DEN_FILL_THRESHOLD)
    return den.swap_dims({"n": "time"})


def main():
    den_open_loop = load_champ_den(OPEN_LOOP_FILE)
    den_assim = load_champ_den(ASSIM_FILE)

    # restrict both time series to their common (overlapping) period
    start = max(den_open_loop.time.values.min(), den_assim.time.values.min())
    end = min(den_open_loop.time.values.max(), den_assim.time.values.max())
    den_open_loop = den_open_loop.sel(time=slice(start, end))
    den_assim = den_assim.sel(time=slice(start, end))

    fig, ax = plt.subplots(figsize=(10, 4))
    den_open_loop.plot(ax=ax, label="open loop", color="tab:blue")
    den_assim.plot(ax=ax, label="assimilation", color="tab:orange")
    ax.set_ylabel(f"mass density ({den_assim.attrs.get('units', '')})")
    ax.set_xlabel("time")
    ax.set_title("CHAMP along-orbit mass density: open loop vs. assimilation")
    ax.legend()
    fig.tight_layout()
    fig.savefig(OUTPUT_FILE, dpi=150)
    print(f"wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
