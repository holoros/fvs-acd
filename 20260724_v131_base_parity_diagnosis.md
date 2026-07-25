# FVS-ACD v13.1 BASE parity diagnosis: the reused base_* rows are provenance-ambiguous and must be retired

*24 July 2026. OODA diagnosis track. This document records, for the project archive, why the frozen `base_*_results.csv`
rows carried over from v12.11 cannot serve as the BASE arm of the v13.1 scorecard, and specifies the fix: BASE must be
regenerated with the v13.1 harness gated OFF so that BASE and the candidate come from the identical harness and differ
only by the posterior switches. Aggregates only, no coordinates leave the node, no em dashes. This is a new artifact and
overwrites nothing.*

## Symptom

A gate-off parity check of the v13.1 harness against the frozen v12.11 BASE fails. Running the v13.1 harness on PEF with
both posterior switches OFF (`v131off_pef`: the v13.1 harness, `AcadianGY_13.1.r`, `USE_HIER_ING=FALSE`,
`USE_HIER_MORT=FALSE`) and comparing the per-stand result rows against the frozen `base_pef_results.csv` gives a maximum
absolute difference of 3.39e+03 and a `GATEOFF_PIPELINE_IDENTICAL FALSE` verdict. If the reused BASE rows were truly a
gated-off equivalent of the same pipeline, this check would return 0.000e+00. It does not.

## Localization: the diff is entirely in the predicted columns, not the inputs

The 3.39e+03 discrepancy lives entirely in the predicted `_p` columns. The largest per-column maximum absolute
differences are in the volume and density predictions:

| Column | Max abs diff | Meaning |
|---|---|---|
| VALUE_s_p | 3390 | predicted merchantable value, softwood split |
| VALUE_p | 191 | predicted total value |
| SAWVOL_s_p | 52 | predicted sawlog volume, softwood split |
| SDI_p | 21 | predicted stand density index |
| TOPHT_p | 4.2 | predicted top height |
| TOTVOL_p | 4.2 | predicted total volume |

The differences touch 2709 of 2853 stands. Critically, the 23 observed and identifier columns (the `_o` observed values,
the `_t1` initial-state columns, and the stand and source identifiers) are byte-identical between the two files. The
inputs and the observations agree; only the projection differs. So this is not a data-mismatch or a different fitset. It
is the projection engine, or the provenance of the projection, that differs.

## Contrast: the model equations gate off correctly

The model equations themselves gate off cleanly. The dedicated stand-level gate-off check (SLURM job 12568080,
`gateoff_v131.R`) drives `AcadianGY_13.1.r` with the switches OFF against the frozen 12.10.1 model and returns a maximum
absolute difference of 0.000e+00 over the projection. So `AcadianGY_13.1.r` with `use.hier.ingrowth` and
`use.hier.mortality` OFF reproduces shipped 12.10.1 at the model level, byte for byte. The gate contract on the equations
holds. The failure in the parity check is therefore not in the model equations; it is at the harness and provenance
level, in how the frozen `base_*_results.csv` rows were produced versus how the v13.1 harness produces them.

## Provenance evidence

The frozen `base_*_results.csv` files are provenance-ambiguous:

1. They were generated on 21 July across a day of iterating on the harness, not in a single controlled pass. The file
   timestamps show duplicate source names produced four hours apart (for example `base_me_fia_l` versus `base_mefia_l`),
   which is the signature of a naming and configuration convention that was still in flux while the files were being
   written.
2. The v12.11 candidate array that these BASE files were paired with only claims a spot check against `cb_v12101` and
   `score_baxter`, not a full re-verification of every BASE source against the frozen 12.10.1 pipeline. The identity of
   the BASE rows to a controlled gate-off pipeline was assumed, never demonstrated across sources.
3. The residual has an anchor and ESI signature: the top-height-scale offset (TOPHT_p max abs diff 4.2, propagating into
   the volume and value columns through the height-driven volume equations) is consistent with a difference in the
   dominant-height anchor or the ESI site input between the pipeline that wrote the frozen BASE and the current v13.1
   harness. That is exactly the kind of harness-level provenance drift that a day of iterating on naming and site
   configuration would introduce, and it is not something the gated model equations can cause, since those are proven
   identical.

Taken together: the inputs match, the model equations gate off perfectly, yet the frozen BASE projections differ from a
clean gated-off v13.1 run. The only remaining explanation is that the frozen BASE rows were written by a
harness/provenance state that is no longer reproducible and no longer matches the controlled pipeline.

## Conclusion

The reused `base_*_results.csv` rows are provenance-ambiguous and must be RETIRED as the BASE arm of the v13.1 scorecard.
They cannot be trusted as a gated-off equivalent because their provenance cannot be reconstructed and a controlled
gated-off run does not reproduce them.

BASE for the v13.1 scorecard must be REGENERATED with the v13.1 harness gated OFF (`MODEL_FILE=~/AcadianGY_13.1.r`,
`USE_HIER_ING=FALSE`, `USE_HIER_MORT=FALSE`), which is byte-identical to 12.10.1 at the model level (job 12568080,
0.000e+00). Regenerating BASE this way guarantees that BASE and the candidate come from the identical harness and differ
only by the posterior switches, so any scorecard difference is attributable to the posteriors and not to harness drift.
This is the only configuration under which a v13.1 candidate-versus-BASE comparison is clean.

## Corrective actions and status

- BASE regeneration. A sibling track is regenerating the self-consistent BASE with the v13.1 harness gated OFF
  (`v131base_*_results.csv`) and repointing the scorecard BASE_PREFIX to `v131base`. IN PROGRESS.
- Leak confirmation. A confirmation track is verifying that the v13.1 harness gated OFF equals the v12.11 harness gated
  OFF (no gated-off leak from the posterior wiring into the frozen pipeline). IN PROGRESS.
- Model-equation gate-off. Proven identical at the stand level (job 12568080, `gateoff_v131.R`, 0.000e+00). DONE.
- Documentation. The battery-ready addendum and the deliverables plan are corrected to retire the byte-identical BASE
  reuse assumption and to instruct regeneration via the v131 base array with BASE_PREFIX=v131base (this pass). DONE.
- Scorecard scope. No v13.1 scorecard number may be computed against the stale `base_*` files. All BASE comparisons must
  use the regenerated `v131base_*` rows once they land. STANDING INSTRUCTION.

## Comparison plan for the ingrowth-only candidate (this track's Deliverable 1)

The ingrowth-only candidate array (`~/magplot/verify/v131_ing_array.sbatch`, `USE_HIER_ING=TRUE`,
`USE_HIER_MORT=FALSE`, `CONFIG_TAG=v131ing_<src>`, ME sources baxter/silc_l/mefia_l/pef/ctrn) is submitted to preview the
recruitment effect before the mortality posterior lands. Once both `v131ing_<src>_results.csv` and the regenerated
`v131base_<src>_results.csv` exist, compute TOTVOL and BA bias of the ingrowth candidate versus the regenerated BASE to
isolate the hierarchical-recruitment effect. Do NOT compare against the stale `base_*` files: doing so would confound the
recruitment effect with the harness-provenance drift diagnosed above. The comparison is deferred until both file sets
land; it does not gate on run completion here.
