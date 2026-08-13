# AcadianGY mortality, self-thinning, and ingrowth calibration on Seven Islands CFI

*28 June 2026. Bakuzis-guided calibration test. The Bakuzis assessment flagged a shallow
self-thinning slope; this memo tests the mortality and ingrowth levers against the Seven
Islands CFI growth bias and closes the loop. AcadianGY 12.3.9 and 12.5.0 production.
Plaintext math, no em dashes.*

## The two flagged submodels

The basal-area over-prediction (+11% overall, +16 to +18% at 8 to 15 year horizons, on both
Maine FIA and Seven Islands CFI) has two candidate drivers, both flagged independently:

1. Self-thinning / mortality, flagged by the Bakuzis Reineke slope (-0.8, far shallower than
   the law-like -1.605): the model sheds too few stems as diameter grows.
2. Ingrowth, a known FVS-ACD problem and the subject of a long series of ingrowth experiments
   in the SILC work: too many recruits inflate density and basal area.

## Result 1: the tree-level mortality multiplier is a no-op

Sweeping the tree-level `mort.mult` from 1.0 to 2.5 left BA bias unchanged at +11.1%. That
input column is not wired into the realized mortality over these horizons, so it is not the
lever. This is worth knowing before anyone tries to calibrate through it.

## Result 2: the MORTCAL size-dependent correction resolves the long-horizon bias

The opt-in size-dependent mortality correction (`ops$MORTCAL = TRUE` in 12.3.9; `use.mortcal`
in the 12.5.0 MORTCAL build) is the effective lever. On the 65 routine Seven Islands CFI pairs,
flat CSI = 12:

| horizon | MORTCAL off | MORTCAL on |
|---|---|---|
| 5 to 7 yr | -11.3% | -17.2% |
| 8 to 11 yr | +17.6% | +4.8% |
| 12 to 15 yr | +15.8% | 0.0% |
| all | +11.1% | -1.3% |

Enabling MORTCAL drops the overall BA bias from +11.1% to -1.3% and removes the long-horizon
over-prediction almost entirely (12 to 15 yr from +15.8% to 0.0%). It slightly over-corrects at
the short horizon (5 to 7 yr, -11.3% to -17.2%), so the size or interval of the correction could
be tuned, but the long-horizon fix is decisive.

## Result 3: the Bakuzis loop closes

Regenerating the Bakuzis site-gradient trajectories with MORTCAL on steepens the realized
self-thinning slope toward the Reineke target:

| site class (CSI) | Reineke slope, MORTCAL off | MORTCAL on |
|---|---|---|
| 8 | -0.89 | -0.93 |
| 11 | -0.85 | -0.95 |
| 14 | -0.81 | -0.97 |
| 17 | -0.78 | -0.97 |
| 20 | -0.78 | -0.99 |

The mortality correction moves the slope from about -0.8 to about -0.97, much closer to -1.605.
The Bakuzis diagnostic predicted the mechanism (too little self-thinning), and the correction
that fixes the growth bias also steepens the self-thinning slope, exactly as predicted. The slope
still falls short of -1.605, so a fuller self-thinning calibration (SDImax and the density
mortality response) could close the remaining gap, but MORTCAL captures most of it.

## Result 4: version archive

AcadianGY 12.3.5 through 12.3.9 give identical Seven Islands CFI BA bias (+11.1%) because the
mortality correction is opt-in and off by default. The behavior change lives in the MORTCAL flag
and the 12.5.0 MORTCAL build, not in the 12.3.x point releases.

## Ingrowth

Ingrowth is the second lever. The 12.5.0 production ingrowth sensitivity (multiplier 1.0, 0.5, 0,
crossed with MORTCAL) quantifies its separate contribution to the bias. Results are tabulated in
`results/seven_islands/silc_cfi_v125_full.csv` once the production matrix completes. The design
isolates whether the residual short-horizon behavior is ingrowth-driven and whether ingrowth and
MORTCAL together over-correct.

