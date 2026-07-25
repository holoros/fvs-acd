# FVS-ACD v12.11: fitted correction levers and the stand-level constraint architecture

*18 July 2026. Consolidates the three lever fits from the OODA run (recruitment, mortality, survivor
diameter increment) and reframes the v12.11 build around Chapter 10 of Weiskittel et al. (2011), Linking
growth models of different resolutions (refs/Weiskittel2011_ch10_linking_resolutions.pdf). The lever fits give
the correction magnitudes; the chapter gives the robust mechanism to apply them. Aggregates only, proprietary
data stayed on Cardinal. No em dashes, plaintext math.*

## The reframe (Aaron's point, grounded in ch. 10)

Individual-tree models are passive aggregation: stand attributes emerge from summing unconstrained tree
projections, so they can drift biologically (ch. 10, section 10.3). The robust fix is to run stand-level
growth, mortality, and ingrowth equations and then constrain or disaggregate the tree-level predictions to
them. Three linking methods from 10.3: disaggregation (proportional increment, additive functions),
constrained parameters, and combined; Cao (2007) constrained least squares is the strongest when tree-level
increment and survival equations already exist, which is our case. So v12.11 should not be three ad hoc
tree-level multipliers. It should be: predict the stand-level target for BA increment, mortality, and
ingrowth, then scale the tree-level ddbh, survival, and recruitment so the summed tree prediction matches the
stand target. The three fits below are the empirical magnitudes those stand-level corrections must hit; the
build wires them in as constraints rather than raw per-tree clamps.

## Lever 1: recruitment (highest volume leverage)

Finding: predicted ingrowth is 3 to 42 percent of observed; the basal-area ingrowth ratio is stable and
roughly density-flat at 2.0 to 2.8 (pooled 2.5); the larger volume ratio (5 to 6x) is that BA deficit times a
recruit-undergrowth factor (~2x) that belongs to the diameter lever, so do not double count. Calibrate on the
long-interval evidence (the short-interval ratios are inflated by the annualized recruitment floor, the 2018
too-infrequent ingrowth signature).

- Fit: ingrowth.mult = 2.5 (range 2.4 to 2.8), BA-anchored, flat. Optional RD taper to protect mature closed
  stands (Baxter own ratio only 1.31): m(RD) = 1.4 + 1.4*(1 - logistic(12*(RD - 0.80))).
- Hook: calc_ingrowth in _scripts/AcadianGY_12.10.2.r lines 2566 to 2570. ops$ingrowth.mult is already read
  (default 1); ingrowth.thrshld = 0 expected-value recruitment is already the make_ops default. Flat lever
  needs NO engine edit, just ops$ingrowth.mult <- 2.5 and ops$use.ingrowth.release <- TRUE. Optional taper is
  a small gated diff at 2566 to 2570 (spec in the subagent output).
- Stand-constraint form (preferred): predict stand ingrowth (stems and BA per ha) from a stand-level ingrowth
  equation keyed to RD and composition, then recover the recruit diameters, rather than a flat per-plot
  multiplier. This is the ch. 10 Figure 10.1 ingrowth term I plus diameter-distribution recovery.

## Lever 2: mortality (second volume mover)

Finding: over-removal is a high-density MANAGED phenomenon. At equal RD, natural stands are removed about
right (Baxter obs/pred 1.07, Maine FIA 1.07) while managed/thinned residuals are over-removed 6 to 7x (CTRN
0.22, i.e. predicted 4.5x observed; NB 0.40). A pure density scalar is wrong because it would suppress the
correct natural self-thinning; the correction must be management gated.

- Fit: management-gated attenuation of the self-thinning removal fraction. f(RD) = fmin + (1 - fmin)*
  exp(-k*max(RD - RD0, 0)) for managed/thinned stands, f = 1 for natural. fmin = 0.13, k = 12.4, RD0 = 0.38,
  RD = SDI/1200. Post-fix: CTRN 15.5 -> 2.7 (obs 3.4), NB 12.2 -> 2.3 (obs 4.9), Baxter and Maine FIA exactly
  unchanged.
- Hook: SDImort block in AcadianGYOneStand, _scripts/AcadianGY_12.10.2.r lines 3618 to 3653 (sdm_mfrac line
  3644). Gated diff on a new ops$mort.dens.scale, default OFF reproduces v12.10.2 bit for bit. Existing
  related flags: ops$mort.mult (global), ops$use.mortcal (off by default), ops$use.sdimort (on). Thinning
  survival modifiers ssurv_thin_mod / tsurv_thin_mod already reduce stand.mort.ba but do not touch the
  sdimort path, which is exactly why thinned residuals still over-remove.
