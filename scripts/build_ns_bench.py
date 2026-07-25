#!/usr/bin/env python3
"""
Build the Nova Scotia remeasurement benchmark inputs for the FVS-ACD (AcadianGY) multi-source
harness, matching the schema of bench_mefia_long_*.csv / magp_qcnb_*.csv already on Cardinal
(~/magplot/verify/multisrc/ and ~/magplot/verify/), so bench_parity_split_ms_v1211.R consumes
them via PAIRS_FILE/INIT_FILE/T2_FILE/SITE_FILE with NO harness change.

Inputs (local, licensed NS data -- coordinates never leave this build; only aggregates and a
safe location table are exported elsewhere):
  NS_PSP_tree.csv           operational PSPs: source,stand,plot,year,tree,dbh,ht,hcb,species,
                             CrownClass,stage,expf,SITE_INDEX  (dbh cm, ht m; stand==plot always)
  NS_PSP_research_tree.csv  research/thinning PSPs: source,stand,plot,year,tree,species,dbh,ht,
                             hcb,expf,crownclass,stage,bhage,barem,bares,fertn,fertp,fertk,TYEAR
  sample.sas7bdat           operational silviculture/treatment code per stand-year (SILVICULTU)
  psp_qplot.sas7bdat        research per-plot summaries incl. AVGTOPHTM (used as an ESI proxy
                             for research stands, which carry no SITE_INDEX field)
  NovaScotiaLatLong.csv     plot coordinates (used only for the coordinate-safe location table)

Managed/unmanaged definition (per task, reported in scorecard read-out):
  - Every NS_PSP_research_tree.csv stand is a research/thinning trial (TYEAR = treatment year on
    79% of rows) -> MANAGED = 1.
  - Operational stands (NS_PSP_tree.csv) are joined to sample.sas7bdat on (stand=PLOT_NUMBE,
    year=SAMPLE_YEA). SILVICULTU codes 99/00 = untreated/natural; 02 = not natural (non-thinning
    silviculture, e.g. planted); 05/07 = PCT; 08 = CT; 06 = unclassified non-natural code present
    in the data but undocumented in the source SAS. A stand is MANAGED = 1 if ANY sample-year
    record carries SILVICULTU in {02,05,06,07,08}; stands with only 99/00 codes, or with no
    sample record at all, are MANAGED = 0 (untreated default).

Species crosswalk: NS codes are mostly already AcadianGY (AGY) 2-letter codes (BF, RS, BS, WS,
NS, WP, RP, JP, EH, TA, RM, SM, YB, GB, WA, BA, BC, RO, ST, SB, PC, OH, OS). Non-AGY codes are
remapped to the nearest AGY code where the genus is unambiguous, else to the generic OS
(softwood) / OH (hardwood) bucket per the task's fallback rule:
  WB->PB (white/paper birch)  TL->TA (tamarack)      BE->AB (American beech)
  LA->BT (largetooth aspen)   IW->HH (ironwood)       EW->WC (eastern white cedar)
  SP->OS  EL->OS  Sk->OS  JL->OS                      (unresolved conifers -> generic softwood)
  AL,AP,CC,DR,EO,HT,MA,WE,WI,WL,OT -> OH              (unresolved/minor hardwoods incl. research
                                                        "OT" catch-all, ~9% of research rows --
                                                        flagged as a coverage caveat)
  MM->ST (mountain maple grouped with striped maple, matching the QC/NB crosswalk convention)

ESI / site index for the SITE file:
  - Operational stands: per-stand median of the non-null NS_PSP_tree.csv SITE_INDEX field
    (covers ~92% of operational stands; same units/scale as the QC/NB esi8 values, ~0-29 m).
  - Research (managed) stands: NS_PSP_tree.csv carries no SITE_INDEX field for these plots. Used
    psp_qplot.sas7bdat AVGTOPHTM (average dominant/codominant top height, m) as a proxy,
    per-stand median across all qplot records (mean 12.57 m, sd 4.88 m -- closely matches the
    operational SITE_INDEX distribution, mean 13.86 m sd 3.54 m, so used directly with no
    rescaling). This is a proxy, not a true site index; documented here and in the scorecard
    read-out. Coverage is 422/422 research stands (99.98% of qplot rows have AVGTOPHTM).
  - Stands with no ESI available at all keep esi8 blank (dropped under INDOMAIN=1 by the harness,
    as intended -- these are out-of-domain for the frozen-canon scoring run).

Pairing (mirrors ~/magplot/build_magp_qcnb.py on Cardinal): live trees = dbh present and > 0.
Per stand, sort unique measurement occasions (decoding NS's A/B sub-year codes, e.g. 19972 ->
1997, second occasion that year); pair consecutive occasions with interval_years in [4,15] and
>=3 live trees on both sides. TREE ids in the output are the source data's own tree numbers
(carried through for traceability; the scoring harness re-indexes trees internally and does not
require t1/t2 tree-id correspondence -- confirmed by inspecting bench_parity_split_ms_v1211.R,
which sets tree=seq_len(nrow(it)) and computes stand-level aggregate metrics independently on
each side of a pair, the same convention build_magp_qcnb.py uses).

Outputs (this script), written to OUTDIR (default: sandbox local, then copied/uploaded):
  bench_ns_pairs.csv       STAND,SITE,PROV,interval_years,ELEV,MANAGED  (MANAGED is an extra
                            column the harness ignores/carries through harmlessly; the two-pass
                            managed/unmanaged CANDIDATE run subsets on it locally, not on Cardinal)
  bench_ns_tree_init.csv   STAND,PLOT,TREE,SP,DBH,HT,EXPF,YEAR
  bench_ns_tree_t2.csv     STAND,PLOT,TREE,SP,DBH,HT,EXPF,YEAR
  bench_ns_site_esi.csv    SITE,esi8
"""
import pandas as pd
import numpy as np
import math
import os
import sys
import random

