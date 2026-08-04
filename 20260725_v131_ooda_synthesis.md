# FVS-ACD v13.1 OODA session synthesis, 25 July 2026

Aggregates only, no coordinates left the node, no em dashes. Continuation of 20260723_v131_pass2_status.md.

## Headline scientific finding
The developing-Maine-FIA volume underprediction (whole-plot -16.5%, subplot -24.7%) is NOT fixed by the
hierarchical mortality. Recruitment is the likely lever, and recruitment was mis-assembled. Two OODA cycles
established this cleanly.

## Cycle A: BASE parity failure (resolved)
Gated-off pipeline parity of the v131 harness vs the frozen base_pef failed (3.39e+03, all in predicted
columns). Root cause: the reused Jul 21 base_* rows are provenance-ambiguous, NOT a harness leak. Confirmed
decisively (job 12585148): the v12.11 harness gated OFF with MODEL_FILE=AcadianGY_13.1.r is byte-identical
(0.000e+00) to the v131 harness gated OFF. Fix: BASE regenerated with the v131 harness gated OFF
(v131base_*, all 11 sources present), aggregators repointed BASE_PREFIX=v131base, NS base reads rewired to the
split v131base_ns_* files. The regenerated BASE reproduces the v12.11 references (WP -16.53 vs -16.1, SP
-24.68 vs -24.8, OSM -6.29 vs -6.3), validating it. Stale base_* retired. Diagnosis:
20260724_v131_base_parity_diagnosis.md.

## Cycle B: subplot fit landed, ingrowth bug, first candidate scorecard, recruitment audit + refit

### Subplot fit (job 12547720) LANDED and harvested
Both submodels converged (mortality max_Rhat 1.015, recruit 1.0161; marginal but ESS healthy, 0 divergent).
region:eco identified at subplot grain (mort sd 0.232, l95 0.205 > 0), so the nested funnel is cured at
subplot grain. Variance ladder: plot 0.947, fortype 0.411, region 0.241, region:eco 0.232. Ranef exporting
(job 12611936). Wired for HIER_POSTDIR=~/v13_subplot via symlinks mapping the hook-expected names
(v131r_mortB_*, v131r_ingrowth_*, v131r_scaling.csv) to the subplot originals. NOTE: the hook reads
v131r_mortB_* (not v131r_mortBNS_*), so the whole-plot mortBNS posterior will need the same symlink treatment.

### Subplot mortality vs the v12.11 gate
Directionally consistent (higher RD lowers hazard) but far gentler and thresholdless: fitted hazard falls
~11% across RD 0.10 to 0.80 vs the v12.11 hand gate's ~86% near-step at RD0 0.38. The data want a gentle
density effect, not the steep hand-tuned attenuation. Caveat: rd is marginal net of lnqmd/ba which covary.

### First v13.1 candidate scorecard (subplot-mortality-only, job 12624990, 9 of 11 sources)
Hierarchical mortality ON (subplot posterior, population-level multiplicative hazard), recruitment OFF.
Result: essentially NEUTRAL on volume bias everywhere. Maine FIA whole-plot BASE -16.53 -> CANDIDATE -16.49
(+0.04 pp); every source moves < 0.4 pp from base. The hazard genuinely bites (candidate != base) but is too
gentle to move stand-level volume. Matches OSM -6.29. Conclusion: population-level subplot mortality alone is
not the lever for the developing-plot bias. Pending: mefia_subp (task 4) and ns_long_unmanaged (task 11) still
running; subplot candidate row expected near -24.6 (neutral). Watch items unaggravated: QC volume +1.24
(base +1.27), SILC BA +5.24 (base +5.31).

Selected scorecard (TOTVOL bias %, BASE / CANDIDATE / OSM):
- Baxter (mature, held-out): 9.09 / 8.71 / 12.37
- CTRN (managed): -9.78 / -9.46 / -4.81
- Maine FIA whole-plot (developing): -16.53 / -16.49 / -6.29
- Maine FIA subplot: -24.68 / pending / n/a
- PEF (developing): 1.24 / 1.24 / 0.26
- SILC (managed): -6.37 / -6.44 / -18.07
- NB MagPlot: -11.83 / -11.96 / -8.07
- QC MagPlot: 1.27 / 1.24 / n/a
- NS remeasurement: -38.44 / -38.30 / -29.22

### Ingrowth hook bug (fixed) and recruitment assembly bug (fixed + refitting)
The ingrowth-only preview exploded on PEF (ING_p 13 -> 186). Two defects:
1. Hook basis: SWITCH A applied the ingrowth posterior as an ABSOLUTE replacement while mortality is
   MULTIPLICATIVE. Fixed to multiplicative (modifier = 1 at training-mean covariates); PEF 186 -> 66; gate-off
   still 0.000e+00 (job 12612571). Backup ~/AcadianGY_13.1_PREV_20260725_ingfix.r. This is a structural choice
   to ratify.
2. Assembly (the deeper cause): recruit_tph expansion was bound to TPH2 (stand density, median 1466) instead
   of the per-tree microplot constant 185.243 ha-1. 18.4x per-tree / 19.2x global over-expansion (313.7 ->
   16.34 stems ha-1 yr-1 corrected). Because stand TPH ~ QMD^-2, the bug wrote a mechanical -2 ln_qmd term,
   inflating lnqmd (~40% of the fitted -2.37). Audit: 20260725_v131_recruit_tph_expansion_audit.md.
   FIX + REFIT (v6, job 12649942, output v131r_ingrowth2_*): sanity gate passed (corrected mean 16.339,
   byregion 3.2-45.5). Pre-fit glm.nb preview confirms: lnqmd_z -2.368 -> -1.245, ba_z +0.769 -> +0.292.
   Verification launcher staged ~/v131r_ingrowth2_verify_pef.slurm (expect PEF ING_p near base ~13 after).

## Jobs in flight at session close
- 12554985 v131mortBNS (whole-plot NS-inclusive mortality): 2d10h, chain 2 at 84% sampling, ~14h wall left,
  healthy (0 gamma rejects). Whole-plot posterior for the NS-in-fit candidate.
- 12649942 v131r_ing2 (corrected recruitment refit): running, ~18h, output v131r_ingrowth2_*.
- 12624990 tasks 4, 11 (subplot candidate tail): running; rerun the aggregator to fill the SP candidate row.
- 12611936 subplot ranef export: running.

## Decisions for Aaron (surfaced, not blocking)
1. Ratify the ingrowth hook change absolute -> multiplicative (gate-safe, mirrors mortality).
2. Given hierarchical mortality scores neutral and its density signal is gentle/thresholdless, the v13.1
   mortality story is "keep the sign, drop the steep v12.11 hand gate" rather than a bias fix. The bias lever
   is recruitment (now being refit). Confirm the candidate direction: corrected hierarchical recruitment +
   gentle hierarchical mortality, dropping the v12.11 hand levers.

## Next mechanical steps (when jobs land)
1. mortBNS lands -> symlink v131r_mortBNS_* to the hook-expected v131r_mortB_* names (as done for subplot),
   confirm convergence + identified region:eco, then the whole-plot-mortality candidate.
2. v131r_ingrowth2 lands -> run the staged PEF verification (ING_p near 13), then a recruitment-ON candidate
   and the combined recruitment+mortality candidate scorecard.
3. Finish the subplot candidate row (rerun aggregator after tasks 4/11).
4. Full validation battery (Bakuzis, plateau, maturity Baxter-held-out) on the chosen candidate; deliverables.
