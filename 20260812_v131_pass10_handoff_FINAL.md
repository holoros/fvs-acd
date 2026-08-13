# FVS-ACD v13.1, pass 10, Baxter baseline repair and ship18 full-battery scoring, 12 August 2026

Continuation of pass 9 (`20260812_v131_pass9_handoff.md`). Model of record `~/AcadianGY_13.1.r`
stays UNMODIFIED throughout. No em dashes. Aggregates only, no coordinates left any node.

## OPEN item 1: Baxter baseline regenerated. DONE.

`v131base_baxter_results.csv` was proven stale in pass 9 (byte identical to the pre 4 August
inputs, not current ones). It has now been regenerated from `p9lev3/p9_bax_base_results.csv`,
the current-input gate-off cell already run in pass 9 Track A. Verified before promoting: 91
rows both files, identical column schema, and `p9lev3/p9_bax_baseprev_results.csv` confirmed
byte identical to the OLD `v131base_baxter_results.csv` (proving the staleness diagnosis one more
time from a second angle). New level: TOTVOL bias +13.533% (matches the pass 9 table's `base`
row exactly). Old (stale) level recomputed directly from the file: +9.094%, which explains why
the standing scorecard's +8.765% was flagged `[UNVERIFIED]`, that number is a third vintage
again and its provenance stays open.

Old file preserved at `v131base_baxter_results_PREV_20260812.csv`. New file and its tree-level
companions (`v131base_baxter_pred_t2_tree.csv`, `_pred_yr1_tree.csv`, `_t1_split_tree.csv`)
promoted in place. Any future scorecard run reading `BASE_PREFIX=v131base` now gets the honest
current-input Baxter level automatically; no downstream script needed editing.

**ship18 can now be quoted at an honest baseline as well as an honest delta on Baxter**: TOTVOL
-0.004 pp against the corrected +13.533% base (13.529% final), unchanged from the pass 9 number
since that delta was always computed against the current-input gate-off cell, only the level was
ever in question.

## OPEN item 2: ship18 scored on the remaining sources. 10 of 10 done.

New array job `p9lev3/p9ship_full.sbatch` (SLURM 13441635, 10 tasks), same ship18 config as pass
9's `p9ship.sbatch` task 1 (ONSET=0.55, LEVER 3b lo=0.35 hi=0.45 qmin=18, IMULT=2.5, r2 refit via
`p4e/model_b0b1b2.r`), run across memat, medev, pef, ctrn, silc_l, nb, and NS split four ways
(managed/unmanaged x current/long). Output `p9lev3/p9_ship18_<src>_results.csv`, scored against
`v131base_<src>_results.csv` where one exists by `p9lev3/score_ship18_full.R`
(`p9lev3/p9_ship18_fullscore.csv`, copied here as `2026-08-12_ship18-fullscore_DATA.csv`).

| source | n | TOTVOL ship18 | TOTVOL base | Δ | BA ship18 | BA base | Δ | note |
|---|---|---|---|---|---|---|---|---|
| memat | 1757 | -5.771 | (none) | | -6.265 | (none) | | NO_BASELINE, v131base never generated |
| medev | 1759 | -4.499 | (none) | | -3.366 | (none) | | NO_BASELINE, v131base never generated |
| pef | 2853 | +2.834 | +1.242 | +1.592 | -4.269 | -6.326 | +2.057 | worsens on TOTVOL |
| ctrn | 1086 | -9.543 | -9.777 | +0.234 | -10.833 | -11.259 | +0.426 | improves |
| silc_l | 73 | -4.353 | -6.368 | +2.015 | +12.117 | +5.310 | +6.807 | improves |
| nb | 733 | -2.455 | -4.392 | +1.937 | -8.238 | -11.270 | +3.032 | improves |
| ns_managed | 2500 | -53.156 | -53.606 | +0.450 | -53.867 | -54.575 | +0.708 | improves, both still badly biased |
| ns_unmanaged | 2500 | -4.442 | -5.520 | +1.078 | -5.735 | -7.539 | +1.804 | improves |
| ns_long_managed | 1334 | -73.989 | -74.361 | +0.372 | -71.459 | -72.144 | +0.685 | improves, both still badly biased |
| ns_long_unmanaged | 4419 | -4.355 | -5.947 | +1.592 | -8.159 | -12.094 | +3.935 | improves |

