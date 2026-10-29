# Documentation update g (27 October 2026) for holoros/fvs-acd, built on the files at branch v142-autopilot-20261026 by exact
# replacements, each asserted to match once. Adds PREREG48, PREREG49, the Howland cross-version projections, release notes g, the
# Zenodo 1.10.0 state and the 14.3 PREREG2 state. Removes nothing. Usage: python3 docs_edit_g.py REPO cfg.json
# cfg keys: p2_row (README 14.3 row text after "registered on October 26, 2026 and"), p2_bullet, p2_era, zen_bullet, zen_cite,
# rn_g_path. No em dashes.
import sys, json, os
R, C = sys.argv[1], json.load(open(sys.argv[2]))
def edit(rel, pairs, tail=None):
    p = os.path.join(R, rel); t = open(p, encoding="utf8").read(); n0 = len(t.split())
    for a, b in pairs:
        assert t.count(a) == 1, (rel, t.count(a), a[:90]); t = t.replace(a, b)
    if tail: t = t.rstrip("\n") + "\n" + tail
    assert chr(0x2014) not in t, rel
    open(p, "w", encoding="utf8").write(t); print(rel, "words", n0, "->", len(t.split()))

edit("README.md", [
 ("## Status (October 26, 2026)", "## Status (October 27, 2026)"),
 ("| 14.2 | refinement in progress; no engine file, coefficient or default of 14.1 changed so far | record in `scripts/v14.2dev/` (PREREG46 and the PREREG47 reading in `scripts/v14.2dev/2026-10-26/`), release notes revision f (`scripts/v14.2dev/2026-10-26/release-notes/`) |",
  "| 14.2 | refinement in progress; no engine file, coefficient or default of 14.1 changed so far; PREREG46 to PREREG49 ran in October | record in `scripts/v14.2dev/` (PREREG46, the PREREG47 reading and PREREG48 in `scripts/v14.2dev/2026-10-26/`, PREREG49 in `scripts/v14.2dev/2026-10-27/prereg49/`), release notes revision g (`" + C["rn_g_path"] + "`) |"),
 ("pre-registration 2 (re-estimating the form of T) was registered on October 26, 2026 and has not run |",
  "pre-registration 2 (re-estimating the form of T) was registered on October 26, 2026 and " + C["p2_row"] + " |"),
 ("  (`scripts/v14.2dev/2026-10-26/acdx_arms/`).\n",
  "  (`scripts/v14.2dev/2026-10-26/acdx_arms/`).\n"
  "- PREREG48 split the QC stems deficit (about 24 points on qc_c fold B) and found it is ingrowth past the scoring floor, on both\n"
  "  14.1 and qc_rh (rule 3, a 14.3 ingrowth track; the split does not depend on the height form). An independent recomputation\n"
  "  reproduced every point value and showed why: engine ingrowth enters near 5 cm and stays below QC scoring floors of 9.1 to 33.7 cm\n"
  "  (7 of 6,042 records cross), so the track starts with ingrowth entry size and floor handling\n"
  "  (`scripts/v14.2dev/2026-10-26/rec_b/v142p48/`).\n"
  "- PREREG49 tested a gamma frailty survival step for NS over multi year intervals and reran the v141LTfi Bakuzis question on\n"
  "  measured stand lists. The step fixes the long interval survivor ratios (0.930 and 0.993 against 0.868 and 0.921) but fails\n"
  "  annual survival by interval (5 of 11 classes, predicted too low) and two PREREG22 gates, so it is not adopted; v141LTfi is\n"
  "  not cleared (new Eichhorn and top height monotonicity flags) and loses a median 15.6% of 100 year top height against v141LT\n"
  "  (`scripts/v14.2dev/2026-10-27/prereg49/`). 14.2 is unchanged.\n"
  + C["p2_bullet"] +
  "- Howland Research Forest: 13.1h and 14.0.4 L2 were run on the 93 Howland plots beside 14.1 and the earlier 12.3.6 and 13.1\n"
  "  ship18 runs. By year 50 at mid site, biomass changes by +29.7% (12.3.6), +8.3% (13.1h, after an early drop), -4.2% (13.1\n"
  "  ship18), -11.0% (14.0.4 L2) and -8.3% (14.1); the 14.x engines lose basal area from 41.5 to about 31 m² ha⁻¹. Only 12.3.6\n"
  "  shows the sustained gain that repeat ALS reports there (`results/howland_20261026/`).\n"
  + C["zen_bullet"]),
 ("| `results/`, `data/`, `figures/` | aggregate scorecards, frozen composite scores, publication figures |",
  "| `results/`, `data/`, `figures/` | aggregate scorecards, frozen composite scores, publication figures; `results/howland_20261026/` holds the five version Howland comparison |"),
 ("(1.9.0, 10.5281/zenodo.23665173, published October 26, 2026, as of this writing).",
  C["zen_cite"]),
])