NS_DIR = "/sessions/fervent-pensive-goodall/mnt/Nova Scotia"
OUTDIR = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/repos/fvs-acd/figures/_data/ns_bench_build"
os.makedirs(OUTDIR, exist_ok=True)

MIN_IV, MAX_IV = 4, 15
MIN_TREES = 3
RANDOM_SEED = 2026  # matches the seed convention in ~/magplot/build_magp_qcnb.py
CAP_PER_GROUP = 2500  # tractable-run sample cap per managed/unmanaged group, same rationale as
                       # build_magp_qcnb.py's PER_PROV=2200 cap (NS raises 13,263 raw candidate
                       # pairs, far more than any prior single-source build; capped, not dropped,
                       # so the full raw pair count is still reported for transparency)
ELEV_DEFAULT = 200.0  # NS is low relief; no elevation field in the local extracts, matches the
                       # harness's own ELEV<=0/NA fallback (bench_parity_split_ms_v1211.R: elev<-
                       # if(is.finite(p$ELEV)&&p$ELEV>0)p$ELEV else 200)

# ---------------------------------------------------------------------------------------------
# species crosswalk -> AcadianGY 2-letter codes
# ---------------------------------------------------------------------------------------------
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
    return "OH"  # unseen code fallback, generic hardwood per task's default rule

def decode_year(y):
    """NS research data encodes within-year A/B sub-samples as year*10+{1,2} for 1997-2006
    (e.g. 19972 -> calendar year 1997, second occasion). Anything <3000 is already a plain
    calendar year."""
    y = int(y)
    return y // 10 if y >= 3000 else y

# ---------------------------------------------------------------------------------------------
# 1. load operational PSPs + treatment codes
# ---------------------------------------------------------------------------------------------
print("Loading NS_PSP_tree.csv ...", flush=True)
op = pd.read_csv(os.path.join(NS_DIR, "NS_PSP_tree.csv"), low_memory=False)
op = op[op["source"].notna()]
op["stand_key"] = "NS_OP_" + op["stand"].astype(int).astype(str)
op["actual_year"] = op["year"].apply(decode_year)