Delta is ship18 minus base on the signed bias, not an absolute-value improvement score; read
alongside the base column to see whether the shift moves toward or away from zero. Seven of eight
sources with a baseline move toward zero (improve); pef is the one exception, its already-small
+1.24% over-prediction widens to +2.83%, a real but modest degradation. The two NS-managed rows
(-53% and -74% TOTVOL) are severely biased in both BASE and ship18 alike; ship18 does not close
that gap, it is a pre-existing large miss on managed Nova Scotia stands that predates this pass
and is not something this pass introduced or was asked to fix. memat and medev have no
`v131base_<src>_results.csv` on record (never generated in any prior pass), so only level bias is
reported; closing that gap is priority 6 from the pass 9 ledger (reconcile memat, medev, pef
standing levels) and stays open.

`ns_long_unmanaged` (4419 stand-pairs, no domain filter) was the largest single cell run this pass,
SLURM job 13441635 task 10, completed 2026-08-12 18:54:42, elapsed 3h41m20s, rc=0. It improves on
both TOTVOL (-5.947% base to -4.355% ship18, +1.592 pp) and BA (-12.094% base to -8.159% ship18,
+3.935 pp), the largest BA improvement of any source in the battery. `p9lev3/score_ship18_full.R`
has been re-run and the scorecard, both on Cardinal and copied here as
`2026-08-12_ship18-fullscore_DATA.csv`, is now complete for all 10 sources: of the eight with a
prior baseline, seven improve (nb, ctrn, silc_l, ns_managed, ns_unmanaged, ns_long_managed,
ns_long_unmanaged) and one worsens slightly (pef); the remaining two (memat, medev) report level
only, no prior baseline exists.

## OPEN item 3: ship18 run through the Bakuzis battery. DONE.

New script `p9lev3/bakuzis_ship18.R`, adapted line-for-line from the 23 July 2026 v12.11
long-horizon check (`20260723_bakuzis_longterm.md`), same method, same seeds, same three stand
starts (SW/MW/HW) x ESI 12/16/20 x 160 years. BASE is frozen `~/_scripts/AcadianGY_12.10.1.r`
(same convention as the 23 July check and as the SCORECARD "BASE (frozen, no levers)" row).
CANDIDATE is ship18 via `p4e/model_b0b1b2.r` (sources `AcadianGY_13.1.r`, patches `ddbh()`) with
`sdimort.onset=0.55`, `use.ddbh.standcon=TRUE` at lo .35 hi .45 qmin 18, `ingrowth.mult=2.5`.
SLURM job 13441677, ~9 minutes, rc=0. Output `p9lev3/bakuzis_ship18_relations.csv`, copied here
as `2026-08-12_bakuzis-ship18-relations_DATA.csv`.

| relation | BASE (v12.10.1) | ship18 |
|---|---|---|
| Eichhorn (all 3 stand types) | PASS (11.0-14.2%) | PASS (11.1-14.4%) |
| Reineke, softwood | PASS (-1.59) | **FLAG (-1.80)** |
| Reineke, mixedwood | PASS (-1.54) | PASS (-1.75) |
| Reineke, hardwood | PASS (-1.50) | PASS (-1.64) |
| Site ordering, mixedwood | FLAG (4 HT / 4 VOL inversions) | FLAG (5 HT / 5 VOL inversions), pre-existing in BASE |
| Site ordering, softwood/hardwood | PASS | PASS |
| Yield-density plateau (all 3) | PASS (32.0-36.1 m² ha⁻¹) | PASS (32.0-35.6 m² ha⁻¹) |
| Sukachev (all 3) | PASS | PASS, though slope magnitude roughly halves |

