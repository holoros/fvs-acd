# Bakuzis NS grid for the 14.2 candidate NS configuration v141LTfi: PREREG26 result

30 September 2026. Pre-registration: `plan/2026-09-30_v142_bakuzis-ns-v141LTfi_PREREG26.md` (revision 2, md5 291bb1ec;
revision 1 ad80d059), recorded before any grid trajectory in `~/jobs/v142p26/logs/prereg_md5.txt`. Driver `driver_p26.R`
(runner `runner_p20_fb.R` lines 1 to 419 byte for byte), assembly `assemble_p26.R`. Chain start 08:02, primary verdict 13:27,
CHAIN_DONE 16:28 server time. Nothing fitted. L and T at run 14868899; GT1 stays a named failure. No em dashes.

## Verdict

**Rule 2. Not cleared.** v141LTfi raises no flag that v141LT does not, but on site ordering of basal area its worst margin
is 8 inversions against 7 for v141LT, so non inferiority part (B) fails by one unit. The follow up arms attribute that
margin to threshold matching with IMULT 1.5 (v141LTi reaches 8 alone; the height form alone, v141LTf, stays at 7). 14.1 is
unchanged. The PREREG22 candidate v141LTfi keeps its benchmark gates but is not cleared for release consideration as an NS
regional setting. The reported sensitivity arms add a second, larger reason for caution, set out below: the height form
lowers 100 year top height by 14 to 25 percent, and the configuration's better top height realism in the gated arm comes
from the synthetic 9.1 cm recruit threshold, not from the model.

| Gate or relation | v141LTfi | v141LT (14.1) | Pass |
|:--|:--|:--|:--:|
| G0 driver against frozen Cardinal v141LT, 3 stands, 12 columns | worst scaled 0 | at or below 1e-9 | Yes |
| G0c checker reproduces stored v1402 report | identical | identical | Yes |
| G1 trajectories complete, 101 rows | 72 of 72 (180 of 180 with follow up arms) | all | Yes |
| G2 dry run cell equals grid cell | identical | identical | Yes |
| Reineke, 36 trajectories | 36 flags, worst 1.213 | 36 flags, worst 1.279 | Yes |
| Frontier (NS tau 0.99, slope -1.311) | 4 flags, worst 0.0108 | 4 flags, worst 0.0382 | Yes |
| HT monotone | 0 flags | 26 flags, worst 0.616 m | Yes |
| Site ordering, HT | 0 flags | 1 flag | Yes |
| Site ordering, BA | 5 flags, worst 8 | 5 flags, worst 7 | **No** |
| Site ordering VOL, Eichhorn, Sukachev, yield density, magnitude | 0 flags | 0 flags | Yes |

## What the grid shows

**The failing margin is one inversion in one cell.** The worst BA ordering unit is pure balsam fir at 6,000 stems ha⁻¹, where
lower ESI stands carry more basal area than higher ESI stands at 8 of the 20 five year points under v141LTfi and 7 under
v141LT. Both arms flag the same five mix by density units. The inversions are small: the largest, relative to the highest basal
area at that age, is 3.3 percent under v141LTfi and 2.0 percent under v141LT in that unit, and at most 1.1 percent in the
other flagged units. The count is sensitive to small shifts, and the unit it turns on is a property of both arms.

**Every trajectory fails Reineke in both arms, and both sit below the NS frontier.** Slopes of log TPH on log QMD run from
-0.96 to +0.08 against the (-2.2, -1.2) band, because ingrowth holds stems up as QMD grows (Figure 2). The NS frontier
re-derived from 5,566 ns_c t1 stands has slope -1.311 (intercept 4.987), shallower than Reineke's -1.605; v141LTfi exceeds it
only in the four red spruce 6,000 stem cells, by at most 0.011 in log10 TPH against 0.038 for v141LT. Neither relation
separates the arms.

**The HT monotone pass is the recruit threshold, not the height form.** v141LT drops top height by up to 0.62 m in 26
trajectories when large trees die. v141LTfi has none. The follow up arms show why: the two arms that keep the 5.0 cm recruit
threshold (v141LTf, height form only, and v141LTfi5, both switches at 5.0 cm) have the same 26 flags with the same worst
fall (0.616 m), while the two arms that recruit at 9.1 cm (v141LTi and v141LTfi) have none. Recruits entering at 9.1 cm in a
2 to 5 cm cohort lift top height from 5.1 to 8.5 m in the first year (revision 2 of the plan), and they later
refill the largest 100 stems when the cohort's large trees die.

