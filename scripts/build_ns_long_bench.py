#!/usr/bin/env python3
"""
NS benchmark, second pass, Task 2: long-interval (first-to-last) remeasurement pairs on
undisturbed plots, plus a medium-interval consecutive-pair set in the same run, plus a separate
single-regime managed long-interval set -- all in the bench_ns_long_* schema so
bench_parity_split_ms_v1211.R consumes them via PAIRS_FILE/INIT_FILE/T2_FILE/SITE_FILE with no
harness change (same convention as build_ns_bench.py, pass 1).

Philosophy (principle 14): use every valid remeasurement interval INCLUDING first-to-last on
undisturbed plots, not just short/medium consecutive pairs, to expose long-horizon bias. NS is
the region's longest CFI (1965-present, up to 9 occasions/plot), so it is the one dataset that
can actually test this.

Disturbance screening (must precede any first-to-last pairing -- a "long interval" that silently
includes a harvest in the middle is not a long-horizon growth test, it is a mislabeled harvest
response). Two independent layers, deliberately redundant since NS_PSP_tree.csv itself carries no
tree-status field (see below):

  1. Stand-year SILVICULTU code (sample.sas7bdat), same convention as build_ns_bench.py:
     TREATED_CODES = {02,05,06,07,08} (thinning/PCT/CT/non-natural); 99/00 = untreated/natural.
  2. Tree-level TREE_STATU from the RAW tree.sas7bdat table (NOT the merged NS_PSP_tree.csv,
     which drops TREE_STATU/CAUSE_OF_D entirely -- confirmed this session by a full-row-count
     join back to tree.sas7bdat: NS_PSP_tree.csv passes through all 584,965 raw rows in the same
     status mix, live/dead/cut/ingrowth alike, with no filter). Protocol PDF (page 18):
     TREE_STATU 1=Live, 2=Dead standing, 3=Ingrowth, 4=Cut, 5=Dead down. TREE_STATU==4 ("Cut" --
     harvested or mechanically severed) is a removal, never mortality, and its presence in a
     stand-year is itself independent evidence of a disturbance event whether or not SILVICULTU
     flagged it. A stand-year with any TREE_STATU==4 tree is treated as an additional disturbance
     year on top of the SILVICULTU screen.

A pair (occasion i -> occasion j, i<j) is UNDISTURBED iff no disturbance year t (from either
layer) satisfies year_i <= t <= year_j (inclusive on both ends -- conservative; a treatment
recorded at the start occasion is treated as having already touched that interval, per principle
6, measurement quality first).

Research (thinning-trial) stands are always managed (psp_trt.sas7bdat TYEAR, present for 77% of
NS_PSP_research_tree.csv rows and effectively a fixed per-stand attribute -- confirmed the
observed TYEAR is constant within stand across measurement years in the sample checked). Their
long intervals are built the same way but scored SEPARATELY as "managed, single-regime": a run of
occasions is kept only while the stand's distinct TYEAR set does not change (i.e. no second,
different treatment event partway through -- handles the rare multi-entry KEY4 case; the common
case is one TYEAR for the stand's whole record, so nearly all research first-to-last pairs qualify
as single-regime by construction).

Site index: uses the Task 1 corrected NS site input (raw NS SITE_INDEX / AVGTOPHTM + the
documented +7.0 m ESI v8 raster positive-bias correction, see build_ns_site_correction.py) as the
PRIMARY site_esi file for this long-interval set, per task instruction. The raw (uncorrected)
variant is also written for sensitivity checks.

Pair types (column PAIR_TYPE in bench_ns_long_pairs.csv):
  CONSECUTIVE  - occasion i -> occasion i+1 within an undisturbed/single-regime run (no interval
                 cap this time, unlike pass 1's 4-15yr cap -- NS's natural remeasurement cycle is
                 ~5-10 yr so most of these land <15yr, some land in 15-30yr where a gap exists).
  FIRST_LAST   - first occasion -> last occasion of an undisturbed/single-regime run, only emitted
                 when the run has >=3 occasions (so it differs from the lone CONSECUTIVE pair a
                 2-occasion run would already produce).

Outputs (OUTDIR, matching bench_ns_long_{pairs,tree_init,tree_t2,site_esi}.csv):
  bench_ns_long_pairs.csv        STAND,SITE,PROV,interval_years,ELEV,MANAGED,PAIR_TYPE,SINGLE_REGIME
  bench_ns_long_tree_init.csv    STAND,PLOT,TREE,SP,DBH,HT,EXPF,YEAR
  bench_ns_long_tree_t2.csv      STAND,PLOT,TREE,SP,DBH,HT,EXPF,YEAR
  bench_ns_long_site_esi.csv     SITE,esi8              (corrected, primary)
  bench_ns_long_site_esi_raw.csv SITE,esi8              (uncorrected, sensitivity)
"""
import pandas as pd
import numpy as np
import os
import random

