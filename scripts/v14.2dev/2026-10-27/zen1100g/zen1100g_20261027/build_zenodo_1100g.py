# Restage Zenodo 1.10.0 with release notes revision g, PREREG48 and PREREG49 (27 October 2026). Copies zenodo_upload_p38p47_1100f
# (left untouched) to zenodo_upload_p38p47_1100g and adds, inside the PREREG46 and PREREG47 zip so the record stays at 100 files:
# release notes g (md5 bb36f16a) with its build files under release-notes_2026-10-27g/, the PREREG48 record under prereg48/ (RESULT
# r1 06807ec6 with its PREV, DEVIATIONS, plan, scripts, logs, assembled tables) and the PREREG49 record under prereg49/ (RESULT
# ecc3155d, the identifier screened laptop folder). Every existing member stays byte identical. README, CITATION, metadata and
# FIRE_INSTRUCTIONS are updated, and the reserved DOI 10.5281/zenodo.23670727 is written in. Usage: python3 build_zenodo_1100g.py
# No em dashes.
import os, json, shutil, zipfile, tarfile, hashlib
G = "/home/aaron/jobs/gh_v142"; S = f"{G}/zenodo_upload_p38p47_1100f"; D = f"{G}/zenodo_upload_p38p47_1100g"
K = "/home/aaron/jobs/zen1100g_20261027"; TG = f"{K}/2026-10-27_notes-g-for-zenodo_DATA.tgz"
J = "/home/aaron/jobs"; COMMIT = "5a638f9f194b74efff0acae3c8a70ce6b5229ab8"
md5 = lambda p: hashlib.md5(open(p, "rb").read()).hexdigest()
assert not os.path.exists(D), "REFUSE " + D
assert md5(TG) == "14955070a246167f1a0611d85be023ac"
assert md5(f"{J}/v142p48/2026-10-26_v142_qc-stems-deficit_RESULT.md") == "06807ec6d3c781ee2373f2f49008f98e"
assert md5(f"{J}/v142p49/_laptop/2026-10-27_v142_ns-survival-step_RESULT.md") == "ecc3155db0c4b4b4996cfbf40864bf04"
add = {}
with tarfile.open(TG) as t:
    for m in t.getmembers():
        if m.isfile(): add[m.name.replace("release-notes/", "release-notes_2026-10-27g/", 1)] = t.extractfile(m).read()
assert hashlib.md5(add["release-notes_2026-10-27g/2026-10-27_fvs-acd-v14.2_release-notes_DRAFT.md"]).hexdigest() == "bb36f16a764934ac0c80a3e5f801bb47"
def tree(src, prefix, skip=()):
    for root, dirs, files in os.walk(src):
        dirs[:] = sorted(d for d in dirs if d not in skip)
        for f in sorted(files):
            if "SERVERONLY" in f: continue
            p = os.path.join(root, f); add[prefix + os.path.relpath(p, src)] = open(p, "rb").read()
for f in ("2026-10-26_v142_qc-stems-deficit_RESULT.md", "2026-10-26_v142_qc-stems-deficit_RESULT_PREV_20261026.md", "2026-10-26_v142_qc-stems-deficit_DEVIATIONS.md"):
    add["prereg48/" + f] = open(f"{J}/v142p48/{f}", "rb").read()
for sub in ("plan", "scripts", "logs", "assembled"): tree(f"{J}/v142p48/{sub}", f"prereg48/{sub}/")
tree(f"{J}/v142p49/_laptop", "prereg49/")
shutil.copytree(S, D)
for f in os.listdir(D):
    if f.startswith("check_deposit_") and f.endswith(".log"): os.remove(f"{D}/{f}")
NP = "fvsacd_v142_prereg46_prereg47_2026-10-26.zip"; old = f"{S}/{NP}"; new = f"{D}/{NP}"; os.remove(new)
with zipfile.ZipFile(old) as zo, zipfile.ZipFile(new, "w", zipfile.ZIP_DEFLATED) as zn:
    names = set(zo.namelist())
    for a in add: assert a not in names, a
    for info in zo.infolist(): zn.writestr(info, zo.read(info))
    for a in sorted(add): zn.writestr(a, add[a])
with zipfile.ZipFile(old) as zo, zipfile.ZipFile(new) as zn:
    for m in zo.namelist(): assert zn.read(m) == zo.read(m), m
    for a in add: assert zn.read(a) == add[a], a
    assert len(zn.namelist()) == len(zo.namelist()) + len(add)
def one(s, a, x):
    assert s.count(a) == 1, (s.count(a), a[:80]); return s.replace(a, x)
def rw(f, fn):
    p = f"{D}/{f}"; s = open(p).read(); t = fn(s); assert t != s, f; open(p, "w").write(t)
