# AcadianGY version history on Seven Islands CFI

*28 June 2026. Running the AcadianGY version archive against the Seven Islands CFI growth pairs
to see when the basal-area over-prediction appeared and whether any release changed it. Flat
CSI = 12, 65 routine long-horizon pairs, BA bias vs observed. Plaintext math, no em dashes.*

## What runs, and what does not

The archive spans v2 through v12.5.0 (in the Growth Model folder). They fall into three input
contracts:

1. v12.1.2 through v12.4.1 and 12.3.5 through 12.3.9: the `AcadianGYOneStand(tree, stand, ops)`
   per-year contract with uppercase tree columns. These run directly in the CFI harness.
2. v12.5.0 (production): a refactor to lowercase columns with `make_stand()` and `make_acd_tree()`.
   Runs via its own production driver.
3. v8.x through v11.x: the older monolithic `Acadian.GY(tree, stand, ops, cyclen, CutPoint)`
   whole-stand projector. The key was the stand argument: unlike v12, the old projector wants
   `stand` as a data.frame (columns STAND, CSI, ELEV), not a list, and `cyclen` as the number of
   projection years. With that contract v9.6 runs cleanly on all 65 pairs. v10.8 sources (after
   nlme and doParallel) but errors on 64 of 65 pairs, so it is not comparable. v11.1's archived
   copy is truncated (incomplete source). v8.x exposes a 3-argument `Acadian.GY(tree, stand, ops)`
   with no cyclen, so its projection length is controlled differently and it was not run here.

So the comparison now spans v9.6 through v12.5.0. v9.6 is the one clean pre-v12 point; v10.8, v11,
and v8 would each need a little more old-input plumbing to run faithfully.

## Result: the over-prediction is long-standing and narrows from v9 to v12

Overall BA bias, 65 routine Seven Islands CFI pairs, flat CSI = 12:

| version | overall BA bias | era |
|---|---|---|
| v9.6 | +17.0% | pre-v12 (Acadian.GY projector) |
| v10.8 | not comparable | pre-v12, ran only 1 of 65 pairs |
| v12.1.2 | +11.0% | v12 |
| v12.3.0 | +12.1% | v12 |
| v12.3.2 | +11.3% | v12 |
| v12.3.5 to v12.3.9 | +11.0% | v12 |
| v12.4.1 | +11.0% | v12 |
| v12.5.0 MORTCAL off | +11.3% | v12 |
| v12.5.0 MORTCAL on | -1.1% | v12 |

Two readings. First, the basal-area over-prediction is long-standing: it was already present in
v9.6 at +17% (and worse at the long horizons, +23% at 8 to 11 yr and +25% at 12 to 15 yr), and it
narrowed to a stable roughly +11% across the entire v12 lineage. So the model improved between v9
and v12 but did not remove the bias. Second, within v12 the bias is flat across point releases
(11 to 12%), so choosing among v12.1 through v12.4 does not change the Seven Islands result. The
only thing that removes it is the mortality correction (MORTCAL), opt-in and off by default in
12.3.x and a build option in 12.5.0. This reinforces the calibration finding: the lever is the
self-thinning and ingrowth submodels, not any single version's growth or site equations.

v9.6 by horizon: -9.5% (5 to 7 yr), +23.2% (8 to 11 yr), +25.0% (12 to 15 yr). The same
under-early, over-late horizon signature as v12, only larger, consistent with a self-thinning
that releases too little density.

## Practical reading for the team

- There is no earlier v12 release that quietly fixed or worsened the bias; choosing among 12.1
  through 12.4 does not change the Seven Islands result.
- The behavior-changing levers are MORTCAL and ingrowth, not the version number.
- To extend this back to v8 through v11, reconstruct that era's stand-init input format and drive
  `Acadian.GY(tree, stand, ops, cyclen)` directly. That is a bounded but separate task; flag it
  if the historical pre-v12 comparison is wanted.

## Production and version-history results (collected 28 June 2026)

The earlier-version archive run (`silc_cfi_xver_archive.csv`, SLURM 12074004) and the 12.5.0
production matrix (`silc_cfi_v125_full.csv`, SLURM 12073824) are in. The placeholder rows above now
carry the real numbers: 12.5.0 MORTCAL off sits at +11.3% (csi12), exactly on the v12 line, and
MORTCAL on resolves to -1.1%.

Earlier v12 lineage, ALL-horizon BA bias, 65 routine pairs, flat CSI = 12:

| version | ALL | 5 to 7 yr | 8 to 11 yr | 12 to 15 yr |
|---|---|---|---|---|
| v12.1.2 | +11.0% | -11.4% | +17.5% | +15.8% |
| v12.3.0 | +12.1% | -11.4% | +19.1% | +16.8% |
| v12.3.2 | +11.3% | -11.4% | +17.7% | +16.6% |
| v12.3.9 | +11.0% | -11.3% | +17.5% | +15.8% |
| v12.4.1 | +11.0% | -11.4% | +17.5% | +15.8% |
| v12.5.0 MORTCAL off | +11.3% | -11.3% | +17.7% | +16.2% |
| v12.5.0 MORTCAL on | -1.1% | -17.2% | +4.9% | +0.4% |

This confirms the lineage reading. The whole v12.1.2 through v12.4.1 ladder sits in a tight +11.0 to
+12.1% band, the by-horizon signature is the same throughout (under-early near -11%, over-late near
+16 to +19%), and 12.5.0 with MORTCAL off lands on that same line (+11.3%). The bias is stable across
v12, not a regression in any point release, and not removed by any version bump. Only the MORTCAL
correction moves it, dropping ALL to -1.1% and the 12 to 15 yr horizon to +0.4%.

## Files

- `results/seven_islands/silc_cfi_xver_archive.csv` (v12.1.2 to v12.4.1 plus v12.3.9, collected 28 Jun 2026)
- `results/seven_islands/silc_cfi_v125_full.csv` (12.5.0 production, collected 28 Jun 2026)
- `results/seven_islands/silc_cfi_cross_version.csv` (12.3.5 to 12.3.9)
- archive sources staged on Cardinal at `~/acd_archive/`
