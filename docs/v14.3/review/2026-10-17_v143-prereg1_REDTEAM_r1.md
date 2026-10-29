# Red team r1: v143 PREREG1 draft

17 October 2026. Independent reviewer, repo read only.

Verified correct: 0.346, 0.515 and 0.632 (25% of 1.3855, 2.0611, 2.5271); the reference gaps 0.459, -1.436 and -1.109; "no frozen version clears P1 to P3"; 827 stands on 781 plots; 128 disturbed stands; m_T at tst 1 and the cap = 4.045; both md5s.

- **F1 MUST. RF, RD_res and DQR are not computable as defined, and they are not comparable across frames.** Plan: "RF is removed over pre-removal basal area of live trees in the engine tree list." The mefia_ph_c engine list is the post-harvest v1 list (frame_builder L7, L155). Pre-removal trees exist only in v0 FIA records, and r1 links only v0 trees with DIA >= 5 in, counting a tree with no v1 record as cut (class_r1 L114, L119-121). The lists start at 2.54 cm with saplings at 74.965 TPA (builder L27, L90), and the engine Dq uses every tree (14.1.r L143-145). FIA "after" is tst years after the cut and includes ingrowth; "before" is years ahead of it. CTRN differs in both lag and floor. **Repair:** for each quantity, give the source table, the visit, the lag to the removal and one DBH floor, the same across mefia_ph_c, the T frame, ctrn_c/ctrn_fl and the grid. Extend the harness stop to every gated frame.

- **F2 MUST. The T set is CTRN only, so the E0b and N1 partitions rest on a wrong premise.** Plan: "fitted on CTRN and BAXTER commercial thinnings"; E0b and N1 name BAXTER. PREREG2_r5 L150 says "The T estimation set holds 119 locations nested in 17 installations" (CTRN). BAXTER enters only L (L190 "D1 BAXTER after L", GL5). bench141 supplies a TST_FILE for every Maine set (htfix sbatch L74-76), so known tst in pef, silc, medev or memat is unverified, and if any carries it a correct arm fails E0b. **Repair:** define E0b from the per-set TST files (known-tst counts), take BAXTER out of N1 unless it has known tst, and correct the text.

- **F3 MUST. The known-tst share is left [UNKNOWN] although it decides whether A1 to A3 can act at all.** An UNKNOWN stand is inert in every arm (14.1.r L111). The share can be read from the TST file without touching any outcome (builder L235, L260). **Repair:** tabulate known tst by class before registration and register a minimum count per gated class. Below it, the verdict is "uninformative", not "fail".

- **F4 MUST. Rule 2 is a non sequitur.** "A0 fails P1: T is not the main cause." Example: L adds 0.2 and T adds 0.96, so A0 = 0.43 fails P1 although T is 83% of the gap. Because m_T >= 1 (14.1.r L68-71), A1 to A3 lie roughly between A0 and 14.1, so rule 3 already covers the case. A0 also runs through rules 3 to 6 "per arm". **Repair:** define the T share as (g141 - gA0)/(g141 - gL2) with a paired plot bootstrap, and call T the main cause if the lower limit exceeds 0.5. State that this is T given L (the terms multiply, 14.1.r L106-114). Bar A0 from candidacy.

- **F5 SHOULD. Point-estimate gates are as noisy as their tolerances.** The 14.1 half-widths are about 0.26, 0.31 and 0.54 against 0.346, 0.515 and 0.632 (by_type CSV). P4's "non-overlap, paired on plots" contradicts itself, and any arm that passes P1 clears it anyway. **Repair:** make P3 a paired no-harm test (upper limit of arm minus 14.1 at or below a stated margin), make P4 a paired-difference interval that excludes 0, and report P1 and P2 with their intervals.

- **F6 SHOULD. A1 nearly restates the class definition.** RF comes from the same v0 to v1 tree-linked removal that defines "heavy" (class_r1 L129-132). The stress variants at 0.35 and 0.65 are the class bounds themselves, so at 0.65 the heavy class is ineligible by construction. P1 therefore cannot separate mechanism from relabeling. **Repair:** add a classifier-independent test, the v1 to v2 survivor diameter increment ratio by d/Dq class, eligible against ineligible within a class, and mark the FCCL-bound variants as non-evidential.

- **F7 SHOULD. The benchmark does not single out heavy removals.** The 14.1 minus L2 uplift by class is +1.895 (light), +1.806 (intermediate), +1.162 (heavy) and +1.367 (low volume), computed from the CSV. Heavy has the smallest uplift in absolute terms and the largest only per unit of t1 stock. P2 (14.1 at 1.41) passes only if T is also withheld from intermediate removals, which are partial removals. **Repair:** register the uplift pattern the geometry hypothesis predicts against "T too strong everywhere", and state that P1 to P3 jointly require stripping T from intermediate stands.

- **F8 SHOULD. Threshold provenance.** The ±25% band was fixed for an AGB level intercept (README L50; int_region = 0.25 x t2 AGB). Applying it to rates is a post-read choice, made knowing that L2 passes P1 and P2. The "E1 window" cited for P5 applied to NS and NS_LONG total volume (VERSION_HISTORY L419-420), not to AGB. **Repair:** report every verdict at ±15%, ±25% and ±35%, and label P5 as borrowed.

- **F9 SHOULD. N1 can barely fail, and N2's domain is assumed.** The thresholds are the CTRN extremes, so every fit stand is eligible by construction. Those extremes come from 17 installations with designed treatments, so they are close to prescription values. **Repair:** in the TH step, compute the three quantities for the 20 grid cells and for ctrn_c/ctrn_fl, and record any that fall outside support before any arm output exists.

- **F10 SHOULD. Rule 6 cannot reuse "the same builder".** It hard-codes ME_PLOT, ME_COND and ME_TREE (L36, L54, L80), JURIS "ME" (L163), validation against mefia_l_c (L98-131) and the Acadian ESI raster, with only cov30m stands admitted (L21, L256). Rule 6 also sets no minimum n and gates only point estimates. **Repair:** register the builder diff, ESI coverage of NH and VT, a minimum n per class, and P5 plus the paired P3.

- **F11 SHOULD. The extrapolation domain is unbounded.** T comes from CTRN spruce-fir with tst support of 1 to 17 yr (VERSION_HISTORY L376). mefia_ph_c includes hardwood types. **Repair:** report gaps by FORTYPGRP_V0 and the known-tst range against 1 to 17 yr.

- **F12 NOTE.** The cap is not read from the rds. It comes from V141_RELCAP (sbatch L76). An unset value is NA, not NULL, so the rds rel_cap is never reached (14.1.r L138, L160). Assert that the two are equal.

- **F13 NOTE.** Low volume (269 stands, the largest class) is gated only by P5. Include it in the no-harm test.

- **F14 NOTE.** A1's purpose line is wrong: FCCL classifies on merchantable volume (README L46), while A1 uses basal area.

- **F15 NOTE.** "The compute host" is unnamed. The standing default is firebreather, which has been unreachable since 11 October (README L22), and all inputs are on Cardinal. Name the host.

Verdict: not registrable as drafted. Fix F1 to F4 before any threshold is computed.
