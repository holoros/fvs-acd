# Stage the Zenodo 1.10.0 deposit (NOT uploaded, NOT published; publishing needs Aaron's go). Copies the published 1.9.0
# staging folder zenodo_upload_p38p45b (left untouched) to zenodo_upload_p38p47_1100 and:
#  - adds the cross-version benchmark zip (fvs-acd_crossversion-benchmark_2026-10-16.zip, md5 499e0c15, as prepared on
#    16 October with FOLD_INSTRUCTIONS.md), the acdx arms record zip, a PREREG46 and PREREG47 zip, and the two RESULT notes;
#  - folds the PREREG16 to PREREG25 script zips into one and the PREREG36 and PREREG37 results zips into one, every member at its
#    original path and byte identical, so the record stays at 100 files;
#  - updates README.md, CITATION.cff, zenodo_metadata.json, FIRE_INSTRUCTIONS.md and the manifests.
# Usage: python3 build_zenodo_1100.py config.json. No em dashes.
import os, sys, json, shutil, zipfile, glob, hashlib
C = json.load(open(sys.argv[1]))
G = "/home/aaron/jobs/gh_v142"; S = f"{G}/zenodo_upload_p38p45b"; D = f"{G}/zenodo_upload_p38p47_1100"; K = "/home/aaron/jobs/zen1100_20261026"
assert not os.path.exists(D), "REFUSE " + D
md5 = lambda p: hashlib.md5(open(p, "rb").read()).hexdigest()
ACDX = f"{K}/2026-10-16_fvs-acd-crossversion-benchmark-zenodo-fold_DATA.zip"; assert md5(ACDX) == "499e0c152ef5d58e148644f8139b4be4"
shutil.copytree(S, D)
for f in glob.glob(D + "/check_deposit_*.log"): os.remove(f)
NA = "fvs-acd_crossversion-benchmark_2026-10-16.zip"; shutil.copy2(ACDX, f"{D}/{NA}")
NARM = "fvsacd_v142_acdx-arms_2026-10-26.zip"; NP = "fvsacd_v142_prereg46_prereg47_2026-10-26.zip"
def zip_tree(dst, src, prefix):
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(src):
            dirs.sort()
            for f in sorted(files):
                p = os.path.join(root, f); z.write(p, prefix + os.path.relpath(p, src))
    with zipfile.ZipFile(dst) as z:
        for root, dirs, files in os.walk(src):
            for f in files:
                p = os.path.join(root, f); assert z.read(prefix + os.path.relpath(p, src)) == open(p, "rb").read(), p
zip_tree(f"{D}/{NARM}", f"{K}/arms_unpacked", "acdx_arms_2026-10-26/")
zip_tree(f"{D}/{NP}", f"{K}/pkg", "")
for r in C["results"]: shutil.copy2(f"{K}/pkg/{r['src']}", f"{D}/results/{r['name']}")
O1625 = ["fvsacd_v142_prereg16_scripts_2026-09-27.zip", "fvsacd_v142_prereg17_scripts_2026-09-27.zip", "fvsacd_v142_prereg18_scripts_2026-09-28.zip",
         "fvsacd_v142_prereg19to21_scripts_2026-09-28.zip", "fvsacd_v142_prereg22to25_scripts_2026-09-29.zip"]
Z1625 = "fvsacd_v142_prereg16_to_prereg25_scripts_2026-09-29.zip"
O3637 = ["fvsacd_v142_results_prereg36_2026-10-01.zip", "fvsacd_v142_results_prereg37_2026-10-01.zip"]; Z3637 = "fvsacd_v142_results_prereg36_prereg37_2026-10-01.zip"
for new, olds in ((Z1625, O1625), (Z3637, O3637)):
    with zipfile.ZipFile(f"{D}/{new}", "w", zipfile.ZIP_DEFLATED) as z:
        for o in olds:
            with zipfile.ZipFile(f"{D}/{o}") as zi:
                for info in zi.infolist(): z.writestr(info, zi.read(info))
    with zipfile.ZipFile(f"{D}/{new}") as zn:
        names = zn.namelist(); assert len(names) == len(set(names)), new
        n = 0
        for o in olds:
            with zipfile.ZipFile(f"{D}/{o}") as zo:
                for m in zo.namelist(): assert zn.read(m) == zo.read(m), m; n += 1
        assert n == len(names), (new, n, len(names))
    for o in olds: os.remove(f"{D}/{o}")