## Implication

The site-driver swap (ESI) and the growth-bias fix are independent and complementary. The ESI
swap improves site fidelity; MORTCAL (and ingrowth calibration) fixes the basal-area
over-prediction. They can be adopted together. The Bakuzis assessment correctly identified the
self-thinning submodel as the locus of the bias, and the existing MORTCAL correction validates
that diagnosis on real CFI growth.

## Production and version-history results (collected 28 June 2026)

The 12.5.0 production matrix (`silc_cfi_v125_full.csv`, SLURM 12073824) is in. ALL-horizon BA bias,
65 routine Seven Islands CFI pairs:

| config | MORTCAL off | MORTCAL on |
|---|---|---|
| csi12 (flat 12) | +11.3% | -1.1% |
| csi15 (flat 15) | +11.8% | -0.6% |
| csi21 (flat 21) | +12.7% | +0.2% |
| ig10 (ingrowth mult 1.0) | +11.3% | -1.1% |
| ig05 (ingrowth mult 0.5) | +11.3% | -1.1% |
| ig00 (ingrowth mult 0) | +11.3% | -1.1% |

Two confirmations and one flag.

Confirmation 1, the site input stays a weak lever. Across csi12, csi15, csi21 the ALL-horizon bias
moves only 1.4 pp with MORTCAL off (+11.3 to +12.7) and 1.3 pp with MORTCAL on (-1.1 to +0.2), about
0.15 pp per meter of site over a 9 m span. This matches the 12.3.9 finding that the site driver does
not move stand BA much.

Confirmation 2, MORTCAL removes the long-horizon over-prediction, reproducing 12.3.9. For csi12,
ALL goes +11.3 to -1.1, 12 to 15 yr goes +16.2 to +0.4, 8 to 11 yr goes +17.7 to +4.9, and the
short horizon over-corrects, 5 to 7 yr from -11.3 to -17.2. Same magnitude and same signature as the
12.3.9 MORTCAL result (+11.1 to -1.3 overall, 12 to 15 yr +15.8 to 0.0, 5 to 7 yr -11.3 to -17.2).
The production 12.5.0 build and the 12.3.9 flag give the same fix.

Flag, ingrowth did not act as a lever in this run. The three ingrowth multipliers (1.0, 0.5, 0)
returned identical BA bias at every horizon and, on inspection, byte-identical per-plot predictions
(BA_PRED, TPA_PRED, QMD_PRED all equal across ig00, ig05, ig10; only the config-label column
differs). The dedicated ingrowth panel (`silc_cfi_v125_ingrowth.csv`) and the site panel
(`silc_cfi_v125_panel.csv`) came back empty (n = 0, NA). So the ingrowth multiplier was not wired
into the 12.5.0 production projection this round; it is not yet a demonstrated second lever. This is
the ingrowth analogue of the earlier mort.mult no-op: the knob exists in the input but does not
propagate to realized recruitment. Re-run needed with the ingrowth multiplier actually plumbed into
`make_acd_tree` / the recruitment step before ingrowth can be quantified. MORTCAL remains the single
effective lever demonstrated to date.

## Files

- `results/seven_islands/silc_cfi_mortcal_flag.csv` (MORTCAL off vs on)
- `results/seven_islands/silc_cfi_mortmult.csv` (mort.mult no-op)
- `results/seven_islands/silc_cfi_cross_version.csv` (version archive)
- `results/seven_islands/acadgy_bz_mortcal_off.csv`, `acadgy_bz_mortcal_on.csv` (Bakuzis under MORTCAL)
- `results/seven_islands/silc_cfi_v125_full.csv` (12.5.0 site x MORTCAL x ingrowth, collected 28 Jun 2026)
- `results/seven_islands/silc_cfi_xver_archive.csv` (v12.1.2 to v12.4.1 plus v12.3.9, collected 28 Jun 2026)
