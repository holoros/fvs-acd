#!/usr/bin/env python3
"""Build the gy2 and gy2L evaluation sets (fvsacd142 bridge format) from GYDB2_ALL.sqlite for the programs added to the regional
database in November 2026 and PEI (none of them were in the reg set). Pre-registered in PREREG_GY2.md.
gy2 : one untreated remeasurement per plot, the interval closest to 10 years within 5 to 15 years (earliest on ties).
gy2L: one untreated remeasurement per plot, the longest interval of at least 20 years.
Untreated: no treatment record with t1 < YR <= t2 and no cut tree (Status 50) recorded at a visit after t1 up to t2.
Trees passed to FVS: live at t1, DBH >= 2.54 cm. Scoring floor 10 cm, or the program tag limit when larger (SBW 11.43 cm).
Site: ESI v9na (30 m Acadian draft raster, int16 x 10, m at base age 50) at the plot coordinate. UNB plots subsampled to 900 (gy2)
and 500 (gy2L), seed 20261112. Writes ~/fvsacd142/state/restricted/r0e/gy2{,L}_{pairs,trees}.csv and gy2_build.json (counts only)."""
import sqlite3, json, numpy as np, pandas as pd, rasterio
from pathlib import Path
DB = Path.home() / "gydb2/release/all/GYDB2_ALL.sqlite"; RS = Path.home() / "fvsacd142/state/restricted/r0e"
ESI = Path.home() / "fvsacd142/state/restricted/esi/2026-11-03_acadian-esi-v9na-30m_int16x10_DRAFT.tif"
PROGS = ("SBW_GIS", "PEF_MID", "PEF_PCTF", "NETN_ACAD", "AFERP_OS", "HOWLAND_INV", "HOLT_INV", "UNB_PSP16", "PE_PSP")
FLOOR = {"SBW_GIS": 11.43}; HA = 2.4710538; M2FT = 3.2808399; SEED = 20261112
c = sqlite3.connect(DB)
pl = pd.read_sql(f"select gplot, Program, juris, x, y, elev from plots where Program in {PROGS} and x is not null", c)
vi = pd.read_sql(f"select gplot, gvisit, YR from visits where Program in {PROGS}", c); vi = vi[vi.gplot.isin(pl.gplot)]
tr = pd.read_sql(f"select t.gvisit, t.Tree, t.SpeciesCD, t.DBH, t.HT, t.Status, t.Live, t.PTF from trees t join visits v using(gvisit) where v.Program in {PROGS}", c)
trt = pd.read_sql(f"select gplot, YR from treatments where Program in {PROGS}", c)
cut = tr[tr.Status == 50].gvisit.unique(); vi["cut"] = vi.gvisit.isin(cut)
vi = vi.sort_values(["gplot", "YR", "gvisit"]).drop_duplicates(["gplot", "YR"])          # one visit per plot and year
# all visit pairs per plot
pr = vi.merge(vi, on="gplot", suffixes=("1", "2")); pr = pr[pr.YR2 > pr.YR1]; pr["REMPER"] = pr.YR2 - pr.YR1
def treated(r):
    t = trt.YR[(trt.gplot == r.gplot)]; return bool(((t > r.YR1) & (t <= r.YR2)).any())
tg = set(trt.gplot); cutv = vi[vi.cut][["gplot", "YR"]]
pr["trt"] = [treated(r) if r.gplot in tg else False for r in pr.itertuples()]
cm = pr[["gplot", "YR1", "YR2"]].merge(cutv, on="gplot"); cm = cm[(cm.YR > cm.YR1) & (cm.YR <= cm.YR2)]
pr["cutin"] = pd.MultiIndex.from_frame(pr[["gplot", "YR1", "YR2"]]).isin(pd.MultiIndex.from_frame(cm[["gplot", "YR1", "YR2"]]))
ok = pr[~pr.trt & ~pr.cutin].copy()
ok["managed"] = ok.gplot.isin(tg).to_numpy() & np.array([bool((trt.YR[trt.gplot == g] <= y).any()) if g in tg else False for g, y in zip(ok.gplot, ok.YR1)])
liv = tr[(tr.Live == 1) & tr.DBH.notna()]
with rasterio.open(ESI) as r:
    v = np.array([x[0] for x in r.sample(zip(pl.x, pl.y))], float)
