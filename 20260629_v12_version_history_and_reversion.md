# FVS-ACD v12 history: what was refined, what reverted, and why

*29 June 2026. Answers the question of what happened in the v12 lineage: a period of substantial
refinement followed by reverting to older equations. Built from the official Acadian GY Model
Documentation (2025-05-20), the cross-version stress tests run this session, and the model source.
Plaintext math, no em dashes.*

## The short answer

The v12 lineage did not revert wholesale. One major refinement was tried, evaluated, and rolled
back: the multi-stage mortality of Chen et al. (2023). The released v12 versions kept the older
Weiskittel et al. (2012) mortality the whole time, which is why the stress tests show a stable bias
across v12.1.2 through v12.4.1 rather than a regression. A second change (the Chen et al. stand
basal-area increment) was kept but re-scoped from the plot level to the stand level. The net effect
is a v12 line whose growth equations advanced (Kuehne 2022 diameter and height increment) but whose
mortality stayed on the 2012 formulation after the 2023 replacement failed to beat it.

## What was refined in v12 (kept)

The model documentation records these as the live v12 equations:

1. Diameter increment: switched to Kuehne et al. (2022) at version 12.1.1, replacing the older
   Russell (Weiskittel et al. 2013) equation. Fit on more than 2.5 million observations, species as
   a random effect, a clear improvement over FVS-NE.
2. Height increment: switched to Kuehne et al. (2022) (from Russell et al. 2014). More conservative
   than the Russell form, which addressed the chronic FVS-NE over-prediction expectation.
3. Stand basal-area increment: Chen et al. (in preparation) added at version 12.3.0. It was first
   applied at the plot level, but because of the variation among plots the team shifted it to the
   stand level, where it acts as a cap on summed tree diameter increment (applied only when summed
   tree BA increment exceeds the stand prediction, and itself capped at 0.227 percent of plot BA,
   the 5th percentile of the Maine FIA data). This is the equation that holds growth down at high
   density.

## What reverted (rolled back)

Mortality. The documentation is explicit: the multi-stage mortality approach of Chen et al. (2023)
"was applied in beta versions but was not found to deliver results superior to the previous
approach." The model therefore reverted to predicting both stand- and tree-level mortality with the
Weiskittel et al. (2012) approach (stand.mort.prob, stand.mort.BA, tree.mort.prob). So the large
mortality refinement effort of the v12 cycle was tested in unreleased betas and rolled back; the
production mortality is the 2012 formulation.

This is the reversion being remembered: a lot of work went into the Chen 2023 multi-stage mortality,
it did not validate better than the 2012 equations, and it was pulled before release.

## Why the stress tests look stable, not regressed

The cross-version run this session (v12.1.2, v12.3.0, v12.3.2, v12.3.9, v12.4.1 on Seven Islands
CFI) gave a basal-area bias of +11.0 to +12.1 percent across all of them, essentially flat. That is
consistent with the history above: the released v12 versions all carried the same Weiskittel 2012
mortality and the Kuehne 2022 growth, so the stand-level behavior did not move much between point
releases. The Chen 2023 mortality, which would have changed the picture, never shipped. The 12.3.0
introduction of the stand BA-increment cap is visible as a small bump (+12.1 percent at 12.3.0) but
not a regime change.

## How this connects to the current work

The persistent +11 to +18 percent long-horizon basal-area over-prediction is a direct consequence of
this history: the growth side advanced (Kuehne 2022) but the mortality side stayed on the 2012
equations after the 2023 replacement was rolled back, and those 2012 equations carry no
density-frontier feedback. That is exactly the gap the 12.6.x work targets from a different angle
than Chen 2023: rather than replacing the whole mortality model, 12.6.0 adds the in-source MORTCAL
size-dependent correction and a standard SDImax-ceiling self-thinning, and 12.6.1 adds expected-value
ingrowth. These are smaller, testable increments on top of the reverted-to 2012 mortality, chosen
precisely because the large 2023 replacement did not pan out. The lesson from the v12 reversion,
that a wholesale mortality rewrite has to beat the 2012 equations on validation before it ships, is
the reason the 12.6.x changes are each gated and individually validated.

## Provenance

- Official equations and the reversion statement: Acadian GY Model Documentation, 2025-05-20
  (uploaded). The Mortality section is the source for the Chen 2023 rollback.
- Cross-version bias: `results/seven_islands/silc_cfi_xver_archive.csv` and
  `silc_cfi_cross_version.csv` (this session).
