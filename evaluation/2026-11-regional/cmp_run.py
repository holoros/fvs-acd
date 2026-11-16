#!/usr/bin/env python3
"""Comparator arms for the gy2, gy2L, t14H and bakz evaluation sets (PREREG_GY2 Amendment 3).

Arms
  fvs_base     native FVS-NE (fvs-modern build 9c99ff1 on firebreather), no calibration keywords
  fvs_regional native FVS-NE plus the fvs-modern NE calibrated keyword set (SDIMAX, MORTMULT, BAIMULT; generated on
               Cardinal from ~/fvs-modern/config, md5 in meta)
  conus_spdep  native FVS-NE with the fvs-conus hooks exactly as run_5model_scorecard_cohort.py sets them: Greg height
               growth (compound_none), crown change, GOMPIT size_bgi mortality, Greg DG off (FVS_GREGDG=0)
  osm          OSM 2.26.1 Acadian (perseus_me track D pins), years per cycle = largest divisor of REMPER up to 10 (OSM limit), one extra cycle run, the cycle at REMPER read, BGI from the 5 nearest
               plots of the BGI lookup by plot coordinates (bakz: BGI matched to the ESI grid value by quantile)

FVS arms reuse the production arm's base keyfile for each pair (same trees, STDINFO, SITECODE, DESIGN), drop its TIMEINT
and NUMCYCLE lines and write annual cycles (cycle length ceil(REMPER/40) when REMPER > 40; bakz: 5 year cycles).
Output per pair: restricted/batch/<run>/all/P<sid>/fvsout.db with FVS_TreeList (Year, TPA, DBH, Ht, SpeciesFIA), the layout
vol_score.py and bakz_traj.py read.
"""
import argparse, hashlib, json, math, os, shutil, sqlite3, subprocess, sys, tempfile, time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
import numpy as np
import pandas as pd

H = Path.home(); S = H / "fvsacd142/state/restricted"; J = H / "jobs/gy2eval_20261112"
FVSNE = H / "jobs/fvs-build-9c99ff1/bin-v1_9c99ff1_fb/FVSne"
COEF = J / "cmp/coef"; CALKW = J / "ne_calibrated_kw.txt"
ENGD = H / "perseus_me/me_state/v23_D/work/eng"
OSM = ENGD / "osm/OSM.ConsoleApp"; XW = ENGD / "osmwork/acadian_species_crosswalk.csv"; BGI = ENGD / "osmwork/acd_plt_cn_lookup_with_bgi_csi.csv"
PINS = dict(osm="6ae5235b50019dd80fa253ed284b27c9", xwalk="973eec6704576d56a14dc32a7fe2685f", bgi="393658e9a6fb933d3f518af135b328a3")
HA = 2.4710538; FT = 0.3048
SETS = {  # pairs, trees, production base keyfiles
    "gy2": (S / "r0e/gy2_pairs.csv", S / "r0e/gy2_trees.csv", S / "batch/gyp_gy2/all"),
    "gy2L": (S / "r0e/gy2L_pairs.csv", S / "r0e/gy2L_trees.csv", S / "batch/gyp_gy2L/all"),
    "gy3": (S / "r0e/gy3_pairs.csv", S / "r0e/gy3_trees.csv", S / "batch/gyp_gy3/all"),
    "gy3L": (S / "r0e/gy3L_pairs.csv", S / "r0e/gy3L_trees.csv", S / "batch/gyp_gy3L/all"),
    "t14H": (S / "t14/g2_pairs.csv", S / "t14/g2_trees.csv", S / "batch/t14H_prod_fix/all"),
    "bakz": (S / "r0e/bakz_pairs.csv", S / "r0e/bakz_trees.csv", S / "batch/bkp/all"),
    "reg": (S / "r0e/reg_pairs.csv", S / "r0e/reg_trees.csv", S / "batch/r0e_reg_prod_fix/all"),
}
ENV = {
    "fvs_base": {}, "fvs_regional": {},
    "conus_spdep": {"FVS_GREGHG": "1", "FVS_GREG_TD": "28", "FVS_GREG_EMT": "-30", "FVS_GREG_ELEV": "1000",
                    "FVS_GREG_MCW_COEF": str(COEF / "greg_mcw_coefficients.csv"),
                    "FVS_GREGHG_COEF": str(COEF / "greg_hg_coefficients_compound_none.csv"),
                    "FVS_GREGDG": "0", "FVS_GREGDG_COEF": str(COEF / "greg_dg_coefficients.csv"), "FVS_GREG_DD0": "1600",
                    "FVS_GREG_PPT_SM": "230", "FVS_GREG_DD18": "3500",
                    "FVS_GREGCRW": "1", "FVS_GREGCRW_COEF": str(COEF / "greg_crown_change_coefficients.csv"),
                    "FVS_GOMPIT": "1", "FVS_GOMPIT_COEF": str(COEF / "greg_mortality_coefficients_size_bgi.csv")},
}


