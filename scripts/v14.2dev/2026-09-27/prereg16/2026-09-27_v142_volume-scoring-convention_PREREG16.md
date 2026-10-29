# Symmetric height convention for benchmark volume scoring: pre-registration 16

27 September 2026, revision 1, written before any computation. Aaron chose this track (option 1, autopilot) after
PREREG14 found that observed and predicted volume are scored with different height imputations. No engine file,
coefficient, default or frozen run changes; this re-scores existing per tree outputs only. No em dashes.

## Problem

The benchmark runner's `metrics()` computes observed volume with measured height where it exists and the generic two
curve `himp(sp, d)` elsewhere. It computes predicted volume with the model's heights: its own imputation (`pht`) plus
grown increment. In QC only 18 percent of trees carry a measured height; `himp` reads 12 percent below measured and
`pht` 4 percent above (PREREG14). So every predicted over observed volume ratio mixes model error with a convention gap
whose size depends on each source's measured height share.

## Conventions scored

- **C0, as published.** The runner's own TOTVOL_o and TOTVOL_p, reproduced to 1e-6 relative as an identity check.
- **C1, himp on both sides (primary).** Observed and predicted volume both use `himp(sp, D)` for every tree, with the
  observed or predicted diameter and expansion factor. Height drops out, so C1 isolates the diameter and stem part of
  volume error. Every benchmark set can be scored this way, with no tags needed.
- **C2, measured where measured (secondary, tag stable sets only).** On tag matched survivors with a measured t2
  height, both sides use that measured height. Elsewhere both sides use `himp`. This keeps real height information and
  still treats both sides the same. It applies to NS (pass 28), QC (pass 28 tags), CTRN, BAXTER and MNAP State.

Height error is scored separately. The height tests are TOPHT and the tag matched height checks (PREREG11 H2 pattern);
they are not folded into volume.

## Scope

- **Arms:** v141LT (14.1 as shipped) and v1404_L2 (14.0.4), the two arms of record, from the frozen bench141 and v1404
  outputs.
- **Sets:** all 19 benchmark sets plus mnap_c (State, PREREG15).
- **Compute:** Cardinal, where the per tree outputs live. This is a scoring job, matching the precedent Aaron set for
  PREREG11 scoring, since moving the per tree outputs over the laptop link failed at 241 MB on 26 September.

## Gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| V0 identity | C0 recomputed from per tree files against the published results | 1e-6 relative on every scored stand | PREREG14 check C5 |
| V1 coverage | Stands scored under C1 equal the stands scored in the published benchmark | Equal, per set and arm | Construction |
| V2 bounds | Stand volume under C1 within physical bounds (0 to 1,500 m³ ha⁻¹), no NA on scored stands | Hard stop | F5 |
| V3 QC check | C1 on screened qc_c v141LT reproduces PREREG14's V_ph/V_oh | 1.088 within 0.001 | PREREG14 |

## Reported, not gated

For each set and arm, under C0, C1 and (where available) C2:

- total volume predicted over observed, bias percent and %RMSE, with stand bootstrap 95 percent intervals (the
  benchmark's site cluster draws);
- the convention gap C0 / C1 per set, regressed on the set's measured height share at t2.

## Decision rule stated now

- If the C0 / C1 gap exceeds 3 percent in any set, volume gates in 14.2 pre-registrations use C1 (or C2 where it
  exists), and the 14.1 regional volume findings are restated under C1 in the next release note.
- If the gap is within 3 percent everywhere, C0 stays and the gap is documented.
- Either way, the QC anchor recalibration (option 3) is scored under C1 or C2, never C0.

## Constraints

- New directories only (`v142_20260925/recs/volconv/`).
- Frozen runs are read, not rerun.
- No coordinates in any output.
- Nothing is sent outside.
