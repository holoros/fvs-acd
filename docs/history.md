# FVS-ACD project history (status sections retired from the README)

These are the status sections the README carried from June to October 16, 2026, moved here
verbatim on October 17, 2026 when the README was rewritten as a user guide. They are kept for
provenance and are not the current state; the current state is in `../README.md` and
`../VERSION_HISTORY.md`. Paths inside them are relative to the repository root.

## Status as of October 16, 2026 (heading renamed from "Current status" on the move; text verbatim)

**AcadianGY 14.1 is the release.** It shipped on September 24, 2026 as an overlay on 14.0.4 with both of its diameter increment terms off by default and one named standing gate failure (GT1), as `VERSION_HISTORY.md` Era 8 records. The 14.x engine files (`scripts/AcadianGY_14.0.1.r` to `scripts/AcadianGY_14.1.r`) and the 14.1 gate pre-registration are on branch `engines-14.1-20260924`, which is open as pull request #9 and is not yet merged into this branch or `main`. The 13.1 model of record described in the August section below remains the base that every 14.x file sources.

The 14.2 refinement runs on branch `v142-refinement-20260926`. From September 27 to October 5, 2026 it ran the preregistered studies PREREG16 to PREREG45b against the 14.1 benchmark record, and none of them changed an engine file, coefficient or default of 14.1. It adopted a volume scoring convention (C1, or C2 where tags allow) and scorer r2, produced one regional NS candidate (v141LTfi) that passes its benchmark gates but has not cleared a Bakuzis grid, and closed the QC height anchor track with the shipped 0.111 kept. PREREG46 and revisions 1 to 5 of PREREG47 (absolute QC Bakuzis gates) are registered but not yet run, because firebreather, the host of the 14.2 runs, has been unreachable since October 11, 2026. The current release notes are revision e, `scripts/v14.2dev/2026-10-16/release-notes/2026-10-16_fvs-acd-v14.2_release-notes_DRAFT.md`.

A cross-version benchmark on October 16, 2026 compared 13.1h, 14.0.4 L2 and 14.1 on the 19 frozen benchmark sets, a new set of 827 post-harvest Maine FIA stands, and 200 yr no-harvest projections of 918 unmanaged Maine FIA stands (`docs/benchmarks/2026-10-16_cross-version/README.md`). Version 14.1 is the best ten year model, with a median absolute biomass bias of 3.8% across the 19 sets against 9.6% for 13.1h. However, it predicts biomass recovery after heavy removals of 2.78 Mg ha⁻¹ yr⁻¹ against an observed 1.39, an overstatement of 1.39 (1.13 to 1.64), and it projects a plateau and decline in 64 to 84% of stands in every forest type, where the FIA curves show a peak only in spruce-fir. Version 13.1h tracks recovery after harvest most closely but never declines. The benchmark points 14.3 at three changes, which are to limit the thinning response to partial removals (1), condition senescence on forest type (2), and repair the diameter growth shortfall of about 10% in quadratic mean diameter that every version shows on unmanaged Maine FIA stands (3). The 14.2 candidate arms p38_fit and qc_rh were not run, as their engine copies are on firebreather.

The Zenodo concept DOI for all versions of the FVS-ACD deposit is 10.5281/zenodo.22996790. The latest published version is 1.8.0 (10.5281/zenodo.23168366), which adds PREREG38 to PREREG44, and earlier versions are 1.7.0 (10.5281/zenodo.23085773) and 1.6.0 (10.5281/zenodo.23082910). Version 1.9.0, which adds PREREG45, PREREG45b and the stress tests, is staged on firebreather and unpublished. The cross-version benchmark is planned for the version after it.

## Status as of August 13, 2026 (historical)

Active development is on **AcadianGY 13.1**, not the 12.6.1 candidate this README previously
described. The model of record is `~/AcadianGY_13.1.r` on Cardinal (never edited directly; all
tuning is overlay scripts sourced after it loads). This work is on the **`hardwood-formrisk-wip`**
branch, not yet merged to `main`; the dated handoffs below cover history through July 2026 only.
Check `hardwood-formrisk-wip` for the current v13.1 pass 9-11 handoffs and results.

As of that branch (pass 10, 12 August 2026): the current leading configuration is **ship18**
(`sdimort.onset=0.55`, LEVER 3b survivor-increment correction, `ingrowth.mult=2.5`, r2 refit),
scored across 10 benchmark sources. 7 of 8 sources with a prior baseline improve on TOTVOL and
basal area bias, one (pef) worsens slightly, and the Bakuzis biological-realism battery passes 4
of 5 relations, with one new flag (softwood Reineke self-thinning, right at the acceptance
boundary) shipped as a disclosed tradeoff per Aaron's decision.

