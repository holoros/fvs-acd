# FVS-ACD (Acadian variant) modernization

Acadian growth-and-yield model (AcadianGY / FVS-ACD) modernization, benchmarking, and production
documentation. Code and aggregate results are versioned here; coordinate data, raw tree lists, and
large inputs stay on OSC Cardinal and (at release) Zenodo, matching the other holoros data repos.

## Production candidate
**AcadianGY 12.6.1** with the recommended operational configuration. See
`20260629_FVS-ACD_production_version_spec.md` (the authoritative spec the other documents reference).

Refinements over the 12.5.0 production refactor (all gated; legacy flags reproduce 12.5.0 bit-for-bit):
ESI site input, site-independent SDImax, SDImax-ceiling self-thinning, expected-value ingrowth;
MORTCAL optional and off by default.

## Documentation triad
- Benchmarking: `AcadianGY_v126_benchmarking.html` (self-contained, AcdBenchCompare style) and
  `20260629_AcadianGY_v126_benchmarking.md`.
- User guide: `20260629_FVS-ACD_user_guide.md`.
- Variant GTR (FVSne-style draft): `20260629_FVS-ACD_variant_overview_GTR_draft.md`.

## Key findings
- 12.5.0 to 12.6.0 roughly halved the regional over-prediction (BA +6.8% to +3.3%).
- The Maine long-horizon over-prediction is a regional **mortality deficit**, not a growth excess
  (`20260629_increment_vs_mortality_diagnosis.md`): Maine under-grows diameter (-14.5%) yet
  over-predicts BA and stems.
- Value is dominated by the site variable (GSA SRC 0.80); ingrowth fixes stem structure, not value.
- FVS-ACD vs OSM diverge ~60% in long-horizon BA (model-form uncertainty).
- Version evolution: v9.6 (+17%) -> v12 line (+11%) -> v12.6 (+3% regional).

## Layout
- `scripts/` model versions (AcadianGY_12.6.x.r), build/patch scripts, validation harnesses, figures.
- `results/` aggregate scorecards, bias tables, trajectories (no coordinates).
- `figures/` publication PNGs.
- Dated `.md` memos and reports.

## Status and next steps
12.6.1 is a documented **candidate, not a release**. Gating items before release (see
`20260629_redteam_and_roadmap.md`): regional mortality recalibration, refined ESI + ESI-anchored
dominant height, broader long-horizon validation, diameter-increment refit. The canonical model is
maintained by Ben Rice (Midgard Natural Resources); model changes coordinate with that repository.
