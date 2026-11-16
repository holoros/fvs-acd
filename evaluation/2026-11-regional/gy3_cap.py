#!/usr/bin/env python3
"""PREREG_GY2 Amendment 4a: cap gy3 and gy3L at 150 pairs per program (seed 20261115) before any score. The full sets are kept as
gy3full and gy3Lfull in r0e. Pair ids are unchanged. Writes counts to gy3_cap.json."""
import json, numpy as np, pandas as pd
from pathlib import Path
RS = Path.home() / "fvsacd142/state/restricted/r0e"; CAP = 150; out = {}
for s in ("gy3", "gy3L"):
    fp, ft = RS / f"{s}full_pairs.csv", RS / f"{s}full_trees.csv"
    if not fp.exists():
        (RS / f"{s}_pairs.csv").rename(fp); (RS / f"{s}_trees.csv").rename(ft)
    P = pd.read_csv(fp, dtype={"pair_id": str, "t1_id": str}); T = pd.read_csv(ft, dtype={"pair_id": str, "tree_cn": str})
    rng = np.random.default_rng(20261115); keep = []
    for b, g in P.sort_values("pair_id").groupby("block", sort=True):
        ids = g.pair_id.to_numpy(); keep += list(ids if len(ids) <= CAP else rng.choice(ids, CAP, replace=False))
    P2 = P[P.pair_id.isin(keep)]; T2 = T[T.pair_id.isin(keep)]
    P2.to_csv(RS / f"{s}_pairs.csv", index=False); T2.to_csv(RS / f"{s}_trees.csv", index=False)
    out[s] = dict(full=int(len(P)), capped=int(len(P2)), trees=int(len(T2)), by_program=P2.block.value_counts().to_dict())
Path("gy3_cap.json").write_text(json.dumps(out, indent=1)); print(json.dumps(out))