Pass 11 (in progress) fixed a silent-failure defect in the v13.1 hierarchical-posterior ingrowth
path: a missing normalizer file was silently substituted with 1 instead of raising an error,
inflating recruitment 97 percent in three harnesses that default to it. The fix
(`hier_norm_guard_patch.R`) is deployed on that branch; see its handoffs for the pass 9 Track E
diagnosis and the pass 11 fix and rerun.

The 12.6.1-era material below (production candidate note, documentation triad, key findings) is
historical and describes an earlier stage of the project. It is kept for provenance, not as the
current state.

## Historical: 12.6.1 production candidate (superseded by v13.1)

**AcadianGY 12.6.1** with the recommended operational configuration. See
`docs/handoffs/20260629_FVS-ACD_production_version_spec.md` (the authoritative spec the other
documents reference).

Refinements over the 12.5.0 production refactor (all gated; legacy flags reproduce 12.5.0 bit-for-bit):
ESI site input, site-independent SDImax, SDImax-ceiling self-thinning, expected-value ingrowth;
MORTCAL optional and off by default.

### Documentation triad (12.6-era)
- Benchmarking: `docs/reports/AcadianGY_v126_benchmarking.html` (self-contained, AcdBenchCompare
  style) and `docs/handoffs/20260629_AcadianGY_v126_benchmarking.md`.
- User guide: `docs/handoffs/20260629_FVS-ACD_user_guide.md`.
- Variant GTR (FVSne-style draft): `docs/handoffs/20260629_FVS-ACD_variant_overview_GTR_draft.md`;
  the polished GTR deliverable is `docs/reports/FVS-ACD_variant_overview_GTR.docx` / `.pdf`.

### Key findings (12.6-era)
- 12.5.0 to 12.6.0 roughly halved the regional over-prediction (BA +6.8% to +3.3%).
- The Maine long-horizon over-prediction is a regional **mortality deficit**, not a growth excess
  (`docs/handoffs/20260629_increment_vs_mortality_diagnosis.md`): Maine under-grows diameter
  (-14.5%) yet over-predicts BA and stems.
- Value is dominated by the site variable (GSA SRC 0.80); ingrowth fixes stem structure, not value.
- FVS-ACD vs OSM diverge ~60% in long-horizon BA (model-form uncertainty).
- Version evolution: v9.6 (+17%) -> v12 line (+11%) -> v12.6 (+3% regional) -> v13.1 ship18 (see
  Current status above for the latest scorecard).

### Status and next steps (12.6-era, see Current status above for what actually shipped next)
12.6.1 was a documented candidate, not a release, at the time this section was written. Gating
items named then (see `docs/handoffs/20260629_redteam_and_roadmap.md`): regional mortality
recalibration, refined ESI + ESI-anchored dominant height, broader long-horizon validation,
diameter-increment refit. The canonical model is maintained by Ben Rice (Midgard Natural
Resources); model changes coordinate with that repository.

## Repository layout as described on October 16, 2026 (moved from the README's Layout section)

- `scripts/` complete model version lineage (`AcadianGY_*.r`, 31 files, 12.3.6 through the current model of record 13.1), build/patch scripts, validation harnesses. See `VERSION_HISTORY.md` for what each version was and whether it shipped, was parked, or was a prototype.
- `results/` aggregate scorecards, bias tables, trajectories (no coordinates).
- `figures/` publication PNGs.
- `data/` frozen scorecard and composite-score CSVs, snippet notes.
- `refs/` archived reference material (theses, external reports).
- `zenodo_v12101/` the v12.10.1 Zenodo deposit package (metadata, upload script, data dictionary).
- `_context/` standing prompts and specs that don't fit the dated-handoff pattern.
- `docs/handoffs/` dated session handoffs and working notes, `YYYYMMDD_topic.md` (or `.docx`
  where a handoff produced a formatted deliverable alongside its markdown source). This is the
  project's day-by-day record; read chronologically for history, or grep for a topic.
- `docs/reports/` current, citable deliverables: benchmark reports, the variant GTR, presentation
  decks, in their finished formats (docx/pptx/pdf) plus markdown source where one exists.
- `docs/reports/archive/` superseded `_PREV_*` versions of the files in `docs/reports/`, kept for
  provenance. Not the current version of anything; check `docs/reports/` first.
- `docs/benchmarks/` dated benchmark packages, each with its own README, report, figures,
  aggregate CSVs and scripts (first entry `2026-10-16_cross-version/`).
- `scripts/v14.2dev/` the 14.2 refinement record, one dated folder per session, holding the
  preregistrations, RESULT files, diffs, scripts and release notes.
- `docs/GY_model_evaluation_scorecard.md`, `docs/HANDOFF_FVS-ACD.md` standing (non-dated)
  reference documents.
- `CHARTER.md` project charter, at root alongside this README as a repo-level standing document.

Reorganized 13 August 2026 (moved 76 dated handoffs and 22 archived report versions out of the
repo root into `docs/`; no history rewrite, all moves are plain renames and every file is still in
`git log` under its old path via `git log --follow`).