def readme(s):
    s = one(s, "thirty seven pre-registered studies", "thirty nine pre-registered studies")
    s = one(s, "Version 1.10.0 receives its own DOI when published as a new version of record 23665173.",
            "Version 1.10.0 DOI: 10.5281/zenodo.23670727 (record 23670727, a new version of record 23665173, published 27 October 2026).")
    s = one(s, "Run files, deviations, red team records and release notes revision f in `fvsacd_v142_prereg46_prereg47_2026-10-26.zip`",
            "Run files, deviations, red team records and release notes revisions f and g in `fvsacd_v142_prereg46_prereg47_2026-10-26.zip`")
    s = one(s, "| PREREG32 | nb_c stands with an empty observed t2 list |",
            "| PREREG48 | QC stems deficit split into survivors, upgrowth, recruitment and residual on field tags, for 14.3 | Rule 3, 14.3 ingrowth track on 14.1 and qc_rh, AR passes; ingrowth share 1.269 and 1.251; engine ingrowth enters near 5 cm, below QC floors of 9.1 to 33.7 cm; verified independently (record in the PREREG46 and PREREG47 zip, `prereg48/`) |\n"
            "| PREREG49 | NS gamma frailty survival step, and v141LTfi on the NS grid from measured stand lists, for 14.3 | Stage 1 rule 2 on M3, not adopted (M4 and M5 also fail); stage 2 v141LTfi not cleared (Eichhorn, top height monotonicity); median 100 year top height loss 15.6% against v141LT (record in the same zip, `prereg49/`) |\n"
            "| PREREG32 | nb_c stands with an empty observed t2 list |")
    s = one(s, "the frozen figure is unchanged); revision e of October 16 stays inside the cross-version zip.",
            "the frozen figure is unchanged); revision e of October 16 stays inside the cross-version zip. On 27 October 2026 the same zip received\n"
            "release notes revision g (27 October 2026, built on revision f, numbers checked independently) under `release-notes_2026-10-27g/`,\n"
            "the PREREG48 record under `prereg48/` (RESULT revised once with a verification addendum, earlier text kept) and the PREREG49\n"
            "record under `prereg49/`, so the record stays at 100 files. Repository commit " + COMMIT[:8] + " on branch v142-autopilot-20261026\n"
            "holds the same records.")
    assert chr(0x2014) not in s; return s
rw("README.md", readme)
rw("CITATION.cff", lambda s: one(one(s, "date-released: 2026-10-05", "date-released: 2026-10-27"),
    "# a new version of record 23168366. The doi field",
    "# a new version of record 23168366. 1.10.0 was published on 27 October 2026 as record 23670727 (DOI\n# 10.5281/zenodo.23670727), a new version of record 23665173. The doi field"))
def meta(s):
    j = json.loads(s); m = j["metadata"]; m["publication_date"] = "2026-10-27"
    m["title"] = one(m["title"], "the absolute QC Bakuzis gates (PREREG47) and the cross-version benchmark (scripts and aggregate results, 26 September to 26 October 2026)",
                     "the absolute QC Bakuzis gates (PREREG47), the QC stems deficit split (PREREG48), the NS survival step (PREREG49) and the cross-version benchmark (scripts and aggregate results, 26 September to 27 October 2026)")
    m["description"] = one(m["description"], "<p>Release notes revision f (26 October 2026) are included.</p>",
        "<p>It also adds PREREG48, which places the QC stems deficit in ingrowth past the scoring floor (engine ingrowth enters near 5 cm, below QC floors of 9.1 to 33.7 cm), and PREREG49, whose NS survival step is not adopted and which does not clear v141LTfi on measured stand lists. Release notes revisions f (26 October 2026) and g (27 October 2026) are included.</p>")
    m["related_identifiers"] = (m.get("related_identifiers") or []) + [{"identifier": "https://github.com/holoros/fvs-acd/tree/" + COMMIT, "relation": "isSupplementTo", "resource_type": "software"}]
    return json.dumps(j, indent=2, ensure_ascii=False) + "\n"
rw("zenodo_metadata.json", meta)
rw("FIRE_INSTRUCTIONS.md", lambda s: one(s, "`~/jobs/gh_v142/zenodo_upload_p38p47_1100f/`, built from `zenodo_upload_p38p47_1100/` (left untouched) by\n`~/jobs/zen1100f_20261026/build_zenodo_1100f.py`, which adds release notes revision f;",
    "`~/jobs/gh_v142/zenodo_upload_p38p47_1100g/`, built from `zenodo_upload_p38p47_1100f/` (left untouched) by\n`~/jobs/zen1100g_20261027/build_zenodo_1100g.py`, which adds release notes revision g, PREREG48 and PREREG49; 1100f was built from\n`zenodo_upload_p38p47_1100/` by `~/jobs/zen1100f_20261026/build_zenodo_1100f.py`, which adds release notes revision f;"))
txt = "".join(open(f"{D}/{f}").read() for f in ("README.md", "CITATION.cff", "zenodo_metadata.json", "FIRE_INSTRUCTIONS.md"))
assert chr(0x2014) not in txt
print("added members", len(add)); print("BUILD_ZENODO_1100G_DONE", md5(new))
