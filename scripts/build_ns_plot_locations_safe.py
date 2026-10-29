#!/usr/bin/env python3
"""
Build a coordinate-safe NS plot-location summary for the benchmark footprint map track.
No raw coordinates are exported (NS PSP data is licensed, per
2016009_UMaine_AaronWeiskittle_PSP_LicAgr.PDF, and CLAUDE.md treats plot-level coordinates as
release-restricted by default). Aggregated to COUNTY_COD (Nova Scotia county code, from
NovaScotiaLatLong.csv) with plot counts and managed/unmanaged counts per county.

Operational PSPs (NS_PSP_tree.csv) join reliably to NovaScotiaLatLong.csv on stand==PLOT_NUMBE
(3270/3270 operational stands match). Research/thinning PSPs (NS_PSP_research_tree.csv) use a
separate stand-numbering scheme from a different source database (NS_Research.accdb) with no
reliable county join available locally (a small numeric overlap with PLOT_NUMBE, 38/422, is
almost certainly coincidental collision, not a real correspondence, so it is not used) -- these
are reported as a separate "Research network (county not resolved)" row rather than mis-assigned
to a county.
"""
import pandas as pd
import os

NS_DIR = "/sessions/fervent-pensive-goodall/mnt/Nova Scotia"
OUT = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/repos/fvs-acd/figures/_data/ns_plot_locations_safe.csv"

ll = pd.read_csv(os.path.join(NS_DIR, "NovaScotiaLatLong.csv"))
ll = ll[["PLOT_NUMBE", "COUNTY_COD"]].drop_duplicates(subset="PLOT_NUMBE")

op = pd.read_csv(os.path.join(NS_DIR, "NS_PSP_tree.csv"), low_memory=False)
op_stands = op[["stand"]].drop_duplicates().rename(columns={"stand": "PLOT_NUMBE"})

samp = pd.read_sas(os.path.join(NS_DIR, "sample.sas7bdat"), encoding="latin1")
samp["stand"] = samp["PLOT_NUMBE"].astype(float).astype(int)
samp["SILVICULTU"] = samp["SILVICULTU"].apply(
    lambda b: b.decode("latin1").strip() if isinstance(b, (bytes, bytearray)) else str(b).strip()
)
TREATED_CODES = {"02", "05", "06", "07", "08"}
samp["is_treated"] = samp["SILVICULTU"].isin(TREATED_CODES)
managed_map = samp.groupby("stand")["is_treated"].any().to_dict()

op_stands["MANAGED"] = op_stands["PLOT_NUMBE"].map(lambda s: 1 if managed_map.get(s, False) else 0)
op_stands = op_stands.merge(ll, on="PLOT_NUMBE", how="left")

county_summary = op_stands.groupby("COUNTY_COD").agg(
    n_plots=("PLOT_NUMBE", "nunique"),
    n_managed=("MANAGED", "sum"),
).reset_index()
county_summary["n_unmanaged"] = county_summary["n_plots"] - county_summary["n_managed"]
county_summary["source"] = "Operational PSP"
county_summary = county_summary.rename(columns={"COUNTY_COD": "county_code"})

rs = pd.read_csv(os.path.join(NS_DIR, "NS_PSP_research_tree.csv"), low_memory=False)
n_research_stands = rs["stand"].nunique()
research_row = pd.DataFrame([{
    "county_code": "RESEARCH_NETWORK_COUNTY_NOT_RESOLVED",
    "n_plots": n_research_stands,
    "n_managed": n_research_stands,
    "n_unmanaged": 0,
    "source": "Research/thinning PSP",
}])

out = pd.concat([county_summary, research_row], ignore_index=True)
out = out[["source", "county_code", "n_plots", "n_managed", "n_unmanaged"]]
out.to_csv(OUT, index=False)
print(out.to_string(index=False))
print("\nwrote", OUT)
print("total plots:", out.n_plots.sum())