NS_DIR = "/sessions/fervent-pensive-goodall/mnt/Nova Scotia"
OUTDIR = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/repos/fvs-acd/figures/_data/ns_bench_build"
os.makedirs(OUTDIR, exist_ok=True)

MIN_TREES = 3
RANDOM_SEED = 2026
CAP_PER_GROUP = 3000          # tractable-run cap, applied per (MANAGED, PAIR_TYPE) group
ELEV_DEFAULT = 200.0
ESI8_RASTER_BIAS_M = 7.0      # Task 1 correction, see build_ns_site_correction.py

TREATED_CODES = {"02", "05", "06", "07", "08"}
CUT_STATUS = 4
CUT_STATUS_STR = str(CUT_STATUS)  # "4" -- TREE_STATU is a decoded string column, see BUGFIX below

AGY_DIRECT = {
    "BA","BC","BF","BP","BS","EH","GB","JP","NS","OH","OS","PC","RM","RO","RP","RS",
    "SB","SM","ST","TA","WA","WP","WS","YB",
}
REMAP = {
    "WB":"PB","TL":"TA","BE":"AB","LA":"BT","IW":"HH","EW":"WC",
    "SP":"OS","EL":"OS","SK":"OS","JL":"OS",
    "AL":"OH","AP":"OH","CC":"OH","DR":"OH","EO":"OH","HT":"OH","MA":"OH",
    "WE":"OH","WI":"OH","WL":"OH","OT":"OH","MM":"ST",
}
def mapsp(code):
    if pd.isna(code):
        return "OH"
    c = str(code).strip().upper()
    if c in AGY_DIRECT:
        return c
    if c in REMAP:
        return REMAP[c]
    return "OH"

def decode_year(y):
    y = int(y)
    return y // 10 if y >= 3000 else y

# -------------------------------------------------------------------------------------------
# 1. operational: load trees, silviculture codes, and the raw TREE_STATU cut-screen
# -------------------------------------------------------------------------------------------
print("Loading NS_PSP_tree.csv ...", flush=True)
op = pd.read_csv(os.path.join(NS_DIR, "NS_PSP_tree.csv"), low_memory=False)
op = op[op["source"].notna()].copy()
op["stand_key"] = "NS_OP_" + op["stand"].astype(int).astype(str)
op["actual_year"] = op["year"].apply(decode_year)

print("Loading sample.sas7bdat (silviculture codes) ...", flush=True)
samp = pd.read_sas(os.path.join(NS_DIR, "sample.sas7bdat"), encoding="latin1")
samp["stand"] = samp["PLOT_NUMBE"].astype(float).astype(int)
samp["SILVICULTU"] = samp["SILVICULTU"].apply(
    lambda b: b.decode("latin1").strip() if isinstance(b, (bytes, bytearray)) else str(b).strip())
samp["SAMPLE_YEA"] = samp["SAMPLE_YEA"].astype(float).astype(int)
samp["is_treated"] = samp["SILVICULTU"].isin(TREATED_CODES)
silv_dist_years = (samp[samp.is_treated]
                    .groupby("stand")["SAMPLE_YEA"].apply(lambda s: set(int(v) for v in s)))