OM, NM = "zenodo_upload_manifest_190.txt", "zenodo_upload_manifest_1100.txt"
def relist(path):
    L = open(path).read().splitlines(); hdr = [l for l in L if l.startswith("#")]; body = [l for l in L if l and not l.startswith("#")]
    for a in O1625 + O3637: assert body.count(a) == 1, (path, a)
    body[body.index(O1625[0])] = Z1625
    for a in O1625[1:]: body.remove(a)
    body[body.index(O3637[0])] = Z3637; body.remove(O3637[1])
    if OM in body: body[body.index(OM)] = NM
    body += [NA, NARM, NP] + ["results/" + r["name"] for r in C["results"]]
    assert len(body) == len(set(body)); return hdr, body
h, b = relist(f"{D}/{OM}"); assert len(b) <= 100, len(b); os.remove(f"{D}/{OM}"); open(f"{D}/{NM}", "w").write("\n".join(h + b) + "\n"); NMAN = len(b)
h2, b2 = relist(f"{D}/files_to_upload.txt"); open(f"{D}/files_to_upload.txt", "w").write("\n".join(h2 + b2) + "\n")
for p in b: assert os.path.exists(f"{D}/{p}"), p
def one(s, a, x):
    assert s.count(a) == 1, (s.count(a), a[:80]); return s.replace(a, x)
def rw(f, fn):
    p = f"{D}/{f}"; s = open(p).read(); t = fn(s); assert t != s, f; open(p, "w").write(t)
def readme(s):
    s = one(s, "# FVS-ACD 14.2 refinement, 26 September to 5 October 2026: scripts and aggregate results (version 1.9.0)",
            "# FVS-ACD 14.2 refinement, 26 September to 26 October 2026: scripts and aggregate results (version 1.10.0)")
    s = one(s, "thirty five pre-registered studies", "thirty seven pre-registered studies")
    s = one(s, "PREREG45b and the fourth 5 October release notes).", "PREREG45b and the fourth 5 October release notes; " + C["commit_note"] + ").")
    s = one(s, "Version 1.9.0 DOI: 10.5281/zenodo.23665173", "Version 1.10.0 receives its own DOI when published as a new version of record 23665173. Version 1.9.0 DOI: 10.5281/zenodo.23665173")
    s = one(s, "`zenodo_upload_manifest_180.txt` lists the uploaded files", "`zenodo_upload_manifest_1100.txt` lists the uploaded files")
    s = one(s, "- `fvsacd_v142_prereg16_scripts_2026-09-27.zip`:", f"- `{Z1625}` (folded in 1.10.0 from the PREREG16, 17, 18, 19 to 21 and 22 to 25 script zips, members unchanged, paths as below), holding\n  the PREREG16 material:")
    for o in O1625[1:]: s = s.replace(f"`{o}`", f"`{Z1625}`")
    for o in O3637: s = s.replace(f"`{o}`", f"`{Z3637}`")
    s = one(s, "- `results/volconv_assembled/`:", C["contents_lines"] + "\n- `results/volconv_assembled/`:")
    s = one(s, "| PREREG32 | nb_c stands", C["study_rows"] + "\n| PREREG32 | nb_c stands")
    s = one(s, "## Changes in 1.9.0", "## Changes in 1.10.0\n\n" + C["changes"] + "\n\n## Changes in 1.9.0")
    assert "—" not in s; return s
rw("README.md", readme)
rw("CITATION.cff", lambda s: one(s, "version: 1.9.0", "version: 1.10.0"))
def meta(s):
    j = json.loads(s); m = j["metadata"]; m["version"] = "1.10.0"; m["publication_date"] = "2026-10-26"
    m["title"] = one(m["title"], "(PREREG45, PREREG45b) (scripts and aggregate results, 26 September to 5 October 2026)",
                     "(PREREG45, PREREG45b), the zero form test (PREREG46), the absolute QC Bakuzis gates (PREREG47) and the cross-version benchmark (scripts and aggregate results, 26 September to 26 October 2026)")
    m["description"] = m["description"].rstrip()
    assert m["description"].endswith("</p>"); m["description"] += C["meta_desc"]
    ri = m.get("related_identifiers") or []; ri += C["related"]; m["related_identifiers"] = ri
    return json.dumps(j, indent=2, ensure_ascii=False) + "\n"
rw("zenodo_metadata.json", meta)
open(f"{D}/FIRE_INSTRUCTIONS.md", "w").write(C["fire"])
txt = "".join(open(f"{D}/{f}").read() for f in ("README.md", "CITATION.cff", "zenodo_metadata.json", "FIRE_INSTRUCTIONS.md", NM))
assert "—" not in txt
print("manifest", NMAN, "files"); print("BUILD_ZENODO_1100_DONE")