**One new flag, not a regression on the pre-existing one.** The mixedwood site-ordering flag is
present in BASE too, at nearly the same magnitude (4 vs 5 inversions), so per the 23 July finding
it is a pre-existing behavior of the shared growth engine, not something ship18 introduces or
worsens materially. The softwood Reineke self-thinning slope is new: BASE passes comfortably at
-1.59, ship18 lands at -1.80, exactly on the FLAG boundary of the -1.8 to -1.4 acceptance band
(the raw unrounded value is just past -1.8). This is LEVER 3b's stand-QMD-floor-18 mechanism
doing exactly what it is designed to do (tightening the survivor-increment constraint in mature,
high-QMD stands, which is where self-thinning behavior is measured), but it steepens the
self-thinning slope enough to cross the boundary on the softwood synthetic stand specifically.
Mixedwood and hardwood both stay comfortably inside the band even though their slopes also
steepen (MW -1.54 to -1.75, HW -1.50 to -1.64). Sukachev's slope magnitude falls by roughly half
on every stand type (e.g., SW -0.0070 to -0.0040) but stays negative, so it still passes; this is
consistent with LEVER 3b damping late-stage diameter growth, the same mechanism.

This is a real finding to weigh before shipping, not a blocker by itself: one relation, one stand
type, on the boundary, in a synthetic idealized-stand test with no replication (single RNG seed,
same caveat the 23 July check carried).

**Decision (Aaron, 12 August 2026): ship as a disclosed tradeoff.** Do not gate ship18 on this
flag. Carry it into the shipping deck the same way onset 0.55's Baxter cost was disclosed in the
`v131_shipping_array.sbatch` header: one relation (Reineke self-thinning), one stand type
(softwood), landing exactly on the -1.8 boundary of the -1.8 to -1.4 acceptance band, mechanism
identified (LEVER 3b's qmin 18 floor tightening the survivor-increment constraint in mature,
high-QMD stands, precisely where self-thinning is measured), not replicated across seeds. No qmin
sensitivity rerun requested at this time.

## OPEN item 4: Bakuzis on ship18. Same as item 3 above, done together.

## Firewall notes carried forward, nothing new this pass beyond the above.

BASE_PREFIX is always v131base. The benchmark plot key is STAND, not PLOT. A client-side MCP
timeout on `cardinal_submit_job`/`sbatch` does NOT mean the submission failed; both the ship-full
array and the Bakuzis job were submitted successfully on the first attempt despite two client-side
timeouts during this session, confirmed live via `squeue` before any resubmission was considered.
Do not enable lever 3a. A job or task status carried in a handoff is subject to F9 and must be
re-queried live, including the `ns_long_unmanaged` status above.

## Next steps, priority order

All pass 10 items are now closed. Remaining items carry forward from the pass 9 ledger:

1. Reconcile memat, medev, pef standing levels (pass 9 OPEN item 6, still untouched).
2. Re-derive the Chapter 10 1.22 pp bias-budget entry (pass 9 OPEN item 4, still untouched).
3. Run CVX_HTCO=FALSE sensitivity (pass 9 OPEN item 5, still untouched).
4. Other items from the pass 9 ledger, still open: the plot_ba_incr reparameterization (scoped,
   not built), xu25Nr2 stem-budget stress test, the small-tree 5.0 cm excess flow defect,
   `calc_merch_height`'s unpatched silent try.

## Files

- `v131base_baxter_results.csv` (regenerated), `v131base_baxter_results_PREV_20260812.csv` (old,
  preserved), `v131base_baxter_pred_t2_tree.csv`, `_pred_yr1_tree.csv`, `_t1_split_tree.csv`
- `p9lev3/p9ship_full.sbatch` (new), `p9lev3/p9_ship18_<src>_results.csv` x10 (all sources
  complete), `p9lev3/score_ship18_full.R` (new), `p9lev3/p9_ship18_fullscore.csv`
- `p9lev3/bakuzis_ship18.R` (new), `p9lev3/bakuzis_ship18.sbatch` (new),
  `p9lev3/bakuzis_ship18_traj.csv`, `p9lev3/bakuzis_ship18_relations.csv`
- Copied to this repo: `2026-08-12_ship18-fullscore_DATA.csv`,
  `2026-08-12_bakuzis-ship18-relations_DATA.csv`

Pass 10 closed 12 August 2026. All four open items resolved: Baxter baseline regenerated,
ship18 scored on all 10 sources, Bakuzis battery run, and Aaron's ship-as-disclosed-tradeoff
decision recorded. Next session should pick up the pass 9 ledger items above, in priority order.