print("Loading tree.sas7bdat (raw TREE_STATU, cut-tree screen) ...", flush=True)
raw = pd.read_sas(os.path.join(NS_DIR, "tree.sas7bdat"), encoding="latin1")
raw["PLOT_NUMBE"] = raw["PLOT_NUMBE"].astype(float).astype(int)
raw["SAMPLE_YEA"] = raw["SAMPLE_YEA"].astype(float).astype(int)
# BUGFIX 2026-07-22 (redteam round 2, blocker #1): pd.read_sas returns TREE_STATU as bytes/str
# ('1'..'5' or b'1'..b'5'), never as the Python int 4, so the old `raw["TREE_STATU"] == CUT_STATUS`
# comparison was always False and the tree-level cut screen never fired (0 rows dropped, every run).
# Decode to a stripped string and compare as string against CUT_STATUS_STR ("4").
raw["TREE_STATU_STR"] = raw["TREE_STATU"].apply(
    lambda v: v.decode("latin1").strip() if isinstance(v, (bytes, bytearray)) else str(v).strip())
cut_years = (raw[raw["TREE_STATU_STR"] == CUT_STATUS_STR]
             .groupby("PLOT_NUMBE")["SAMPLE_YEA"].apply(lambda s: set(int(v) for v in s)))

# combined per-stand disturbance year set (operational)
op_stands = sorted(op["stand"].dropna().astype(int).unique())
op_dist_years = {}
for s in op_stands:
    ys = set()
    if s in silv_dist_years.index:
        ys |= silv_dist_years.loc[s]
    if s in cut_years.index:
        ys |= cut_years.loc[s]
    op_dist_years[s] = ys
n_stands_with_cut_not_silv = sum(
    1 for s in op_stands
    if s in cut_years.index and not (cut_years.loc[s] & silv_dist_years.get(s, set()))
)
print(f"  operational stands: {len(op_stands)}; stands with a TREE_STATU=4 cut year not already "
      f"flagged by SILVICULTU: {n_stands_with_cut_not_silv}", flush=True)

op_esi_raw = op.groupby("stand_key")["SITE_INDEX"].median(numeric_only=True).dropna()
op_esi_raw = op_esi_raw[op_esi_raw > 2]

# -------------------------------------------------------------------------------------------
# 2. research: load trees, TYEAR (single-regime marker), ESI proxy
# -------------------------------------------------------------------------------------------
print("Loading NS_PSP_research_tree.csv ...", flush=True)
rs = pd.read_csv(os.path.join(NS_DIR, "NS_PSP_research_tree.csv"), low_memory=False)
rs["stand_key"] = "NS_RS_" + rs["stand"].astype(int).astype(str)
rs["actual_year"] = rs["year"].apply(decode_year)

print("Loading psp_qplot.sas7bdat (ESI proxy) ...", flush=True)
qp = pd.read_sas(os.path.join(NS_DIR, "psp_qplot.sas7bdat"), encoding="latin1")
def key4_to_int(v):
    if isinstance(v, (bytes, bytearray)):
        v = v.decode("latin1")
    return int(str(v).strip())
qp["stand"] = qp["KEY4"].apply(key4_to_int)
qp["stand_key"] = "NS_RS_" + qp["stand"].astype(str)
rs_esi_raw = qp.groupby("stand_key")["AVGTOPHTM"].median(numeric_only=True).dropna()
rs_esi_raw = rs_esi_raw[rs_esi_raw > 2]

esi_map_raw = pd.concat([op_esi_raw, rs_esi_raw]).to_dict()
esi_map_corrected = {k: v + ESI8_RASTER_BIAS_M for k, v in esi_map_raw.items()}

print("Loading psp_trt.sas7bdat (research TYEAR, single-regime check) ...", flush=True)
trt = pd.read_sas(os.path.join(NS_DIR, "psp_trt.sas7bdat"), encoding="latin1")
def key4_int(v):
    if isinstance(v, (bytes, bytearray)):
        v = v.decode("latin1")
    return int(str(v).strip())
trt["stand"] = trt["KEY4"].apply(key4_int)
trt["TYEAR_f"] = pd.to_numeric(trt["TYEAR"], errors="coerce")
rs_tyears = trt.groupby("stand")["TYEAR_f"].apply(lambda s: sorted(set(int(v) for v in s.dropna())))
rs_multi_regime_stands = set(s for s, ys in rs_tyears.items() if len(ys) > 1)
print(f"  research stands: {trt['stand'].nunique()}; multi-TYEAR (>1 distinct treatment year) "
      f"stands excluded from single-regime long pairs: {len(rs_multi_regime_stands)}", flush=True)
