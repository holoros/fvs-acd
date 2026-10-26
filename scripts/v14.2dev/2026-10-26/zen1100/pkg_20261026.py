# Package the 26 October 2026 records for the repository and the 1.10.0 deposit: PREREG46 (qc_lz run), the PREREG47 reading r1,
# the Zenodo 1.9.0 scripts and the acdx arms record. Copies selected files into ~/jobs/zen1100_20261026/pkg and arms_unpacked,
# then sweeps every file for identifiers and coordinates and refuses on any hit. Never copies *_SERVERONLY files, task logs or
# trace files. No em dashes.
import os, shutil, glob, re, tarfile, hashlib, csv, io, sys
K = "/home/aaron/jobs/zen1100_20261026"; P = f"{K}/pkg"; A = f"{K}/arms_unpacked"
J46 = "/home/aaron/jobs/v142p46"; J47 = "/home/aaron/jobs/v142p47"; Z = "/home/aaron/jobs/zen190_20261026"
for d in (P, A): assert not os.path.exists(d), "REFUSE " + d
def cp(src, dst):
    assert os.path.isfile(src), src; assert "SERVERONLY" not in src, src
    d = os.path.join(P, dst); os.makedirs(os.path.dirname(d), exist_ok=True); shutil.copy2(src, d)
def cpg(pattern, dstdir):
    fs = sorted(glob.glob(pattern)); assert fs, pattern
    for f in fs: cp(f, os.path.join(dstdir, os.path.basename(f)))
# PREREG46
B = "prereg46"
cp(f"{K}/2026-10-26_v142_qc-relht-zero-form_RESULT.md", f"{B}/2026-10-26_v142_qc-relht-zero-form_RESULT.md")
cp(f"{K}/2026-10-26_v142-prereg46_DEVIATIONS.md", f"{B}/2026-10-26_v142-prereg46_DEVIATIONS.md")
cpg(f"{K}/review/*.md", f"{B}/review")
cp(f"{J46}/plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md", f"{B}/plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md")
for s in ["fit_p46.R", "fit_p46_lz.R", "chain_p46.sh", "chain_p46_lz.sh", "build_p46.sh", "assemble_p46.R", "assemble_p46_lz.R", "g0x_cmp_p46.R",
          "tr_check_p46.R", "driver_p46.R", "run_task_p46.sh", "run_p46.sh", "run_score_p46.sh", "run_score_p46_lz.sh", "launch_p46.sh", "parts/p46_edit.py",
          "PREV/assemble_p46_lz_r1_PREV_20261026.R"]:
    cp(f"{J46}/scripts/{s}", f"{B}/scripts/{s}")
for s in ["runner_p46_fb.R", "run_retry_p46.sh", "retry_timeouts_p46.sh", "work/p46_taskmap_DATA_2026-10-11.csv", "work/p46_ids_lz.txt"]:
    cp(f"{J46}/home/{s}", f"{B}/home/{s}")
for s in ["prereg_md5.txt", "launch_md5s.txt", "launch_md5s_lz.txt", "build_md5s.txt", "bundle_check.txt", "bundle_md5_p46.txt", "fit_md5.txt", "fit_ez_stop_md5.txt",
          "assemble_md5.txt", "chain_lz.txt", "fit_lz.txt", "assemble.log", "g0_result.csv", "g0b_result.csv", "g0x_result.csv", "tr_result_qc_lz.csv", "score.txt",
          "attempt1_20261026/chain.txt", "attempt1_20261026/fit.txt", "attempt1_20261026/launch_md5s_attempt1.txt"]:
    cp(f"{J46}/logs/{s}", f"{B}/logs/{s}")
