# Documentation update h (28 October 2026) for holoros/fvs-acd, built on the files at branch v142-autopilot-20261026 (HEAD
# 9a5afb37) by exact replacements, each asserted to match once. Adds PREREG50, 14.3 PREREG3, 14.3 PREREG4, the Howland decline
# diagnostic and release notes revision h. Removes nothing; the draft rows of docs/preregistrations.md are kept, with the new
# rows added after them. Usage: python3 docs_edit_h.py REPO cfg_docs_h.json. Every number in cfg_docs_h.json is copied from
# the four RESULT r1 files (md5 e3c62336, 1ef7f471, ad9402e0, 178d7d14). No em dashes.
import sys, json, os
R, C = sys.argv[1], json.load(open(sys.argv[2], encoding="utf8"))
def edit(rel, pairs):
    p = os.path.join(R, rel); t = open(p, encoding="utf8").read(); n0 = len(t.split())
    for a, b in pairs:
        assert t.count(a) == 1, (rel, t.count(a), a[:90]); t = t.replace(a, b)
    assert chr(0x2014) not in t, rel
    open(p, "w", encoding="utf8").write(t); print(rel, "words", n0, "->", len(t.split()))

ZEN = ("- Zenodo version 1.10.0 (10.5281/zenodo.23670727) was published on October 27, 2026 with the cross-version benchmark,\n"
       "  PREREG46 to PREREG49, the 14.2 arms and release notes revision g.\n")
edit("README.md", [
 ("## Status (October 27, 2026)", "## Status (October 28, 2026)"),
 ("PREREG46 to PREREG49 ran in October | record in `scripts/v14.2dev/` (PREREG46, the PREREG47 reading and PREREG48 in `scripts/v14.2dev/2026-10-26/`, PREREG49 in `scripts/v14.2dev/2026-10-27/prereg49/`), release notes revision g (`scripts/v14.2dev/2026-10-27/release-notes/`) |",
  "PREREG46 to PREREG50 ran in October | record in `scripts/v14.2dev/` (PREREG46, the PREREG47 reading and PREREG48 in `scripts/v14.2dev/2026-10-26/`, PREREG49 in `scripts/v14.2dev/2026-10-27/prereg49/`, PREREG50 in `scripts/v14.2dev/2026-10-28/prereg50/`), release notes revision h (`" + C["rn_h_path"] + "`; revision g in `scripts/v14.2dev/2026-10-27/release-notes/`) |"),
 ("and the sealed NH and VT confirmation is open | [`docs/v14.3/`](docs/v14.3/), result in [`docs/v14.3/run_v143p1/result/`](docs/v14.3/run_v143p1/result/) |",
  "and the sealed NH and VT confirmation is open" + C["p143_row_add"] + " | [`docs/v14.3/`](docs/v14.3/), result in [`docs/v14.3/run_v143p1/result/`](docs/v14.3/run_v143p1/result/); pre-registrations 2 to 4 and the Howland decline diagnostic in `docs/v14.3/run_v143p2/`, `run_v143p3/`, `run_v143p4/` and `run_howland_decline/` |"),
 (ZEN, ZEN + "\n"
  "October 28, 2026. Four more studies ran, all on aggregates and none changing 14.1 or 14.2. Each RESULT was revised once after\n"
  "an independent read only check recomputed every headline value; the earlier text is kept beside it as `_PREV_20261028b`.\n\n"
  + C["p50_bullet"] + C["p3_bullet"] + C["p4_bullet"] + C["hd_bullet"]),
 ("on October 17, 2026; earlier 14.2 refinement folders carry no record of a screen.",
  "on October 17, 2026; earlier 14.2 refinement folders carry no record of a screen. The PREREG50, 14.3 PREREG3, 14.3 PREREG4\n"
  "and Howland decline records added on October 28, 2026 were screened against the stand and site identifiers of their server only\n"
  "files and for key and coordinate columns, and no file was refused (`scripts/v14.2dev/2026-10-28/docs_h/`)."),
])

edit("VERSION_HISTORY.md", [
 ("revision g carries both (`scripts/v14.2dev/2026-10-27/release-notes/`).\n",
  "revision g carries both (`scripts/v14.2dev/2026-10-27/release-notes/`).\n" + C["era9_p50"]),
 ("## Era 10: 14.3 studies (October 17 to 27, 2026)", "## Era 10: 14.3 studies (October 17 to 28, 2026)"),
 ("| none | 17 Oct to 27 Oct | none | no engine file added, 14.1 remains the release |",
  "| none | 17 Oct to 28 Oct | none | no engine file added, 14.1 remains the release |"),
 ("`docs/v14.3/run_v143p1/`.\n\n## What this document does not cover",
  "`docs/v14.3/run_v143p1/`.\n\n" + C["era10_add"] + "\n## What this document does not cover"),
])

p = os.path.join(R, "docs/preregistrations.md"); t = open(p, encoding="utf8").read()
a50 = "| 50 | draft (not registered) | QC ingrowth entry size and scoring floor handling, for 14.3: preregistration 50 | `scripts/v14.2dev/2026-10-27/drafts/2026-10-27_v142_qc-ingrowth-entry-floor_PREREG50_DRAFT.md` |"
a3 = "| 3 | draft (not registered) | A T form with a class varying shape, beyond the PREREG2 family, for 14.3: pre-registration 3 | `docs/v14.3/prereg3_draft/2026-10-27_v143_T-form-class-shape_PREREG3_DRAFT.md` |"
for a, add in ((a50, C["prereg_rows_50"]), (a3, C["prereg_rows_143"])):
    assert t.count(a) == 1, a[:60]; t = t.replace(a, a + "\n" + add)
assert chr(0x2014) not in t; open(p, "w", encoding="utf8").write(t); print("docs/preregistrations.md updated")

edit("docs/index.md", [
 ("and its registered revision 5 (October 26, md5 b7562e8b) at the top of `v14.3/` |",
  "and its registered revision 5 (October 26, md5 b7562e8b) at the top of `v14.3/`; the October 28 runs in `run_v143p3/` (pre-registration 3, T form beyond the PREREG2 family), `run_v143p4/` (pre-registration 4, senescence by forest type) and `run_howland_decline/` (the Howland decline diagnostic) |"),
 ("PREREG13b to PREREG49, and of the 14.3 pre-registrations |", "PREREG13b to PREREG50, and of the 14.3 pre-registrations |"),
 ("| `../scripts/v14.2dev/2026-10-26/release-notes/2026-10-26_fvs-acd-v14.2_release-notes_DRAFT.md` |",
  "| `../scripts/v14.2dev/2026-10-28/release-notes/2026-10-28_fvs-acd-v14.2_release-notes_DRAFT.md` | 14.2 release notes, revision h (October 28); revision g is in `../scripts/v14.2dev/2026-10-27/release-notes/`; PREREG50 is in `../scripts/v14.2dev/2026-10-28/prereg50/` |\n"
  "| `../scripts/v14.2dev/2026-10-26/release-notes/2026-10-26_fvs-acd-v14.2_release-notes_DRAFT.md` |"),
 ("the PREREG48 and PREREG49 runs, the Zenodo 1.10.0 drivers and this documentation update |",
  "the PREREG48 and PREREG49 runs, the Zenodo 1.10.0 drivers, the October 28 records (PREREG50, 14.3 PREREG3 and PREREG4, the Howland decline diagnostic), release notes h and this documentation update |"),
])
print("DOCS_H_DONE")