# research disturbance-year set used ONLY to segment single-regime runs: treat every TYEAR beyond
# the first as a new disturbance boundary (so a run never straddles two different treatments)
rs_dist_years = {}
for s, ys in rs_tyears.items():
    rs_dist_years[s] = set(ys[1:]) if len(ys) > 1 else set()

# -------------------------------------------------------------------------------------------
# 3. generic occasion-run builder: segments a stand's sorted occasions into maximal runs with no
#    intervening disturbance year, then emits CONSECUTIVE pairs (every step) and one FIRST_LAST
#    pair per run of >=3 occasions.
# -------------------------------------------------------------------------------------------
def build_long_pairs(df, dist_years_lookup, managed_flag, key_field="stand"):
    pairs = []
    t1_acc = {"STAND": [], "TREE": [], "SP": [], "DBH": [], "HT": [], "EXPF": [], "YEAR": []}
    t2_acc = {"STAND": [], "TREE": [], "SP": [], "DBH": [], "HT": [], "EXPF": [], "YEAR": []}

    df = df[df["dbh"].notna() & (df["dbh"] > 0) & df["expf"].notna() & (df["expf"] > 0)].copy()
    df["sp_agy"] = df["species"].apply(mapsp)
    df["tree_i"] = df["tree"].astype(int)
    df["dbh_f"] = df["dbh"].astype(float)
    df["ht_f"] = df["ht"].astype(float) if "ht" in df else np.nan
    df["expf_f"] = df["expf"].astype(float) if "expf" in df else np.nan

    occ = {}
    for (sk, yr), g in df.groupby(["stand_key", "year"], sort=False):
        occ[(sk, yr)] = (g["tree_i"].to_numpy(), g["sp_agy"].to_numpy(), g["dbh_f"].to_numpy(),
                         g["ht_f"].to_numpy(), g["expf_f"].to_numpy())
    by_stand = {}
    for (sk, yr) in occ:
        by_stand.setdefault(sk, []).append(yr)

    def push(acc, payload, pair_id, yr):
        tree, sp, dbh, ht, expf = payload
        n = len(tree)
        acc["STAND"].append(np.full(n, pair_id, dtype=object))
        acc["TREE"].append(tree)
        acc["SP"].append(sp)
        acc["DBH"].append(np.round(dbh, 2))
        ht_out = np.where(np.isfinite(ht) & (ht > 0), np.round(ht, 3), np.nan)
        acc["HT"].append(ht_out)
        acc["EXPF"].append(np.round(expf, 4))
        acc["YEAR"].append(np.full(n, yr, dtype=int))

    n_runs = 0
    for sk, raw_years in by_stand.items():
        raw_years = sorted(raw_years)
        if len(raw_years) < 2:
            continue
        stand_num = int(sk.split("_")[-1])
        dyears = dist_years_lookup.get(stand_num, set())
        actual_years = [decode_year(y) for y in raw_years]

        # segment into maximal runs with no disturbance year in (run_start, run_end] window as we
        # extend; simplest correct construction: start a new run whenever the year we're about to
        # add is <= a disturbance year that is > the run's current last actual year and <= the
        # candidate year (i.e. a disturbance occurred between the previous occasion and this one)
        runs = []
        cur_run = [0]
        for idx in range(1, len(raw_years)):
            prev_ay = actual_years[idx - 1]
            this_ay = actual_years[idx]
            crossed = any(prev_ay < d <= this_ay for d in dyears) or (this_ay in dyears and prev_ay == this_ay)
            # also break if the SAME occasion year itself is a disturbance year and it's the very
            # first occasion of what would be a new run (conservative: a disturbance-year occasion
            # cannot anchor a new "undisturbed" run either)
            if crossed:
                runs.append(cur_run)
                cur_run = [idx]
            else:
                cur_run.append(idx)
        runs.append(cur_run)
        # drop any run whose own anchor occasion year is itself a disturbance year (edge case:
        # first occasion overall coincides with a treatment record)
        runs = [r for r in runs if actual_years[r[0]] not in dyears]

        for run in runs:
            if len(run) < 2:
                continue
            n_runs += 1
            # CONSECUTIVE pairs
            for k in range(len(run) - 1):
                i, j = run[k], run[k + 1]
                y1, y2 = raw_years[i], raw_years[j]
                ay1, ay2 = actual_years[i], actual_years[j]
                iv = ay2 - ay1
                if iv < 1:
                    continue
                p1, p2 = occ[(sk, y1)], occ[(sk, y2)]
                if len(p1[0]) < MIN_TREES or len(p2[0]) < MIN_TREES:
                    continue
                pair_id = f"{sk}_{ay1}_{ay2}_C"
                pairs.append({"STAND": pair_id, "SITE": sk, "PROV": "NS", "interval_years": iv,
                               "ELEV": ELEV_DEFAULT, "MANAGED": managed_flag,
                               "PAIR_TYPE": "CONSECUTIVE", "SINGLE_REGIME": 1})
                push(t1_acc, p1, pair_id, ay1); push(t2_acc, p2, pair_id, ay2)
            # FIRST_LAST pair, only if run has >=3 occasions (else identical to the lone
            # consecutive pair above)
            if len(run) >= 3:
                i, j = run[0], run[-1]
                y1, y2 = raw_years[i], raw_years[j]
                ay1, ay2 = actual_years[i], actual_years[j]
                iv = ay2 - ay1
                if iv >= 1:
                    p1, p2 = occ[(sk, y1)], occ[(sk, y2)]
                    if len(p1[0]) >= MIN_TREES and len(p2[0]) >= MIN_TREES:
                        pair_id = f"{sk}_{ay1}_{ay2}_FL"
                        pairs.append({"STAND": pair_id, "SITE": sk, "PROV": "NS",
                                      "interval_years": iv, "ELEV": ELEV_DEFAULT,
                                      "MANAGED": managed_flag, "PAIR_TYPE": "FIRST_LAST",
                                      "SINGLE_REGIME": 1})
                        push(t1_acc, p1, pair_id, ay1); push(t2_acc, p2, pair_id, ay2)

    def finalize(acc):
        if not acc["STAND"]:
            return pd.DataFrame(columns=["STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"])
        out = pd.DataFrame({"STAND": np.concatenate(acc["STAND"]), "PLOT": 1,
                             "TREE": np.concatenate(acc["TREE"]), "SP": np.concatenate(acc["SP"]),
                             "DBH": np.concatenate(acc["DBH"]), "HT": np.concatenate(acc["HT"]),
                             "EXPF": np.concatenate(acc["EXPF"]), "YEAR": np.concatenate(acc["YEAR"])})
        return out[["STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"]]

    print(f"  undisturbed/single-regime runs found: {n_runs}", flush=True)
    return pairs, finalize(t1_acc), finalize(t2_acc)