print("Loading sample.sas7bdat (silviculture codes) ...", flush=True)
samp = pd.read_sas(os.path.join(NS_DIR, "sample.sas7bdat"), encoding="latin1")
samp["stand"] = samp["PLOT_NUMBE"].astype(float).astype(int)
samp["SILVICULTU"] = samp["SILVICULTU"].apply(
    lambda b: b.decode("latin1").strip() if isinstance(b, (bytes, bytearray)) else str(b).strip()
)
TREATED_CODES = {"02", "05", "06", "07", "08"}
samp["is_treated"] = samp["SILVICULTU"].isin(TREATED_CODES)
op_managed = samp.groupby("stand")["is_treated"].any()
op_managed_map = {("NS_OP_" + str(int(k))): (1 if v else 0) for k, v in op_managed.items()}

# per-stand ESI (median of non-null SITE_INDEX)
op_esi = op.groupby("stand_key")["SITE_INDEX"].median(numeric_only=True)
op_esi = op_esi.dropna()
op_esi = op_esi[op_esi > 2]

# ---------------------------------------------------------------------------------------------
# 2. load research (managed/thinning) PSPs + ESI proxy from psp_qplot AVGTOPHTM
# ---------------------------------------------------------------------------------------------
print("Loading NS_PSP_research_tree.csv ...", flush=True)
rs = pd.read_csv(os.path.join(NS_DIR, "NS_PSP_research_tree.csv"), low_memory=False)
rs["stand_key"] = "NS_RS_" + rs["stand"].astype(int).astype(str)
rs["actual_year"] = rs["year"].apply(decode_year)

print("Loading psp_qplot.sas7bdat (ESI proxy for research stands) ...", flush=True)
qp = pd.read_sas(os.path.join(NS_DIR, "psp_qplot.sas7bdat"), encoding="latin1")
def key4_to_int(v):
    if isinstance(v, (bytes, bytearray)):
        v = v.decode("latin1")
    return int(str(v).strip())
qp["stand"] = qp["KEY4"].apply(key4_to_int)
qp["stand_key"] = "NS_RS_" + qp["stand"].astype(str)
rs_esi = qp.groupby("stand_key")["AVGTOPHTM"].median(numeric_only=True)
rs_esi = rs_esi.dropna()
rs_esi = rs_esi[rs_esi > 2]

esi_map = pd.concat([op_esi, rs_esi]).to_dict()

# ---------------------------------------------------------------------------------------------
# 3. build live-tree occasion lists and consecutive pairs, generic over source
# ---------------------------------------------------------------------------------------------
def build_pairs(df, managed_lookup, default_managed):
    pairs = []
    # accumulate raw numpy arrays across all pairs, concat once at the end (much faster than
    # concatenating thousands of tiny per-occasion DataFrames)
    t1_acc = {"STAND": [], "TREE": [], "SP": [], "DBH": [], "HT": [], "EXPF": [], "YEAR": []}
    t2_acc = {"STAND": [], "TREE": [], "SP": [], "DBH": [], "HT": [], "EXPF": [], "YEAR": []}

    df = df[df["dbh"].notna() & (df["dbh"] > 0) &
            df["expf"].notna() & (df["expf"] > 0)].copy()
    df["sp_agy"] = df["species"].apply(mapsp)
    df["tree_i"] = df["tree"].astype(int)
    df["dbh_f"] = df["dbh"].astype(float)
    df["ht_f"] = df["ht"].astype(float) if "ht" in df else np.nan
    df["expf_f"] = df["expf"].astype(float) if "expf" in df else np.nan

    # occasion key -> compact numpy payload, built once via groupby
    occ = {}
    for (sk, yr), g in df.groupby(["stand_key", "year"], sort=False):
        occ[(sk, yr)] = (
            g["tree_i"].to_numpy(), g["sp_agy"].to_numpy(),
            g["dbh_f"].to_numpy(), g["ht_f"].to_numpy(), g["expf_f"].to_numpy(),
        )
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

    for sk, raw_years in by_stand.items():
        raw_years = sorted(raw_years)
        if len(raw_years) < 2:
            continue
        for i in range(len(raw_years) - 1):
            y1, y2 = raw_years[i], raw_years[i + 1]
            ay1, ay2 = decode_year(y1), decode_year(y2)
            iv = ay2 - ay1
            if iv < MIN_IV or iv > MAX_IV:
                continue
            p1, p2 = occ[(sk, y1)], occ[(sk, y2)]
            if len(p1[0]) < MIN_TREES or len(p2[0]) < MIN_TREES:
                continue
            # unique STAND per pair (avoids the known magp_qcnb cross-pair tree-list collision,
            # ~5% of QC/NB stands; NS operational plots have up to 9 occasions so the same
            # collision would be far more severe here -- SITE stays plot-level for the ESI join)
            pair_id = f"{sk}_{ay1}"
            managed = managed_lookup.get(sk, default_managed)
            pairs.append({
                "STAND": pair_id, "SITE": sk, "PROV": "NS",
                "interval_years": iv, "ELEV": ELEV_DEFAULT, "MANAGED": managed,
            })
            push(t1_acc, p1, pair_id, ay1)
            push(t2_acc, p2, pair_id, ay2)

    def finalize(acc):
        if not acc["STAND"]:
            return pd.DataFrame(columns=["STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"])
        out = pd.DataFrame({
            "STAND": np.concatenate(acc["STAND"]),
            "PLOT": 1,
            "TREE": np.concatenate(acc["TREE"]),
            "SP": np.concatenate(acc["SP"]),
            "DBH": np.concatenate(acc["DBH"]),
            "HT": np.concatenate(acc["HT"]),
            "EXPF": np.concatenate(acc["EXPF"]),
            "YEAR": np.concatenate(acc["YEAR"]),
        })
        return out[["STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"]]

    return pairs, finalize(t1_acc), finalize(t2_acc)

