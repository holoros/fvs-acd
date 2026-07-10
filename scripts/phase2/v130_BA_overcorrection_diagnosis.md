# v13.0 basal-area over-correction: root-cause diagnosis

*Phase 2, 10 July 2026. Diagnosis of why the cb_v130 BA net-increment anchor inverts BA bias from -9.81% to +9.83% pooled (NB -8.84% to +25.96%, QMD_small -13.98% to +35.75%, ESI_low -11.97% to +19.22%) while the height half behaves. Browser-free, code-only, nothing executed. No em dashes.*

## Verdict

The BA re-anchor is salvageable, and the catastrophe is a single coding bug, not a failure of the science. The correction reads its per-step time length from `tree$year[1]`, but in this model `tree$year` is the cumulative elapsed-year counter, not the length of the current step. Because the harness calls `AcadianGYOneStand` once per year and increments `year` by one inside every call, on call k the correction demands a net BA increment of `tnet * k` delivered in a single one-year growth step, instead of `tnet * 1`. The escalating demand pins the survivor diameter-increment scale at its upper clamp for the back half of every multi-year interval, so the correction over-delivers by roughly two-fold and inverts the bias. The fix is to make the step the model's own within-call clock advance (which is exactly one year), and to tighten the per-year survivor-increment clamp. A ship-height-only fallback is not necessary.

The other three hypotheses are secondary or absent. Net-versus-gross is handled correctly in the code. Anchor transfer to near-asymptotic mature stands is a real but minor second-order concern that the fix hedges with a bounded-nudge gain. The quadratic scale s is neither unbounded nor mis-signed; the only mis-scale is the step multiplier.

## The mechanism, from the code

The correction runs inside `AcadianGYOneStand` (figures/_data/AcadianGY_12.9.2.r, the structural twin of the frozen 12.10.1 base). The order within one call is: snapshot at function entry (EDIT2a), grow every tree by ddbh (the Output block, `year = year + 1` at line 3563), SDImax self-thinning mortality that builds `sdm_rd` (lines 3649 to 3662, captured by EDIT2b), append ingrowth (line 3680), then the BA correction (EDIT2c, inserted before the return select at line 3686).

EDIT2a captures the true start-of-step state before any growth: `.v130_ba0`, `.v130_qmd0`, `.v130_N0`, and the per-id start diameters `.v130_d0_by_id`. That part is correct.

EDIT2c then computes:

```
.v130_step <- tryCatch(as.numeric(tree$year[1]), error=function(e) 1); if (!is.finite(.v130_step) || .v130_step < 1) .v130_step <- 1
.v130_tnet <- 3.213247 - 0.00436607*.v130_ba0 - 0.159089*.v130_rd0 - 1.021738*log(.v130_qmd0)
.v130_batar <- .v130_ba0 + .v130_tnet * .v130_step
```

The failure is on the first line. The harness (scripts/comprehensive_bench.R line 61) seeds the tree list with `year = 0` and then loops `for (yr in seq_len(iv)) { nx <- AcadianGYOneStand(...); cur <- bf(nx) }` (line 64), carrying the returned tree list, with its incremented `year`, into the next call. `bf()` does not reset `year`. So at the correction point on call k the tree carries `year = k` (entry `k - 1`, plus one from the line 3563 mutate). The smoke harness (scripts/cardinal_v130_smoke.R line 131) has the identical carry-forward loop, so the behavior is not an artifact of one driver.

The anchor `net_ba_ann` is a NET ANNUAL increment in m2 ha-1 yr-1, and the correction is applied once per annual call, so the correct step is 1 every call. Instead `.v130_step` takes the values 1, 2, 3, ..., iv across the interval. The build spec even states the intent, "step = tree interval in years (annual step = 1)"; the author assumed `tree$year[1]` held the step length when it actually holds the running clock. That single wrong assumption is the whole event.

## Why an escalating step produces exactly this magnitude

Let s* be the survivor-increment scale a correctly stepped correction would choose in a given year, that is the scale that makes the one-year net increment equal `tnet`. Because the frozen baseline under-predicts BA by about 9%, the anchor asks for modestly more growth than the stand naturally puts on, so s* sits a bit above 1, on the order of 2 for the vigorous buckets. The buggy correction instead solves for `tnet * k` in one year, so the scale it wants is approximately `s* * k`, then clamped to the band [0.25, 4].

With s* near 2 the product s* k reaches the ceiling of 4 by k = 2. So from the second year of every interval onward the survivor diameter increments are quadrupled, year after year, rather than the intended roughly two-fold. Over an eight-year interval the applied scale runs 2, 4, 4, 4, 4, 4, 4, 4 against an intended 2 every year. The ratio of delivered extra growth to intended extra growth is about (2 + 4*7) / (8*2) = 30/16 = 1.9. The correction therefore over-delivers the intended BA nudge by roughly a factor of 1.9.