pl["esi"] = np.where(v == -32768, np.nan, v / 10.0)
OUT = {"plots_with_coords": int(len(pl)), "pairs_all": int(len(pr)), "pairs_untreated": int(len(ok)), "esi_missing": int(pl.esi.isna().sum())}
def build(sel, tag, ucap):
    sel = sel.merge(pl, on="gplot"); sel = sel[sel.esi.notna()]
    rng = np.random.default_rng(SEED); u = sel.gplot[sel.Program == "UNB_PSP16"].to_numpy()
    if len(u) > ucap: sel = sel[(sel.Program != "UNB_PSP16") | sel.gplot.isin(rng.choice(np.sort(u), ucap, replace=False))]
    sel = sel.sort_values("gplot").reset_index(drop=True); sel["pair_id"] = [f"{i + 1:012d}" for i in range(len(sel))]
    sel["floor"] = sel.Program.map(FLOOR).fillna(10.0)
    t1 = liv.merge(sel[["gvisit1", "pair_id", "floor"]], left_on="gvisit", right_on="gvisit1")
    t2 = liv.merge(sel[["gvisit2", "pair_id", "floor"]], left_on="gvisit", right_on="gvisit2")
    for nm, t in (("1", t1), ("2", t2)):
        a = t[t.DBH >= t.floor]; ba = (np.pi / 40000 * a.DBH ** 2 * a.PTF).groupby(a.pair_id).sum(); n = a.PTF.groupby(a.pair_id).sum()
        sel[f"obsBA{nm}"] = sel.pair_id.map(ba).fillna(0.0); sel[f"obsN{nm}"] = sel.pair_id.map(n).fillna(0.0)
    t1 = t1[t1.DBH >= 2.54]
    raw = t1.assign(b=np.pi / 40000 * t1.DBH ** 2 * t1.PTF).groupby("pair_id"); sel["rawBA1"] = sel.pair_id.map(raw.b.sum()); sel["rawN1"] = sel.pair_id.map(raw.PTF.sum())
    sel = sel[(sel.obsBA1 > 0) & sel.rawN1.notna()]
    P = pd.DataFrame({"pair_id": sel.pair_id, "t1_id": sel.gplot + "__" + sel.YR1.astype(str) + "_" + sel.YR2.astype(str), "INVYR1": sel.YR1,
                      "REMPER": sel.REMPER.astype(float), "SICOND_FVS": sel.esi * M2FT, "STDAGE": np.nan, "ASPECT": np.nan, "SLOPE": np.nan,
                      "ELEV": sel.elev * M2FT, "FORTYPCD": np.nan, "SISP_FVS": np.nan, "SITE": sel.gplot, "SET": sel.Program.str.lower(),
                      "block": sel.Program, "JURIS": sel.juris, "MANAGED": sel.managed.astype(int), "SCORE_MINDBH": sel.floor,
                      "obsBA1": sel.obsBA1, "obsBA2": sel.obsBA2, "obsN1": sel.obsN1, "obsN2": sel.obsN2, "rawBA1": sel.rawBA1, "rawN1": sel.rawN1,
                      "BA_T1": sel.obsBA1, "BA_T2": sel.obsBA2, "TPH_T1": sel.obsN1, "TPH_T2": sel.obsN2, "si_src": "v9na_30m_draft"})
    t1 = t1[t1.pair_id.isin(P.pair_id)]
    T = pd.DataFrame({"pair_id": t1.pair_id, "tree_cn": t1.Tree.astype(str), "SPCD": t1.SpeciesCD.map(SP).astype(int), "DIA": t1.DBH / 2.54,
                      "HT": t1.HT * M2FT, "CR": np.nan, "TPA_UNADJ": t1.PTF / HA, "DRYBIO_AG": 0.0})
    P.to_csv(RS / f"{tag}_pairs.csv", index=False); T.to_csv(RS / f"{tag}_trees.csv", index=False)
    OUT[tag] = dict(pairs=int(len(P)), trees=int(len(T)), by_program=P.block.value_counts().to_dict(), by_juris=P.JURIS.value_counts().to_dict(),
                    remper_mean=round(float(P.REMPER.mean()), 2), remper_range=[int(P.REMPER.min()), int(P.REMPER.max())], managed=int(P.MANAGED.sum()),
                    esi_m_mean=round(float(sel.esi.mean()), 2), ba1_mean=round(float(P.obsBA1.mean()), 2), ba2_mean=round(float(P.obsBA2.mean()), 2),
                    ht_share=round(float(T.HT.notna().mean()), 3))
rs = pd.read_csv(str(Path.home() / "jobs/bakuzis_fvsconus_20261027/repos/fvs-modern/data/NSBE/REF_SPECIES.csv"), usecols=["SPCD", "SPECIES_SYMBOL"]).dropna()
SP = dict(zip(rs.SPECIES_SYMBOL, rs.SPCD.astype(int)))
SP.update({"ACER": 310, "PICEA": 90, "LARIX": 70, "POPUL": 740, "QUERC": 800, "ULMUS": 970, "SALIX": 920, "ALNUS": 350, "MALUS": 660,
           "AMELA": 356, "T_X": 998, "PINUS": 100, "ABIES": 10, "BETUL": 370, "FRAXI": 540, "PRUNU": 760, "SORBU": 935, "THUJA": 241, "TSUGA": 260})
liv = liv[liv.gvisit.isin(set(vi.gvisit))]; um = sorted(set(liv.SpeciesCD) - set(SP)); OUT["species_unmapped"] = um
liv = liv[liv.SpeciesCD.isin(SP)]
c10 = ok[(ok.REMPER >= 5) & (ok.REMPER <= 15)].assign(d=lambda d: (d.REMPER - 10).abs()).sort_values(["gplot", "d", "YR1"]).drop_duplicates("gplot")
build(c10, "gy2", 900)
cL = ok[ok.REMPER >= 20].sort_values(["gplot", "REMPER", "YR1"], ascending=[True, False, True]).drop_duplicates("gplot")
build(cL, "gy2L", 500)
Path("gy2_build.json").write_text(json.dumps(OUT, indent=1)); print(json.dumps(OUT, indent=1))
