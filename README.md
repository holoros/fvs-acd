# FVS-ACD (Acadian variant) modernization

Acadian growth-and-yield model (AcadianGY / FVS-ACD) modernization, benchmarking, and production
documentation. Code and aggregate results are versioned here; coordinate data, raw tree lists, and
large inputs stay on OSC Cardinal and (at release) Zenodo, matching the other holoros data repos.

## Current status (updated 13 August 2026)

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

## Layout

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
- `docs/GY_model_evaluation_scorecard.md`, `docs/HANDOFF_FVS-ACD.md` standing (non-dated)
  reference documents.
- `CHARTER.md` project charter, at root alongside this README as a repo-level standing document.

Reorganized 13 August 2026 (moved 76 dated handoffs and 22 archived report versions out of the
repo root into `docs/`; no history rewrite, all moves are plain renames and every file is still in
`git log` under its old path via `git log --follow`).
