# AcadianGY version archive

The full AcadianGY / FVS-ACD R implementation lineage, committed for provenance. These are the model
source files only (no coordinate data). The production candidate and the 12.6.x refinement series live
one level up in `scripts/`; this folder holds the historical and intermediate versions.

| file | line | notes |
|---|---|---|
| AcadianGYv8.1.r | v8.1 | early archived version; ran on Seven Islands cross-version benchmark |
| AcadianGYv9.6.r | v9.6 | cleanest pre-v12 run on Seven Islands (BA +17%); proven Acadian.GY(tree,stand,ops,cyclen,CutPoint) contract |
| AcadianGYv10.8.r | v10.8 | archived; older SPP.func rejects some v12 species |
| AcadianGYv11.1.r | v11.1 | archived |
| AcadianGYv12.1.2.r | v12.1.2 | early v12 line |
| AcadianGYv12_3_0.r | v12.3.0 | v12.3 series start |
| AcadianGYv12_3_2.R | v12.3.2 | v12.3 series |
| AcadianGYv12_4_1.R | v12.4.1 | v12.4 series |
| AcadianGY_12.3.6.r | v12.3.6 | v12.3 refinement line (HRF / Seven Islands work) |
| AcadianGY_12.3.7.r | v12.3.7 | |
| AcadianGY_12.3.8.r | v12.3.8 | acd_divergence investigation (fvs-modern) |
| AcadianGY_12.3.9.r | v12.3.9 | |
| AcadianGY_12.5.0.r | v12.5.0 | production refactor baseline; make_stand / make_acd_tree / make_ops / AcadianGYOneStand contract |
| AcadianGY_12.5.0_mortcal.r | v12.5.0 + MORTCAL | MORTCAL empirical BA-corrector variant |

Lineage in `scripts/` (current series): 12.3.10 (ESI patch), 12.6.0 (four refinements),
12.6.1 (production candidate, expected-value ingrowth), 12.6.2_proto and 12.6.2b_proto
(ESI-anchored dominant height; b = fitted k=0.0039 p=0.726), 12.6.4 (regional stand-mortality cut scale).

Version evolution on the 270-plot NB/NS/ME regional set (BA bias): v9.6 +17% -> v12 line +11% ->
v12.6 +3.3%. See `20260629_v12_version_history_and_reversion.md` for the refinement-then-reversion story.