**Top height realism reverses when that artifact is removed.** Under the reported test, v141LT top height at age 50 is below
0.85 ESI on 13 of 18 ESI 15 and 18 cells (0.66 to 0.90 of ESI) and v141LTfi on 9 (0.77 to 0.93). v141LTfi5 is below 0.85 on
all 18 (0.58 to 0.82). At age 100 the height form cuts top height relative to 14.1 by 14 to 25 percent whether it runs alone
(v141LTf, ratio 0.754 to 0.863) or with threshold matching at 5.0 cm (v141LTfi5, 0.753 to 0.863), every cell below the
0.90 plausibility ratio. With recruits at 9.1 cm the same form gives 0.884 to 0.954. Threshold matching alone raises top
height (v141LTi, 1.057 to 1.180 at age 100). The height form was validated on remeasured NS tag trees over one interval
(PREREG20, PREREG22), where 14.1 over predicted large tree height increment; the grid says that correction, compounded over
a century from a seedling cohort, gives balsam fir on an 18 m ESI a top height of 16.2 m at year 100 against 20.8 m under
14.1 (Figure 1). Which of the two is closer to observed long run NS height growth cannot be decided from a synthetic grid.
It is the question the next NS track has to answer against observed long interval height, before any NS height setting is
carried forward.

**Volume and stems.** At age 100 v141LTfi carries 75 to 91 percent of v141LT volume and 78 to 99 percent of its stems (4 cm);
balsam fir takes the largest cut (for example 221 against 285 m³ ha⁻¹ at ESI 9 and N0 3,000). v141LTfi5 carries 80 to 94
percent of volume and 93 to 110 percent of stems.

**Sensitivity arm v141LTfi5, reported and not gated.** At 5.0 cm the BA ordering worst margin falls to 6 (3 flags), so the
gated failure depends on the synthetic threshold. v141LTfi5 fails non inferiority on two other relations instead: a new
yield density flag in balsam fir at ESI 9 (CV of age 100 volume across N0 0.164 against the 0.15 limit) and a Reineke worst
margin of 1.284 against 1.279. The plan states this arm cannot change the verdict. No threshold tested gives a
configuration that is non inferior to 14.1.

**Component arms, reported.** Read with the same rule, neither component alone is non inferior either: v141LTf worsens the
Reineke (1.312) and frontier (0.0396) margins, and v141LTi worsens the BA ordering margin (8) and adds one BA ordering flag
(mixed, N0 1,500).

![Top height and volume for all five arms](figs/gyr142-p26-arms-height-volume_2026-09-30.png)

**Figure 1.** Top height (largest 100 stems ha⁻¹) and NSVB total volume over 100 projection years for N0 3,000 stems ha⁻¹ at
ESI 9 m (dashed) and 18 m (solid), by mix, for the gated arms (v141LT, v141LTfi) and the reported arms (v141LTf, v141LTi,
v141LTfi5). v141LTf and v141LTfi5 overlap in top height. Figure script `figs/2026-09-30_v142_p26_fig_arms.R`, written after
the chain closed and reported, not gated.

![Reineke view of the gated arms](assembled/gyr142-p26-reineke_2026-09-30.png)

**Figure 2.** Stems per ha against QMD (trees 4 cm and over), log scales, five year points over 100 years, gated arms, with
the Reineke slope -1.605 dotted. Assembly figure; its title and axis labels use plain text units.

## Re-derivation [F9]

`verify_20260930/rederive_p26.R` (md5 61fe2e6a) shares no code with `assemble_p26.R`: it reads the raw per task trajectory
files in `out/`, recomputes every relation statistic, flag and margin and every NI gate for the two gated arms, and compares
with `assembled/`. It ran through a load gated launcher (`run_rederive_p26.sh`) at 16:17 server time: 408 of 408 relation
rows matched with 408 of 408 flags agreeing (worst margin difference 7.2e-15, worst statistic 4.0e-15), G1 72 of 72 with
run_ok 1 throughout, 10 of 10 NI gate values agreeing, NI overall re-derived FALSE. The log ends `REDERIVE_DONE`. The follow
up arms and the sensitivity comparison are read from the follow up assembly and are not re-derived.

## Deviations

1. **Plan revision 2** (before any grid trajectory) recorded the 9.1 cm recruit jump seen in a 3 year smoke of one cell and
   added v141LTfi5 as a reported arm; the gated arm stayed at 9.1 cm as registered.
2. **Assembly attribution fix before chain launch** (08:00 server time, after the dry follow up assemblies;
   `assemble_p26.R.pre_attrfix` kept).
3. **Figure 1 added after CHAIN_DONE** because the assembly figures show only the gated arms. It reads the follow up table
   and changes no number.

## Files

`~/jobs/v142p26/`: `plan/` (PREREG26 revisions 1 and 2, cell plans), `scripts/` (driver, runner, chain, assembly, G0 and
G0c, thresholds), `diffs/`, `logs/` (prereg md5, G0, G0c, tasks, chain), `out/` (trajectories), `assembled/` (primary gates,
relations, realism, verdict, figures) and `assembled/followup/` (all five arms, attribution, sensitivity NI, follow up
verdict), `figs/`, `verify_20260930/`. Laptop: `outputs/2026-09/fvs-acd-v14.2-recs/p26/`.
