#!/usr/bin/env python3
"""Bakuzis projection set (2026-11-12). Three real starting stands from the regional benchmark set (spruce-fir, mixedwood, northern
hardwood; live BA 15 to 22 m2/ha, QMD 10 to 15 cm, >= 1,200 stems/ha, unmanaged), each projected from the same start for 10 to 100
years in 10-year steps at five site levels (ESI 10, 12, 14, 16 and 18 m at base 50). Written as the bridge set bakz (one row per
stand x site x horizon) so every arm runs through the production runner. Writes state/restricted/r0e/bakz_{pairs,trees}.csv."""
import numpy as np, pandas as pd, json
from pathlib import Path
RS = Path.home() / "fvsacd142/state/restricted/r0e"; HA = 2.4710538
P = pd.read_csv(RS / "reg_pairs.csv", dtype={"pair_id": str, "t1_id": str}); T = pd.read_csv(RS / "reg_trees.csv", dtype={"pair_id": str})
rs = pd.read_csv(Path.home() / "jobs/bakuzis_fvsconus_20261027/repos/fvs-modern/data/NSBE/REF_SPECIES.csv", usecols=["SPCD", "SFTWD_HRDWD"])
sw = dict(zip(rs.SPCD, rs.SFTWD_HRDWD == "S")); T = T[T.DIA >= 1.0]
T["ba"] = np.pi / 40000 * (T.DIA * 2.54) ** 2 * T.TPA_UNADJ * HA; T["sw"] = T.SPCD.map(sw).fillna(False)
g = T.groupby("pair_id"); S = pd.DataFrame({"ba": g.ba.sum(), "tph": g.TPA_UNADJ.sum() * HA, "swb": T[T.sw].groupby("pair_id").ba.sum()}).fillna(0)
S["qmd"] = np.sqrt(S.ba / S.tph / (np.pi / 40000)); S["sws"] = S.swb / S.ba
S = S.join(P.set_index("pair_id")[["MANAGED", "SET", "ELEV"]])
S = S[(S.MANAGED == 0) & S.ba.between(15, 22) & S.qmd.between(10, 15) & (S.tph >= 1200)]
pick = {}
for nm, lo, hi in (("SF", 0.8, 1.01), ("MX", 0.4, 0.6), ("NH", -0.01, 0.2)):
    c = S[S.sws.between(lo, hi)].copy(); c["d"] = ((c.ba - 18.5) / 3.5) ** 2 + ((c.qmd - 12.5) / 1.5) ** 2; pick[nm] = c.sort_values(["d"]).index[0]
rows, trees, i = [], [], 0
for nm, pid in pick.items():
    for si in (10, 12, 14, 16, 18):
        for h in range(10, 101, 10):
            i += 1; new = f"{i:012d}"
            rows.append(dict(pair_id=new, t1_id=f"BAKZ__{nm}__si{si}__h{h:03d}", INVYR1=2000, REMPER=float(h), SICOND_FVS=si * 3.2808399, STDAGE=np.nan,
                             ASPECT=np.nan, SLOPE=np.nan, ELEV=1000.0, FORTYPCD=np.nan, SISP_FVS=np.nan, SITE=f"{nm}_si{si}", SET="bakz", block=nm, JURIS="ME",
                             MANAGED=0, SCORE_MINDBH=10.0, obsBA1=np.nan, obsBA2=np.nan, obsN1=np.nan, obsN2=np.nan, rawBA1=np.nan, rawN1=np.nan,
                             BA_T1=np.nan, BA_T2=np.nan, TPH_T1=np.nan, TPH_T2=np.nan, si_src="fixed_grid"))
            trees.append(T[T.pair_id == pid].drop(columns=["ba", "sw"]).assign(pair_id=new))
pd.DataFrame(rows).to_csv(RS / "bakz_pairs.csv", index=False); pd.concat(trees).to_csv(RS / "bakz_trees.csv", index=False)
print(json.dumps({k: dict(pair=v, **{c: round(float(S.loc[v, c]), 3) for c in ("ba", "tph", "qmd", "sws")}, set=S.loc[v, "SET"]) for k, v in pick.items()}, indent=1), len(rows))