That factor closes the loop on the numbers. The intended nudge moves BA from -9% to 0, which is about +9% of ending BA. Delivering 1.9 times that extra is about +17%, leaving a net of -9% + 17% = +8%, against the observed pooled +9.83%. The buckets with the longest remeasurement intervals and the largest natural survivor increments overshoot the most: NB (long intervals, vigorous mid-density stands) lands at +25.96%, and QMD_small at +35.75% because small trees carry large relative diameter increments and the BA solve weights them by the squared-increment term `.v130_C = sum(k_ba * e1s * dd^2)`, which amplifies the scaling of small fast-growing stems. TOTVOL follows BA and worse (+10.04%) because NSVB volume scales with dbh-squared times height, so inflated survivor diameters push volume even harder than BA. Every sign, ordering, and magnitude in the gate result is consistent with the escalating-step mechanism and with nothing else.

## Ranked hypotheses

1. COMPOUNDING through an escalating per-call step (hypothesis a, with the specific coding fault that drives it). This is the root cause. The correction is re-applied every annual call, which is by itself the intended design, but the step it re-applies is `tnet * k` rather than `tnet * 1`, so each year demands several years of net growth at once and the survivor scale saturates at its ceiling. The compounding is not a slow drift from a small per-year bias; it is a large, structural, linearly escalating over-demand that pins the clamp. Fixing the step converts the runaway into the intended bounded per-year re-anchor.

2. ANCHOR TRANSFER to near-asymptotic mature stands (hypothesis c). Real but second order. The FIA CONUS fit predicts more BA growth than these mature MagPlot NB stands naturally realize, which is precisely why the baseline under-predicts them and why the anchor points in the right direction. Even a correctly stepped exact match could still over-add slightly on stands sitting near their asymptote, because forcing an exact match each year removes the stand's own deceleration. This is a dampening question, not a bug, and the candidate fix hedges it with a gain that turns the exact match into a bounded nudge. It cannot by itself explain a swing to +26 to +36%; that requires the step escalation.

3. NET versus GROSS baseline (hypothesis b). Not the cause. The snapshot `.v130_ba0` is taken at function entry before any growth, and the correction runs after growth, after SDImax mortality, and after ingrowth is appended, so the realized quantity the solve matches is the true end-of-step stand BA on the same NET basis the anchor was fit on. Ingrowth BA is held fixed and subtracted out through `.v130_baing` and `.v130_Tsurv = .v130_batar - .v130_baing`, and the survivor expansion factors used in the quadratic are post-mortality. The net basis is correct.

4. UNBOUNDED or mis-signed scale s (hypothesis d). Not present as stated. The quadratic `C s^2 + B s + (A - Tsurv) = 0` takes the positive root, A, B, and C are positive for growing survivors, and s is guarded to [0.25, 4] with a non-finite fallback of 1, so it is bounded and correctly signed. The genuine mis-scale is the step multiplier feeding `.v130_batar`, not s. The one real weakness in the clamp is that [0.25, 4] is far too loose for a single-year survivor-increment scale, which is why the ceiling of 4 still lets the bug quadruple growth rather than merely nudge it.

## Recommendation and the fix

Ship v13.0 with the BA half repaired, not height-only. Two changes, both in the inserted R:

First and decisive, make the step the model's own within-call clock advance rather than the absolute clock. Snapshot the entry year in EDIT2a as `.v130_year0 <- tree$year[1]`, and in EDIT2c set `.v130_step <- tree$year[1] - .v130_year0`, which is exactly one for the annual loop and generalizes to any true multi-year step a future driver might use. This alone converts the runaway into the intended per-year re-anchor.

Second, as a guard and a hedge on the anchor-transfer concern, tighten the survivor-increment clamp from [0.25, 4] to a physically sane single-year band of [0.7, 1.5], and expose a bounded-nudge gain `ops$ba.anchor.gain` in [0, 1] that shrinks the solved scale toward 1, so the correction can be a damped nudge toward the anchor rather than an exact yearly match. The gain defaults to 1, which is the intended exact match and is now safe because the step is correct; if the smoke test shows the corrected exact match still over-adds on mature NB (the residual hypothesis-c risk), dial the gain to about 0.5.

The candidate builder implementing both changes is scripts/phase2/build_v130_baonly_v2.py. Re-run the four-point smoke test (top-height increment down and tracking the M2 target, stand net BA increment rising toward but not overshooting the anchor, TOTVOL finite and sane, no stand errors), then comprehensive_bench.R with CONFIG_TAG=cb_v130 and the v130_score_gate.R against cb_v12101. Expect BA bias to land near zero rather than at either extreme, and TOTVOL to track BA.
