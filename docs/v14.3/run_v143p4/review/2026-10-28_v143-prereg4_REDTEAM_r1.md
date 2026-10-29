# PREREG4 plan red team, round 1 (fresh read of revision 0)

28 October 2026. Read of `plan/2026-10-28_v143_senescence-forest-type_PREREG4.md` revision 0 against the sources it cites (benchmark README and `analysis_r1` CSVs, `explore/e0_*.out`, `explore/e1_*.out`, the 14.0.4 engine, the bench141 and long200 launchers, the acdx arms build). Items are MUST (would make a verdict wrong or untraceable), SHOULD (ambiguity a script writer would have to resolve) and NOTE.

## MUST

- **M1, E0 overstated.** The plan says the floor exceeded the Garcia kill "in every one of the 36,720 stand steps". The E0 output gives `share_floor_binds` 1 at three decimals, which means at least 0.9995, not every step. Restate as printed.
- **M2, E1 overstated.** "About a fifth of FIA aspen-birch and maple-beech-birch stands" is 45 of 164 (0.27) and 38 of 237 (0.16) in the E1 output. Give the counts.
- **M3, background numbers.** "At most 2% of stands" for 13.1h is 0.022 in white-red pine-hemlock; "0.00 to 0.30" for the curve probabilities is 0 to 0.305. Quote as in the file.
- **M4, run completeness.** Nothing stops a candidate that silently fails stands (RUN_OK 0) from scoring well on a smaller set. Add a harness gate: in each of the 19 sets and the 200 yr frame the candidate runs at least 99% of the stands frozen 14.1 ran, and every comparison is paired on stands that ran in every compared arm.
- **M5, H3 pass condition undefined when few sets match.** State the pairing used for the bridge (stands that ran in frozen v141LT and v141off, as bench141 paired them) and fail the gate if fewer than 15 of the 19 sets match on stand count for any metric.
- **M6, H2 comparison unit.** The grid arms run through STAND_KEEP_FILE, so their chunk files do not align with the frozen chunks. The identity check must concatenate chunks and compare by stand on the arm's stand set (with the frozen outputs filtered to it), not file by file.

## SHOULD

- **S1, floor domain definition.** Define "the floor set the kill" for one plot year: fit_ok is FALSE, or N1 (1 - pf) is below N2_L1. Plot years are the trace calls.
- **S2, t2 list content.** Confirm in the frame step that the t2 lists hold live trees only; if any t2 record has EXPF at or below 0, count it as dead.
- **S3, t1 Dq for the S population.** Say that it is computed from the frame t1 list (all records, expansion weighted).
- **S4, seeds.** Name one seed for every bootstrap (fit, hindcast scores, long run intervals) and say that 14.1 is rescored with the same seed on the same paired stands.
- **S5, BK3 baseline.** 14.1's fold B interval must be recomputed from the frozen long200 v141LT trajectories on the same fold B stands.
- **S6, LR1 comparability.** The projection window (200 yr from the stand's current age) and the curve horizon (peak before 250 yr of age) differ. State this as a limit and why the 0.30 tolerance is wide.
- **S7, figure.** Specify the figure: share declining by FIA type for 13.1h, 14.1, each candidate and D1, fold B, with 95% stand bootstrap intervals and the curve probability marked.
- **S8, growth shortfall in the calibration.** 14.1's diameter growth is low on mefia_l_c (QMD bias -6.3 to -12.0% across versions, README), so predicted basal area of dying stems is slightly low and delta is pushed up. Name as a limit.

## NOTE

- **N1.** Say that the same delta for both classes in every grid arm is what makes per class interpolation valid when a stand changes class inside a hindcast interval.
- **N2.** Record E0 and E1 job numbers and that both read no observed mortality (already stated; keep).