def md5(p):
    return hashlib.md5(Path(p).read_bytes()).hexdigest()


def cycles(R, setname):
    R = int(round(R))
    if setname == "bakz":
        return [5] * (R // 5) + ([R % 5] if R % 5 else [])
    L = max(1, math.ceil(R / 40)); n = math.ceil(R / L); first = R - (n - 1) * L
    return [first] + [L] * (n - 1)


def fvs_key(base, R, setname, calkw):
    out = []
    for ln in base.read_text().splitlines():
        if ln.startswith(("TIMEINT", "NUMCYCLE")):
            continue
        if ln.startswith("PROCESS") and calkw:
            out.append(calkw.rstrip("\n"))
        out.append(ln)
        if ln.startswith("INVYEAR"):
            cy = cycles(R, setname); out.append(f"NUMCYCLE    {len(cy):>10.1f}")
            L = max(set(cy), key=cy.count); out.append(f"TIMEINT   {0:>10}{L:>10}")
            for i, c in enumerate(cy, 1):
                if c != L:
                    out.append(f"TIMEINT   {i:>10}{c:>10}")
    return "\n".join(out) + "\n"


def fvs_one(job):
    sid, R, setname, arm, base, outdir, calkw = job
    d = Path(outdir) / f"P{sid}"
    if (d / "DONE").exists():
        return sid, "skip"
    d.mkdir(parents=True, exist_ok=True)
    for f in d.iterdir():
        f.unlink()
    (d / "s.key").write_text(fvs_key(Path(base), R, setname, calkw))
    env = os.environ.copy(); env.update(ENV[arm])
    try:
        r = subprocess.run([str(FVSNE), "--keywordfile=s.key"], cwd=d, env=env, capture_output=True, text=True, timeout=300)
        con = sqlite3.connect(str(d / "fvsout.db")); n = con.execute("select count(distinct Year) from FVS_TreeList").fetchone()[0]; con.close()
        ok = n == len(cycles(R, setname)) + 1
        (d / "DONE").write_text(f"rc {r.returncode} years {n}\n")
        for f in ("fort.13",):
            (d / f).unlink(missing_ok=True)
        return sid, ("ok" if ok else f"years {n}")
    except Exception as e:
        return sid, f"error {type(e).__name__}: {e}"[:200]


def load_xwalk():
    x = pd.read_csv(XW, dtype=str)
    x["FIA"] = pd.to_numeric(x["FIA"], errors="coerce"); x["key"] = x["OSM_AD_CmdKey"].str.strip().str.upper()
    x["inm"] = pd.to_numeric(x["In Model"], errors="coerce").fillna(0).astype(int); x = x[x.FIA > 0]
    fw = {int(f): (k if m == 1 else ("OS" if str(g).strip() == "SW" else "OH")) for f, k, m, g in zip(x.FIA, x.key, x.inm, x.SpeciesGrp)}
    rev = {}
    for f, k, m in sorted(zip(x.FIA.astype(int), x.key, x.inm)):
        if m == 1:
            rev.setdefault(k, f)
    rev.update({"OS": 299, "OH": 998})
    return fw, rev


def bgi_for(P, setname):
    L = pd.read_csv(BGI, usecols=["LAT", "LON", "BGI"]); L = L[pd.to_numeric(L.BGI, errors="coerce") > 0]
    if setname == "bakz":   # quantile match of the ESI grid value to the BGI distribution, using the gy2 + gy2L + t14 ESI frame
        fr = pd.concat([pd.read_csv(SETS[s][0], usecols=["SICOND_FVS"]) for s in ("gy2", "gy2L", "t14H")]).SICOND_FVS * FT
        q = np.array([(fr <= v).mean() for v in P.SICOND_FVS * FT])
        return np.round(np.quantile(L.BGI, np.clip(q, 0.001, 0.999))).astype(int), "esi_quantile"
    c = sqlite3.connect(str(H / "gydb2/release/all/GYDB2_ALL.sqlite"))
    pl = pd.read_sql("select gplot, x as lon, y as lat from plots where x is not null", c).drop_duplicates("gplot").set_index("gplot")
    if setname == "reg":   # regional frame SITE keys (e.g. PEF__PEF_10_13, CTRN__CTRN_AP_101, MNAP__Block_Loc_Plot) to GYDB2 plots
        import re
        cln = lambda v: re.sub(r"[^A-Za-z0-9]", "", str(v)).upper()
        q = pd.read_sql("select gplot, Program, Block, Location, Plot, x as lon, y as lat from plots where x is not null "
                        "and Program in ('PEF_CFI','CFRU_CTRN','MNAP_ERN')", c)
        km = {}
        for r in q.itertuples():
            if r.Program == "MNAP_ERN":
                km[("MNAP", cln(f"{r.Block}{r.Location}{r.Plot}"))] = (r.lat, r.lon)
            else:
                km[("PEF" if r.Program == "PEF_CFI" else "CTRN", cln(r.Location))] = (r.lat, r.lon)
        ll = []
        for sitekey in P.SITE.astype(str).str.strip():
            dsn, pk = sitekey.split("__", 1); pk = re.sub(r"^(PEF|CTRN)_", "", pk)
            ll.append(km.get((dsn, cln(pk)), (np.nan, np.nan)))
        xy = pd.DataFrame(ll, columns=["lat", "lon"])
    else:
        xy = pl.reindex(P.SITE.astype(str).str.strip())
    lat0 = np.radians(45.0); A = np.c_[L.LAT.values, L.LON.values * math.cos(lat0)]; b = L.BGI.values.astype(float)
    out = np.full(len(P), np.nan)
    for i, (la, lo) in enumerate(zip(xy.lat.values, xy.lon.values)):
        if np.isfinite(la):
            dd = (A[:, 0] - la) ** 2 + (A[:, 1] - lo * math.cos(lat0)) ** 2
            out[i] = np.median(b[np.argpartition(dd, 5)[:5]])
    med = float(np.nanmedian(out)); miss = int(np.isnan(out).sum()); out[np.isnan(out)] = med
    return np.round(out).astype(int), f"knn5 (missing coords {miss} filled with median {med:.0f})"


def osm_chunk(job):
    sys.path.insert(0, str(H / "perseus_me/tracks/G/engines/osm")); import osm_engine as OE
    R, rows, outdir, rev = job; work = tempfile.mkdtemp(prefix="cmpo_"); res = []
    try:
        br = [(i + 1, r["bgi"], r["recs"]) for i, r in enumerate(rows) if r["recs"]]
        # OSM: years per cycle 1 to 10, and the last cycle of a run is not written, so run one extra cycle and read cycle R / ypc
        ypc = max(k for k in range(1, 11) if R % k == 0); ck = R // ypc
        got, bad, rc = OE.run_osm(str(OSM), work, br, R + ypc, ypc, (0, ck))
        for i, r in enumerate(rows):
            d = Path(outdir) / f"P{r['sid']}"; d.mkdir(parents=True, exist_ok=True)
            if r["recs"] and not got.get(i + 1):
                res.append((r["sid"], f"no rows rc {rc} bad {bad}")); continue
            parts = []
            for cyc, yr in ((0, r["y0"]), (ck, r["y0"] + R)):   # start state too, so readers that take the first year get t1
                recs = got.get(i + 1, {}).get(cyc, []) if r["recs"] else []
                tl = pd.DataFrame(recs, columns=["tid", "sp", "D", "H", "S"]) if recs else pd.DataFrame(columns=["tid", "sp", "D", "H", "S"])
                parts.append(pd.DataFrame({"Year": yr, "TPA": tl.S / HA, "DBH": tl.D / 2.54, "Ht": tl.H / FT,
                                           "SpeciesFIA": [f"{rev.get(s, 998):03d}" for s in tl.sp]}))
            df = pd.concat(parts, ignore_index=True)
            con = sqlite3.connect(str(d / "fvsout.db")); df.to_sql("FVS_TreeList", con, if_exists="replace", index=False); con.close()
            (d / "DONE").write_text(f"rc {rc} bad {bad} trees {len(df)} bgi {r['bgi']}\n"); res.append((r["sid"], "ok"))
    except Exception as e:
        res += [(r["sid"], f"error {type(e).__name__}: {e}"[:200]) for r in rows]
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", required=True, choices=list(SETS)); ap.add_argument("--arm", required=True, choices=list(ENV) + ["osm"])
    ap.add_argument("--run", required=True); ap.add_argument("--workers", type=int, default=2); ap.add_argument("--head", type=int, default=0)
    ap.add_argument("--only-sets", default="", help="comma list of SET values to keep (reg: Maine frames for OSM)")
    a = ap.parse_args()
    pf, tf, kd = SETS[a.set]
    P = pd.read_csv(pf, dtype={"pair_id": str, "t1_id": str})
    keys = {p.stem[1:]: p for p in kd.glob("P*.key")}
    P = P[P.pair_id.isin(keys)].sort_values("pair_id")
    if a.only_sets:
        P = P[P.SET.isin(a.only_sets.split(","))]
    if a.head:
        P = P.head(a.head)
    outdir = S / "batch" / a.run / "all"; outdir.mkdir(parents=True, exist_ok=True)
    meta = dict(set=a.set, arm=a.arm, run=a.run, pairs=len(P), started=time.strftime("%Y-%m-%dT%H:%M:%S"))
    t0 = time.time(); stat = []
    if a.arm == "osm":
        assert md5(OSM) == PINS["osm"] and md5(XW) == PINS["xwalk"] and md5(BGI) == PINS["bgi"]
        fw, rev = load_xwalk(); b, src = bgi_for(P, a.set); meta["bgi"] = dict(source=src, median=float(np.median(b)), min=int(b.min()), max=int(b.max()))
        T = pd.read_csv(tf, dtype={"pair_id": str}); tg = dict(tuple(T.groupby("pair_id")))
        sys.path.insert(0, str(H / "perseus_me/tracks/G/engines/osm")); import osm_engine as OE
        rows = []
        for r, bg in zip(P.itertuples(), b):
            t = tg.get(r.pair_id); recs = []
            if t is not None:
                t = t[(t.DIA > 0) & (t.TPA_UNADJ > 0)]
                recs = [(OE.osm_species(int(s), fw), d * 2.54, (h * FT if h > 0 else None), tp * HA)
                        for s, d, h, tp in zip(t.SPCD, t.DIA, t.HT.fillna(0), t.TPA_UNADJ)]
            if (outdir / f"P{r.pair_id}" / "DONE").exists():
                stat.append((r.pair_id, "skip")); continue
            rows.append(dict(sid=r.pair_id, R=int(round(r.REMPER)), y0=int(r.INVYR1), bgi=int(bg), recs=recs))
        jobs = []
        for R in sorted({x["R"] for x in rows}):
            q = [x for x in rows if x["R"] == R]
            jobs += [(R, q[i:i + 25], str(outdir), rev) for i in range(0, len(q), 25)]
        with ProcessPoolExecutor(a.workers) as ex:
            for res in ex.map(osm_chunk, jobs):
                stat += res
    else:
        calkw = CALKW.read_text() if a.arm == "fvs_regional" else ""
        meta.update(fvs_md5=md5(FVSNE), calkw_md5=md5(CALKW) if calkw else None,
                    coef_md5={k: md5(v) for k, v in ENV[a.arm].items() if v.endswith(".csv")})
        jobs = [(r.pair_id, float(r.REMPER), a.set, a.arm, str(keys[r.pair_id]), str(outdir), calkw) for r in P.itertuples()]
        with ProcessPoolExecutor(a.workers) as ex:
            stat = list(ex.map(fvs_one, jobs, chunksize=4))
    st = pd.DataFrame(stat, columns=["pair_id", "status"]); st.to_csv(outdir.parent / "status.csv", index=False)
    meta.update(status=st.status.str.split().str[0].value_counts().to_dict(), wall_s=round(time.time() - t0, 1))
    (outdir.parent / "meta.json").write_text(json.dumps(meta, indent=1)); print(json.dumps(meta))


if __name__ == "__main__":
    main()