print("Building operational (unmanaged, disturbance-screened) long/medium pairs ...", flush=True)
op_pairs, op_t1, op_t2 = build_long_pairs(op, op_dist_years, managed_flag=0)
print("  operational pairs:", len(op_pairs), flush=True)

print("Building research (managed, single-regime) long/medium pairs ...", flush=True)
rs_pairs, rs_t1, rs_t2 = build_long_pairs(rs, rs_dist_years, managed_flag=1)
print("  research pairs:", len(rs_pairs), flush=True)

pairs = op_pairs + rs_pairs
pairs_df = pd.DataFrame(pairs, columns=["STAND","SITE","PROV","interval_years","ELEV","MANAGED",
                                         "PAIR_TYPE","SINGLE_REGIME"])

# mark research pairs from multi-TYEAR stands as SINGLE_REGIME=0 (excluded from the "single
# regime" managed long set downstream, kept in the raw file for transparency)
def is_multi_regime(site):
    if not site.startswith("NS_RS_"):
        return False
    return int(site.split("_")[-1]) in rs_multi_regime_stands
pairs_df.loc[pairs_df["SITE"].apply(is_multi_regime), "SINGLE_REGIME"] = 0

n_raw = {(m, t): int(((pairs_df.MANAGED == m) & (pairs_df.PAIR_TYPE == t)).sum())
         for m in (0, 1) for t in ("CONSECUTIVE", "FIRST_LAST")}
