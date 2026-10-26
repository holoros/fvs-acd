# Restage Zenodo 1.10.0 with release notes revision f (NOT uploaded, NOT published; publishing needs Aaron's go). Copies the
# 1.10.0 staging zenodo_upload_p38p47_1100 (left untouched) to zenodo_upload_p38p47_1100f and adds, inside the PREREG46 and
# PREREG47 zip so the record stays at 100 files, release notes revision f (md5 08414cbc) with its content inventory diff,
# unified diff, build script and render check under release-notes_2026-10-26f/, and the companion PREREG46 figure
# (gyr142-p46-relht-longrun_r1) under prereg46/figs/. Every existing member stays byte identical. README, metadata,
# FIRE_INSTRUCTIONS and the related identifier are updated. Usage: python3 build_zenodo_1100f.py. No em dashes.
import os, json, shutil, zipfile, tarfile, hashlib
G = "/home/aaron/jobs/gh_v142"; S = f"{G}/zenodo_upload_p38p47_1100"; D = f"{G}/zenodo_upload_p38p47_1100f"
K = "/home/aaron/jobs/zen1100f_20261026"; TG = f"{K}/2026-10-26_notes-f-for-zenodo_DATA.tgz"
md5 = lambda p: hashlib.md5(open(p, "rb").read()).hexdigest()
assert not os.path.exists(D), "REFUSE " + D
assert md5(TG) == "2943533c4a1a28e10bc5f92a74865331"
EXP = {"release-notes/2026-10-26_fvs-acd-v14.2_release-notes_DRAFT.md": "08414cbca5918f805f259ca7fbd218b8",
       "release-notes/2026-10-26_fvs-acd-v14.2_release-notes_RENDER-CHECK.pdf": "e47765caa9a91061892c3a64753e9361",
       "release-notes/2026-10-26_release-notes_CONTENT-INVENTORY-DIFF.md": "c8596d3748eddfd06d12b54b8df96e93",
       "release-notes/2026-10-26_release-notes_r20261016e_to_r20261026f.diff": "ca9207e8e03dcd8dfff8add68e2afe3d",
       "release-notes/build_rn_20261026f.py": "8f2d85369c01506600b09a2721096171",
       "prereg46/figs/gyr142-p46-relht-longrun_r1_2026-10-26.png": "067e39dd01e8d0d625f2f5a4ea2daeee"}
add = {}
with tarfile.open(TG) as t:
    for m in t.getmembers():
        if m.isfile():
            b = t.extractfile(m).read(); assert hashlib.md5(b).hexdigest() == EXP[m.name], m.name
            arc = m.name.replace("release-notes/", "release-notes_2026-10-26f/", 1); add[arc] = b
assert len(add) == len(EXP)
shutil.copytree(S, D)
for f in os.listdir(D):
    if f.startswith("check_deposit_") and f.endswith(".log"): os.remove(f"{D}/{f}")
NP = "fvsacd_v142_prereg46_prereg47_2026-10-26.zip"; old = f"{S}/{NP}"; new = f"{D}/{NP}"
os.remove(new)
with zipfile.ZipFile(old) as zo, zipfile.ZipFile(new, "w", zipfile.ZIP_DEFLATED) as zn:
    names = zo.namelist()
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
rw("README.md", lambda s: one(one(s,
    "The release notes were not revised for 1.10.0 (revision e of October 16 is inside the cross-version zip).",
    "Release notes revision f (26 October 2026, built on revision e by asserted replacements, with its content inventory diff, unified\n"
    "diff, build script and render check) is inside the PREREG46 and PREREG47 zip under `release-notes_2026-10-26f/`, with a companion\n"
    "PREREG46 figure (`prereg46/figs/gyr142-p46-relht-longrun_r1_2026-10-26.png`, one legend, drawn from the frozen figure's data;\n"
    "the frozen figure is unchanged); revision e of October 16 stays inside the cross-version zip."),
    "Run files, deviations and red team records in `fvsacd_v142_prereg46_prereg47_2026-10-26.zip`",
    "Run files, deviations, red team records and release notes revision f in `fvsacd_v142_prereg46_prereg47_2026-10-26.zip`"))
def meta(s):
    j = json.loads(s); m = j["metadata"]
    m["related_identifiers"] = (m.get("related_identifiers") or []) + [{"identifier": "https://github.com/holoros/fvs-acd/tree/2df65b1183e88c290a01117634e45bd7b4a8a29b",
        "relation": "isSupplementTo", "resource_type": "software"}]
    d = m["description"]; assert d.endswith("</p>"); m["description"] = d + "<p>Release notes revision f (26 October 2026) are included.</p>"
    return json.dumps(j, indent=2, ensure_ascii=False) + "\n"
rw("zenodo_metadata.json", meta)
rw("FIRE_INSTRUCTIONS.md", lambda s: one(one(s, "`~/jobs/gh_v142/zenodo_upload_p38p47_1100/`, built from `zenodo_upload_p38p45b/` (1.9.0, published as\nrecord 23665173, left untouched) by `~/jobs/zen1100_20261026/build_zenodo_1100.py` with `cfg_1100.json`.",
    "`~/jobs/gh_v142/zenodo_upload_p38p47_1100f/`, built from `zenodo_upload_p38p47_1100/` (left untouched) by\n`~/jobs/zen1100f_20261026/build_zenodo_1100f.py`, which adds release notes revision f; that folder was built from\n`zenodo_upload_p38p45b/` (1.9.0, published as record 23665173) by `~/jobs/zen1100_20261026/build_zenodo_1100.py`."),
    "Nothing has been uploaded.", "Nothing has been published."))
txt = "".join(open(f"{D}/{f}").read() for f in ("README.md", "zenodo_metadata.json", "FIRE_INSTRUCTIONS.md"))
assert chr(0x2014) not in txt
print("BUILD_ZENODO_1100F_DONE", md5(new))
