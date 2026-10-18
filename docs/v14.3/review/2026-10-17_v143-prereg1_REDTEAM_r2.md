# Red team r2: v143 PREREG1 draft 2

17 October 2026. Independent reviewer, repo read only. Draft 2 md5 525e4551 matches the change log.

Verified against the files: every md5, gap, tol, uplift (as gap differences), the P3 references 0.977 and 0.650, 827/781, 128, m_T 4.045, the coefficients and cap, 119/17, stand counts, the 20 grid cells, the GT3 bounds and PREREG46 TR. Probe counts are internally consistent (762 and 827 sum correctly) but unverified.

## New findings

**R2-1 MUST. Missing pre visit, not the threshold, decides N1.** Plan: "A stand that lacks a pre visit ... is ineligible"; only 30 of 134 thinned CTRN locations have one. So every arm withdraws T from about 104 thinned ctrn_c locations, and from any pef_c stand without a pre thinning visit (count not given). "Every CTRN location is eligible ... by construction" holds only for the 30. N1 measures the data rule. **Repair:** add a null arm A_pv (T only where a pre visit exists, no threshold), score N1 for each arm against both 14.1 and A_pv, report "ineligible, missing" apart from "ineligible, threshold" in every frame, and register the pef_c pre visit count before any run.

**R2-2 MUST. P1 heavy may be unattainable because of L, and rule 2 does not catch it.** Eligibility is fixed per stand, so every arm's stand result is either the 14.1 or the A0 result. P1 needs the heavy gap to fall from 1.391 to 0.346, that is 1.045 of the 1.162 uplift, so S must be at least 0.90 even if T is withheld from every heavy stand. Rule 2's 0.5 therefore never binds; for S between 0.5 and 0.9 every arm fails P1 because L contributes more than 0.117, and rule 3 records that as an eligibility failure. Rule 2 is also undefined if A0 fails rule 1. **Repair:** after A0, gate feasibility: if the paired heavy gA0 exceeds tol, close as "L limited, no eligibility rule can pass P1" before reading A1 to A3; drop or reset the S threshold to match; state that A0 must pass rule 1 for any verdict.

**R2-3 MUST. A pass does not discriminate HG from HR.** Plan: "If HR holds, no eligibility arm can pass P1 to P3." False for A1 and A2. RF above the CTRN maximum withholds T from nearly all heavy and much intermediate stands whatever the mechanism, and light keeps T, so P1 to P3 can pass under HR. Rule 5 never consults the survivor diagnostic. **Repair:** add a seeded placebo arm with random eligibility at each arm's per class eligible share; a candidate must beat its placebo on the paired heavy and intermediate gaps, or rule 5 must require the registered HG survivor pattern.

**R2-4 SHOULD. The HR prediction is mis-specified.** m_T minus 1 scales with (d/Dq)^2 (14.1.r L68-71), so an inflated alpha also concentrates excess above 1.15 Dq; "spread across d/Dq classes" is not what HR predicts. DQR below 1 stands can carry higher d/Dq within the open top class and other tst, so they differ under HR too; "no difference" has no margin. **Repair:** compare the realized multiplier (observed over A0 predicted increment) with 14.1's m_T, matched on d/Dq class and tst, with a registered margin; state which Dq defines the classes.

**R2-5 SHOULD. The plan misstates the r1 fate rule, and DQR is only a proxy.** Plan: "Trees dying between the pre visit and the removal are counted as removed in mefia_ph_c (r1 rule)." class_r1 L24-26 assigns STATUSCD 2 with any agent but 80 to "died", which is neither cut nor retained. The engine's Dq covers every stem at 2.54 cm and above (builder L27, 14.1.r L143-145) at v1, tst years after the cut, while DQR uses stems at 12.7 cm and above at v0. **Repair:** exclude died trees from both parts as the primary rule and count them as removed in a stress run; correct the sentence; report the engine counters thinning_calls_at_cap and max_rel_dq_seen (14.1.r L116-117) by class and arm.

**R2-6 SHOULD. A3's bound sits where removals across diameter classes land.** A proportional removal gives DQR near 1, so eligibility there is set by sampling noise on a 4 subplot plot, worst after heavy removals leaving few stems at 12.7 cm and above. Using v0 diameters for both parts is sound: growth over the lag largely cancels in the ratio. **Repair:** register a minimum retained tree count (below it, "ineligible, missing"); report the share of stands with DQR in 0.95 to 1.05 by class; add 1.05 to the stress test.

**R2-7 SHOULD. The 30 location subset makes A1 and A2 restrictive.** The maximum of a subset is at or below the maximum of the full set, so RF_MAX is biased low and RD_MIN high. That favors P1 and P2, penalizes N1 and N2, and both percentile variants are more restrictive still. ctrn_c has 134 thinned locations against 119 in the estimation set, so the 30 are not shown to be inside the T support; GT6 caps d/Dq (PREREG2_r5 L203), not RF. **Repair:** intersect the 30 with the 119; state the direction of the bias; add one less restrictive variant; relabel the provenance "by analogy with GT6".

**R2-8 SHOULD. P3's margin is a full tol.** Light could reach an absolute gap of 1.09 (0.459 + 0.632), outside the tol applied in P1 and P2, and still pass "no harm". **Repair:** require the light and low volume absolute gaps to stay within tol and the paired worsening upper limit to be at most 0.5 tol, or justify the margin.

**R2-9 NOTE.** P4 cannot bind: a P1 pass implies a reduction of at least 1.045. Report, do not gate.

**R2-10 NOTE.** The 0.05 tie break has no provenance, sits below the bootstrap resolution (heavy half width about 0.26) and overrides the stated A3, A1, A2 order. Use the order alone or a paired interval.

**R2-11 NOTE.** The PREREG45 floor is 30 trees per bin (L54), applied here to stands; label it borrowed. Register the bootstrap seed; say whether P5 is a point test.

**R2-12 NOTE.** Rule 6 removes the mefia_l_c validation (builder L98-131, height source and ESI extraction) and names no replacement for NH and VT. Nor does it require 14.1 to show the heavy gap there.

## Round 1 disposition

| r1 | Status | Reason |
|:--|:--|:--|
| F1 | PARTIAL | Died fate unassigned, engine Dq proxy (R2-5) |
| F2 | CLOSED | CTRN only; E0b from TST files |
| F3 | PARTIAL | No minimum eligible n per class and arm, no "uninformative" verdict |
| F4 | PARTIAL | S threshold inconsistent with P1 (R2-2) |
| F5 | PARTIAL | R2-8, R2-9 |
| F6 | PARTIAL | Diagnostic not gating; A1 relabels (R2-3) |
| F7 | PARTIAL | R2-3, R2-4 |
| F8 | CLOSED | Sweep; P5 borrowed |
| F9 | PARTIAL | R2-1 |
| F10 | PARTIAL | R2-12 |
| F11 | CLOSED | Type reporting, tst 17 split |
| F12 | CLOSED | CAP gate |
| F13 | CLOSED | Low volume in P3 |
| F14 | CLOSED | Basal area stated |
| F15 | CLOSED | Cardinal named |

Verdict: not registrable. Fix R2-1 to R2-3 before thresholds are computed.