print("raw counts by (MANAGED, PAIR_TYPE):", n_raw, flush=True)

random.seed(RANDOM_SEED)
keep_idx = []
for m in (0, 1):
    for t in ("CONSECUTIVE", "FIRST_LAST"):
        idx = pairs_df.index[(pairs_df.MANAGED == m) & (pairs_df.PAIR_TYPE == t)].tolist()
        if len(idx) > CAP_PER_GROUP:
            idx = sorted(random.sample(idx, CAP_PER_GROUP))
        keep_idx.extend(idx)
pairs_df = pairs_df.loc[sorted(keep_idx)].reset_index(drop=True)
keep_stands = set(pairs_df["STAND"])

t1_df = pd.concat([op_t1, rs_t1], ignore_index=True)
t2_df = pd.concat([op_t2, rs_t2], ignore_index=True)
t1_df = t1_df[t1_df["STAND"].isin(keep_stands)].reset_index(drop=True)
t2_df = t2_df[t2_df["STAND"].isin(keep_stands)].reset_index(drop=True)
t1_df["HT"] = t1_df["HT"].apply(lambda v: "" if pd.isna(v) else v)
t2_df["HT"] = t2_df["HT"].apply(lambda v: "" if pd.isna(v) else v)

sites_needed = set(pairs_df["SITE"].unique())
site_rows_corr = [{"SITE": sk, "esi8": round(float(esi_map_corrected[sk]), 2)}
                   for sk in sites_needed if sk in esi_map_corrected]
site_rows_raw = [{"SITE": sk, "esi8": round(float(esi_map_raw[sk]), 2)}
                  for sk in sites_needed if sk in esi_map_raw]
site_df_corr = pd.DataFrame(site_rows_corr, columns=["SITE", "esi8"])
site_df_raw = pd.DataFrame(site_rows_raw, columns=["SITE", "esi8"])

pairs_df.to_csv(os.path.join(OUTDIR, "bench_ns_long_pairs.csv"), index=False)
t1_df.to_csv(os.path.join(OUTDIR, "bench_ns_long_tree_init.csv"), index=False)
t2_df.to_csv(os.path.join(OUTDIR, "bench_ns_long_tree_t2.csv"), index=False)
site_df_corr.to_csv(os.path.join(OUTDIR, "bench_ns_long_site_esi.csv"), index=False)
site_df_raw.to_csv(os.path.join(OUTDIR, "bench_ns_long_site_esi_raw.csv"), index=False)

# convenience subsets (mirrors bench_ns_pairs_{managed,unmanaged}.csv from pass 1)
pairs_df[(pairs_df.MANAGED == 0) & (pairs_df.PAIR_TYPE == "FIRST_LAST")].to_csv(
    os.path.join(OUTDIR, "bench_ns_long_pairs_unmanaged_firstlast.csv"), index=False)
pairs_df[(pairs_df.MANAGED == 1) & (pairs_df.SINGLE_REGIME == 1) & (pairs_df.PAIR_TYPE == "FIRST_LAST")].to_csv(
    os.path.join(OUTDIR, "bench_ns_long_pairs_managed_singleregime_firstlast.csv"), index=False)
pairs_df[pairs_df.MANAGED == 0].to_csv(os.path.join(OUTDIR, "bench_ns_long_pairs_unmanaged.csv"), index=False)
pairs_df[(pairs_df.MANAGED == 1) & (pairs_df.SINGLE_REGIME == 1)].to_csv(
    os.path.join(OUTDIR, "bench_ns_long_pairs_managed_singleregime.csv"), index=False)

print("=== DONE ===")
print("pairs (after tractable-run cap):", len(pairs_df))
print(pairs_df.groupby(["MANAGED","PAIR_TYPE"]).size())
print("interval_years distribution (FIRST_LAST only):")
fl = pairs_df[pairs_df.PAIR_TYPE == "FIRST_LAST"]
print(fl["interval_years"].describe())
print("t1 trees:", len(t1_df), " t2 trees:", len(t2_df))
print("sites with corrected ESI:", len(site_df_corr), " / stands in pairs:", len(sites_needed))
