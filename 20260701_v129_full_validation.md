# v12.9 full validation: the three checks, and the fix that resulted from them

*1 July 2026, autopilot continuation. The three items flagged as not yet done (ecoregion coverage audit,
recent Maine FIA cross-check, seeded long-horizon Bakuzis check) are now complete. The FIA cross-check
surfaced a real problem with the ecoregion-only gate, which led to a better final design. Plaintext math,
no em dashes.*

## 1. Ecoregion join coverage audit

The original join left 44 of 2555 MagPlot pairs and 1025 of 21638 Maine FIA plots unassigned (coastal and
boundary points falling just outside every polygon). Added a nearest-polygon fallback (bounding-box
pre-filtered distance search) to the point-in-polygon join. Result: 2555/2555 MagPlot and 21638/21638 FIA
plots now assigned, 44 and 1025 respectively via the fallback. Re-ran the core ecoregion x forest-type
diagnostic on the fully-covered data: the target cell (hardwood, outside Acadian core) moved from +56.7 to
+57.4 percent volume bias, confirming the finding was not an artifact of the missing 4 to 5 percent.

## 2. Recent Maine FIA cross-check: the ecoregion-only gate failed this test

Built forest-type-group and ecoregion for the 9066 recent Maine FIA remeasurement pairs (BA-weighted
dominant species group and the same CEC Level III join). Ran v12.9 (FTMULT 0.65, gated on ecoregion x
forest-type only, no province) on the full recent-FIA growing-stand stratum:

| model | BA level bias | annual increment bias |
|---|---|---|
| v12.7.1 baseline | -2.2% | -0.085 m2/ha/yr (-52%) |
| v12.9, ecoregion-only gate, FTMULT 0.65 | -4.0% | -0.151 m2/ha/yr (-93%) |
| v12.9, ecoregion-only gate, FTMULT 0.70 | -3.6% | -0.135 m2/ha/yr (-83%) |

This is a real, meaningful regression. The recent-FIA growing-stand guardrail, which v12.7.1 already had
under control, got substantially worse. Diagnosis: a large fraction of Maine's own FIA plots (1612 of 9066
pairs) sit in the "Northern Appalachian and Atlantic Maritime Highlands" ecoregion, the same ecoregion
carrying most of the Quebec hardwood problem, and are hardwood-dominated. The ecoregion-only gate applied
the Quebec-calibrated correction to these Maine plots too, even though Maine's own hardwood stands were
never part of the diagnosed problem. This is the clearest evidence yet that province (or more precisely,
the CFI data source behind it) still carries real information the ecoregion alone does not capture, echoing
the earlier finding that the identical ecoregion showed opposite-signed bias by province.

## The fix: add province back as a third gate dimension

Rebuilt the gate as the intersection of all three: province equals QC, ecoregion outside the Acadian core,
and forest type hardwood-dominated (`ops$sdimax.fortype.region <- list("QC_OTHER_ECO")`, keyed on a
combined `PROV_ecobucket` string per stand). Since every recent-FIA plot is Maine, none of them can ever
match "QC_OTHER_ECO", so this gate structurally cannot touch FIA regardless of ecoregion or forest type.

Re-ran both checks with the 3-way gate:

| check | v12.7.1 baseline | v12.9, 3-way gate (QC x OTHER_ECO x HW), FTMULT 0.65 |
|---|---|---|
| MagPlot QC, target cell (hardwood, outside Acadian core, n=163 to 173) volume bias | +56.7 to +57.4% | **+10.4%** |
| MagPlot NB, every cell | unchanged | unchanged (province gate excludes NB) |
| Recent Maine FIA, BA level bias | -2.2% | **-2.2%** (exact reproduction) |
| Recent Maine FIA, annual increment bias | -0.085 (-52%) | **-0.085 (-52%)** (exact reproduction) |