cpg(f"{J46}/fit/*.csv", f"{B}/fit"); cpg(f"{J46}/assembled/*", f"{B}/assembled"); cpg(f"{J46}/figs/*", f"{B}/figs"); cpg(f"{J46}/diffs/*", f"{B}/diffs")
# PREREG47
B = "prereg47"
cp(f"{K}/2026-10-26_v142_qc-bakuzis-absolute_RESULT.md", f"{B}/2026-10-26_v142_qc-bakuzis-absolute_RESULT.md")
cp(f"{J47}/plan/thresholds_p47_DATA.csv", f"{B}/plan/thresholds_p47_DATA.csv")
for s in ["prereg_md5.txt", "thresholds_md5.txt", "thresholds_p47_run.log", "launch_md5s.txt", "assemble_p47_r1.log"]: cp(f"{J47}/logs/{s}", f"{B}/logs/{s}")
cpg(f"{J47}/assembled/*", f"{B}/assembled"); cpg(f"{J47}/figs/*", f"{B}/figs")
# Zenodo 1.9.0 drivers
B = "zenodo_190"
for s in ["probe.py", "zen_newversion_190.py", "zen_upload_190.py", "zen_publish_190.py", "zen_upload_190.log", "zen_publish_190.log", "check_deposit_190_20261026.log",
          "check_deposit_190_postdoi.log"]:
    cp(f"{Z}/{s}", f"{B}/{s}")
open(f"{P}/{B}/RUN.md", "w").write("""# Zenodo 1.9.0 publication, 26 October 2026

Host firebreather. Aaron's standing go of 11 October 2026 for 1.9.0 as staged in `~/jobs/gh_v142/zenodo_upload_p38p45b/`.
`probe.py` read the live record and the account's open drafts first (no open 14.2 draft; 1.8.0 latest). `check_deposit.py`
ended GATES PASS. `zen_newversion_190.py` created draft 23665173 as a new version of record 23168366; `zen_upload_190.py`
replaced the 100 inherited files with the 100 manifest files (0 md5 mismatches) and set the metadata; `zen_publish_190.py`
re-read the draft (unsubmitted, 100 files, version 1.9.0) and published it: DOI 10.5281/zenodo.23665173, concept DOI
10.5281/zenodo.22996790. The DOI was then written into the staged CITATION.cff and README.md (prior copies kept with a
_PREV_20261026 suffix) and the gates rerun (GATES PASS). The scripts are the 1.8.0 drivers with state file, staging folder,
manifest and version changed; the token is read from the standing file and never printed. No em dashes.
""")
# acdx arms record
os.makedirs(A); tarfile.open(f"{K}/2026-10-26_acdx-arms-record_DATA.tgz").extractall(A)
# identifier and coordinate sweep, every file
BAD_TOK = re.compile(r"QC__|NB__|NS__|ME__|PLT_CN|LAT_ACTUAL|LON_ACTUAL|TRUE_LAT|TRUE_LON|_SERVERSIDE|SERVERONLY_DATA|plot_coords")
BAD_HDR = {"stand", "site", "tree", "plot", "plt_cn", "lat", "lon", "latitude", "longitude", "lat_dd", "lon_dd", "x_coord", "y_coord", "geometry", "wkt"}
hits, scanned, binary = [], 0, []
for root in (P, A):
    for dp, dn, fn in os.walk(root):
        for f in fn:
            p = os.path.join(dp, f); b = open(p, "rb").read()
            if f.endswith((".png", ".tgz", ".zip")): binary.append(os.path.relpath(p, K)); continue
            s = b.decode("utf8", "replace"); scanned += 1
            for m in BAD_TOK.finditer(s):
                ctx = s[max(0, m.start() - 40):m.end() + 40]
                if f.endswith((".R", ".sh", ".py", ".md", ".txt", ".log", ".diff")) and ("SERVERONLY" in m.group(0) or "QC__" in m.group(0) or "NB__" in m.group(0)) and re.search(r"(grep|stop|refus|REFUSE|guard|prefix|pattern|check|\.csv|_SERVERONLY\b|SERVERONLY\.csv|SERVERONLY_fold)", ctx):
                    continue  # a script or note naming the pattern or a restricted path documents provenance; a data row does not
                hits.append((os.path.relpath(p, K), m.group(0)))
            if f.endswith(".csv"):
                hdr = [h.strip().strip('"').lower() for h in s.splitlines()[0].split(",")] if s else []
                bad = sorted(set(hdr) & BAD_HDR)
                if bad: hits.append((os.path.relpath(p, K), "header " + ",".join(bad)))
print(f"scanned {scanned} text files; not text scannable {len(binary)}: {binary}")
if hits:
    for h in hits[:40]: print("HIT", h)
    print("PKG_REFUSED", len(hits)); sys.exit(3)
print("PKG_DONE")
