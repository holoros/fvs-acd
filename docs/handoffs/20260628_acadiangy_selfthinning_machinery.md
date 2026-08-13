# AcadianGY self-thinning machinery: the density modifiers are inert

*28 June 2026. Bakuzis-guided self-thinning calibration (gy-modeling and fvs-modeling). Tests
whether AcadianGY's relative-density modifiers, which are off by default, steepen self-thinning
toward the Reineke -1.605 law and close the stem-count gap that MORTCAL alone leaves open.
AcadianGY 12.3.9. Plaintext math, no em dashes.*

## What was tested

AcadianGY computes a per-stand maximum SDI (the Weiskittel and Kuehne 2019 function, line 2093 of
the model: a composition-based SDImax driven by percent hardwood basal area, mean specific gravity,
DBH range, species diversity, elevation, and CSI) and a relative density RD = SDI / SDImax. The
model exposes four density controls in ops: `useMORT_RDmodifier`, `useDBH_RDmodifier`,
`useHT_RDmodifier`, and `maxRD`, all off by default. These are the levers that should drive
density-dependent self-thinning as a stand approaches its SDImax ceiling. The Bakuzis assessment
had flagged a shallow self-thinning slope (-0.8 vs the law-like -1.605), so this run toggled the
density modifiers on the Bakuzis site-gradient trajectory and measured the realized Reineke slope.

## Result: the density modifiers do nothing

| config | Reineke slope | terminal stems/ha (site 14) |
|---|---|---|
| base (all off) | -0.82 | 618 |
| MORTCAL on | -0.96 | 426 |
| useMORT_RDmodifier on | -0.82 | 618 |
| useMORT + useDBH + useHT_RDmodifier on | -0.82 | 618 |
| MORTCAL on + all RD modifiers on | -0.96 | 426 |

Enabling the relative-density modifiers changes nothing: the RD configurations are identical to
the base run, slope and terminal density both, to the digit. Adding the RD modifiers on top of
MORTCAL also changes nothing beyond MORTCAL alone. The modifiers are present in the interface but
not connected to the realized projection.

## This completes a clear pattern

Across this whole investigation, the AcadianGY ops knobs that should govern density, mortality, and
recruitment are inert. The tree-level `mort.mult` (1.0 to 2.5) was a no-op. The `ingrowth.mult`
(1.0, 0.5, 0) was a no-op. The ingrowth threshold and entry DBH were no-ops. And now the three
relative-density modifiers are no-ops. The only control that actually changes the projection is the
in-source MORTCAL size-dependent mortality correction. Everything else in the density and
recruitment interface is decorative on this code path.

## Implication for FVS-ACD self-thinning

1. MORTCAL is the only working lever, and it is not enough on its own. It lifts the self-thinning
   slope from -0.82 to -0.96 and pulls terminal density from 618 to 426 stems/ha, a real
   improvement, but it stops well short of the Reineke -1.605. The residual gap to true Reineke
   self-thinning, and the matching stem-count under-prediction (TPA about -18% on Seven Islands
   and FIA), cannot be closed by configuration because the relevant knobs are not wired.
2. Closing it is a code task, not a calibration task. The relative-density modifiers (or a new
   SDImax-relative mortality term) need to be connected to the realized growth and mortality step
   so that stands actually thin as RD approaches 1. The SDImax itself is sound: the composition
   based Weiskittel-Kuehne function already gives softwood a higher ceiling than hardwood (about
   1050 vs 900), matching the brms resummary, so the input to the machinery is fine; it is the
   machinery that is disconnected.
3. The repaired self-thinning would consume the forest-type SDImax from the brms resummary
   (`20260628_sdimax_resummary_for_fvsacd.md`), and the right validation is exactly this Bakuzis
   Reineke test plus the Seven Islands and FIA stem-count bias.

## Recommendation for Ben Rice

Treat self-thinning as the next FVS-ACD code item after the ESI swap and the MORTCAL default. The
density-dependent mortality path (the RD modifiers tied to SDImax) is present but non-functional;
wiring it is what moves the self-thinning slope from -0.96 toward -1.605 and fixes the stem-count
under-prediction that MORTCAL leaves on the table. This is the structural fix the Bakuzis
assessment has been pointing at from the start.

## Caveat

The Bakuzis test falsifies, it does not confirm. The -0.96 under MORTCAL is better but still a
flag; it says the self-thinning is closer to correct, not that it is correct.

## Files

- Script: `scripts/bz_rd_test.R`
- Result: `results/seven_islands/bz_rd_reineke.csv`, and `bz_rd_<config>.csv` trajectories on Cardinal.