This is the complete fix: the target problem is still 82 percent closed (from +56.7 down to +10.4, similar
to the ecoregion-only version's +8.4), and the collateral damage to Maine's own growing stands, which the
ecoregion-only version introduced, is completely eliminated by construction. This 3-way gate, not the
2-way ecoregion-only version reported earlier, is the recommended v12.9 configuration.

## 3. Seeded long-horizon trajectory and Bakuzis check

Fixed the reproducibility gap flagged earlier (trajectory scripts had no `set.seed()`) and projected three
160-year scenarios at ESI 12, 16, 20: a softwood-dominated stand (unaffected by the fortype hook under any
gate), a hardwood-dominated stand under the correction (as if it were the targeted QC/OTHER_ECO population),
and the same hardwood composition without the correction (as if Acadian-core, for comparison).

| scenario | BA plateau (age 160) | TPH (age 160) |
|---|---|---|
| Softwood baseline (unaffected by any fortype gate) | 35.7 to 36.3 m2/ha | 668 to 704 |
| Hardwood, WITH the FTMULT 0.65 correction active | 20.9 to 21.2 m2/ha | 638 to 654 |
| Hardwood, correction NOT active (same composition) | 31.4 to 32.1 m2/ha | 852 to 916 |

Bakuzis relations (site ordering, Reineke regime, Eichhorn volume-height independence) pass cleanly for all
three scenarios with the seeded runs; no new biological-consistency failure introduced by the hook itself.

**The honest caveat, not fully resolved.** When the FTMULT 0.65 correction is active on a hardwood stand,
the long-horizon plateau drops to about 21 m2/ha, well below the realistic 28 to 32 m2/ha target established
for Acadian spruce-fir and, by extension, expected for mature northern hardwoods too (the untouched
hardwood scenario plateaus at a plausible 31 to 32). A correction calibrated to fix a short-interval
(5 to 15 year) volume bias, when carried through 160 years of continuous mortality pressure, compounds into
a long-horizon under-shoot. This is a real, quantified trade-off, not a disqualifying flaw, since the 3-way
gate now confines the correction to genuinely mature, dense QC hardwood stands outside the Acadian core,
which is a narrow population, but it is not fully resolved. The two honest options for a future refinement:
taper the multiplier so it is strongest for short-to-mid rotation stands and relaxes as the stand approaches
its true asymptote, or accept the level correction for inventory-horizon use and flag the long-horizon
carbon and old-growth application as needing the untapered (FTMULT 1.0) config for that specific population
until a better functional form is fit.

## Updated recommendation

Adopt the 3-way gate (`ops$sdimax.fortype.region <- list("QC_OTHER_ECO")`, FTMULT 0.65 to 0.70) as v12.9,
superseding the ecoregion-only version reported earlier today. It closes about 80 percent of the diagnosed
Quebec hardwood-outside-Acadian-core volume bias with zero measurable cost to New Brunswick or to the
independent recent Maine FIA growing-stand stratum, the two places a broader gate would have done real
damage. The long-horizon plateau under-shoot for the specifically-corrected population is the one open
item before this goes anywhere near carbon or old-growth work; it does not affect short-to-mid rotation
inventory use, which is what this correction was built for.

## Files (Cardinal)

`eco_join_v2.py` (nearest-fallback join), `magp_qcnb_ecol3_v2.csv`, `me_plot_ecol3_v2.csv`,
`fia_fortype_ecobucket.R`, `fia_recent_ecobucket_fortype.csv`, `v129_gate3.csv`, `fia_recent_gate3.csv`
(the combined PROV_ecobucket keys), `comprehensive_bench_v129d.R`, `fia_recent_v129.R` /
`fia_recent_v129d.R`, `traj_v129_seeded.R` / `traj_v129_seeded.csv` (seeded, reproducible),
results `cb_v129d_ft065_results.csv`, `fia_v129d_ft065_results.csv` (Maine FIA under the fixed 3-way gate),
`fia_v129_ft065_results.csv` / `fia_v129_ft070_results.csv` (the ecoregion-only version that regressed,
kept for the record).