- Preserves Reineke and the plateau: natural stands take f = 1 (full self-thinning); the floor fmin = 0.13
  attenuates but never disables; the separate sdm_keepc ceiling holding RD <= sdm_max is untouched.
- Stand-constraint form (preferred): the managed over-removal is a stand-level mortality equation error;
  predict stand mortality (TPH and BA loss) with the management-aware equation, then disaggregate to trees,
  rather than scaling the per-tree self-thinning decrement directly.

## Lever 3: survivor diameter increment (mature-end fix)

Finding: survivor diameter growth is too high, concentrated in large trees (20 to 40 cm) of mature high-QMD
stands; it is the sole driver of the Baxter +9 percent (survivor BA 4.15 vs 2.63, ratio 0.634) and is about
right at the developing Maine FIA end (ratio ~1.0). Correction must be size AND maturity dependent. Data
caveat: the multi-source tree lists lack a persistent cross-time tree tag, so tree-level tag matching is
unreliable; the fit rests on stand-level aggregates plus the model's own survivor tracking (this is itself an
argument for the stand-constraint approach).

- Fit: per-tree multiplier m = max(0.15, 1 - r*G(dbh)*H(QMD)), G(dbh) = logistic((dbh - 25)/6),
  H(QMD) = logistic((QMD - 18)/3), r = 0.90. Baxter survivor BA 4.15 -> 2.63 (closes +9 percent), Maine FIA
  x0.966 (developing end preserved).
- Hook: base increment ddbh() lines 788 to 807 (log-linear Kuehne, no true asymptote so large trees keep
  accreting); orchestrator calc_ddbh() lines 1041 to 1207, multipliers combine at line 1167. Existing
  ops$use.ddbh.sizeform is a pure-DBH clamp with no maturity term (too tight). New gated ops$use.ddbh.rein
  hook recommended (spec in the subagent output); stand QMD is available at the hook as plot.data$qmd.
- Stand-constraint form (preferred, ch. 10 proportional increment / Cao 2007 constrained least squares):
  predict stand BA increment from a stand-level equation, then scale tree ddbh so the summed tree BA increment
  matches the stand target. This automatically reins the over-accreting large trees without a hand-tuned
  size-QMD clamp, and it is the method Aaron pointed to. The fitted m() above is the interim direct form; the
  constrained form is the v12.11 target.

## Cross-cutting

- Double-count guard: the recruitment lever owns only the BA/count ingrowth deficit (~2.5x); the recruit
  undergrowth (~2x of the volume ingrowth gap) is diameter growth on young recruits and belongs to lever 3.
  Coordinate so recruit-cohort volume is not added twice.
- All three levers are gated, default OFF, so the gate-off build is byte-identical to v12.10.2. That preserves
  the frozen August model.
- v13.1 (running, job 12410391) is fitting stand-level recruitment and mortality hierarchically; its converged
  posteriors are the principled source for the lever-1 and lever-2 stand equations. Gate it first.

## Build and validate plan (next session)

1. Gate v13.1 (harvest task 20 July); read its recruitment and mortality structure.
2. Build AcadianGY_12.11.r off _scripts/AcadianGY_12.10.2.r. Start with the stand-constraint diameter lever
   (proportional increment to a stand BA-increment target) since it is the ch. 10 method Aaron specified;
   add the recruitment stand-ingrowth equation and the management-gated mortality. Keep every lever gated.
3. Smoke test, then re-score the full multi-source maturity-gradient benchmark (bench_parity_split_ms.R,
   rebuild fig15 and fig17). Target: collapse the sign flip toward zero across Baxter, SILC, Maine FIA, PEF,
   NB, CTRN, holding Baxter out.
4. Gate against the frozen v12.10.1 FIA NSVB result, the managed out-of-sample win over OSM, and, via the
   bakuzis-assessment skill, the five Bakuzis relations and the long-horizon density plateau. Byte-identical
   gate-off check.
5. If clean, v12.11 candidate; route the report through manuscript-preparer conventions.

## Files

- Fit scripts on Cardinal ~/magplot/verify/: fit_ingrowth_lever_v1211.R (+_step2,_step3),
  fit_mort_v1211.R, calibrate_rein.R, emit_ddbh_pertree.R, ddbh_ratio_byclass.csv, standtable_bydbh.csv.
- Chapter: refs/Weiskittel2011_ch10_linking_resolutions.pdf.
- Diagnosis: 20260718_longinterval_volume_diagnosis.md. Kickoff: 20260718_v1211_kickoff_spec.md.