print("Building operational pairs ...", flush=True)
op_pairs, op_t1, op_t2 = build_pairs(op, op_managed_map, default_managed=0)
print("  operational pairs:", len(op_pairs), flush=True)

print("Building research (managed) pairs ...", flush=True)
rs_managed_map = {sk: 1 for sk in rs["stand_key"].unique()}
rs_pairs, rs_t1, rs_t2 = build_pairs(rs, rs_managed_map, default_managed=1)
print("  research pairs:", len(rs_pairs), flush=True)

pairs = op_pairs + rs_pairs
pairs_df = pd.DataFrame(pairs, columns=["STAND","SITE","PROV","interval_years","ELEV","MANAGED"])
n_raw_managed = int((pairs_df.MANAGED == 1).sum())
n_raw_unmanaged = int((pairs_df.MANAGED == 0).sum())

# tractable-run cap, applied separately within managed/unmanaged so both groups survive
random.seed(RANDOM_SEED)
keep_idx = []
for mflag in (0, 1):
    idx = pairs_df.index[pairs_df.MANAGED == mflag].tolist()
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

# ESI/site file: one row per SITE (=STAND) with a value, only for stands actually in pairs
sites_needed = set(pairs_df["SITE"].unique())
site_rows = [{"SITE": sk, "esi8": round(float(esi_map[sk]), 2)} for sk in sites_needed if sk in esi_map]
site_df = pd.DataFrame(site_rows, columns=["SITE", "esi8"])

pairs_df.to_csv(os.path.join(OUTDIR, "bench_ns_pairs.csv"), index=False)
t1_df.to_csv(os.path.join(OUTDIR, "bench_ns_tree_init.csv"), index=False)
t2_df.to_csv(os.path.join(OUTDIR, "bench_ns_tree_t2.csv"), index=False)
site_df.to_csv(os.path.join(OUTDIR, "bench_ns_site_esi.csv"), index=False)

print("=== DONE ===")
print("raw candidate pairs: managed", n_raw_managed, " unmanaged", n_raw_unmanaged)
print("pairs (after tractable-run cap):", len(pairs_df), "  managed:", int((pairs_df.MANAGED==1).sum()),
      " unmanaged:", int((pairs_df.MANAGED==0).sum()))
print("t1 trees:", len(t1_df), " t2 trees:", len(t2_df))
print("sites with ESI:", len(site_df), " / stands in pairs:", len(sites_needed))
print("esi coverage:", round(100*len(site_df)/max(1,len(sites_needed)),1), "%")