edit("VERSION_HISTORY.md", [
 ("alternatives too tall (`scripts/v14.2dev/2026-10-26/`).\n",
  "alternatives too tall (`scripts/v14.2dev/2026-10-26/`). PREREG48 placed the QC stems deficit in ingrowth past the scoring floor\n"
  "(rule 3 on 14.1 and qc_rh), traced by an independent check to engine ingrowth entering near 5 cm, below QC floors of 9.1 to 33.7 cm.\n"
  "PREREG49 (October 26 to 27) did not adopt its NS survival step (annual survival by interval and two PREREG22 gates fail) and did\n"
  "not clear v141LTfi on measured stand lists, whose median 100 year top height loss against v141LT is 15.6%. Release notes\n"
  "revision g carries both (`" + C["rn_g_path"] + "`).\n"),
 ("## Era 10: 14.3 studies (October 17 to 26, 2026)", "## Era 10: 14.3 studies (October 17 to 27, 2026)"),
 ("| none | 17 Oct to 26 Oct | none | no engine file added, 14.1 remains the release |",
  "| none | 17 Oct to 27 Oct | none | no engine file added, 14.1 remains the release |"),
 ("registered on October 26, 2026 (revision 5); it has not run.",
  "registered on October 26, 2026 (revision 5). " + C["p2_era"]),
])

p = os.path.join(R, "docs/preregistrations.md"); t = open(p, encoding="utf8").read()
a49 = "| 49 | draft (not registered) | NS survival over multi year steps and the v141LTfi Bakuzis question, for 14.3: preregistration 49 | `scripts/v14.2dev/2026-10-11/drafts/2026-10-11_v142_ns-survival-step_PREREG49_DRAFT.md` |"
assert t.count(a49) == 1
t = t.replace(a49, a49 + "\n"
 "| 48 | result | Splitting the QC stems deficit into survivor mortality and ingrowth: PREREG48 result (revision r1, with verification addendum) | `scripts/v14.2dev/2026-10-26/rec_b/v142p48/2026-10-26_v142_qc-stems-deficit_RESULT.md` |\n"
 "| 49 | plan | NS survival over multi year steps and the v141LTfi Bakuzis question, for 14.3: preregistration 49 (revision 1, registered) | `scripts/v14.2dev/2026-10-27/prereg49/plan/2026-10-26_v142_ns-survival-step_PREREG49.md` |\n"
 "| 49 | result | NS survival over multi year steps and the v141LTfi Bakuzis question: PREREG49 result | `scripts/v14.2dev/2026-10-27/prereg49/2026-10-27_v142_ns-survival-step_RESULT.md` |")
a2 = "| 2 | plan | The form of the 14.1 thinning release term T, for 14.3: pre-registration 2 (revision 5, registered) | `docs/v14.3/2026-10-26_v143_T-form-reestimation_PREREG2.md` |"
assert t.count(a2) == 1
if C.get("p2_index_rows"): t = t.replace(a2, a2 + "\n" + C["p2_index_rows"])
assert chr(0x2014) not in t; open(p, "w", encoding="utf8").write(t); print("docs/preregistrations.md updated")

edit("docs/index.md", [
 ("| `v142-p46p47-docs-20261026` | the October 26 runs (PREREG46, the PREREG47 reading, the acdx arms, Zenodo 1.9.0 scripts) and this documentation update | stacked on `v143-prereg1-run-20261019` |",
  "| `v142-p46p47-docs-20261026` | the October 26 runs (PREREG46, the PREREG47 reading, the acdx arms, Zenodo 1.9.0 scripts) and the October 26 documentation update | draft PR #14, stacked on `v143-prereg1-run-20261019` |\n"
  "| `v142-autopilot-20261026` | PREREG2 (14.3) and PREREG48 registration, release notes f and g, the Howland cross-version projections, the PREREG48 and PREREG49 runs, the Zenodo 1.10.0 drivers and this documentation update | draft PR #15, stacked on PR #14 |"),
])
print("DOCS_G_DONE")
