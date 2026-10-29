# 14.3 pre-registration 3 (revision 1, md5 20364c4b): deviations and implementation notes

Run 28 October 2026 on Cardinal in `~/v143p3/` (steps 1 to 3) and on firebreather in `~/jobs/v143p3/` (step 1, Maine and
New Hampshire FIA counts). Result: `2026-10-28_v143_T-form-class-shape_RESULT.md`. Each item says what the plan or the
standing rules say, what was done, and why. None of them changes a registered computation of step 3.

## Deviations

1. **Printed rows of a firebreather table (before registration).** While checking the Quebec cut flag source, a `head` of
   `~/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv` printed 6 data rows to the session transcript:
   Quebec MAGPlot stand keys and the observed and predicted volumes of a 14.2 arm (p19_a0030). The standing rule keeps
   stand identifiers out of printed output. No file was written with them, no count used them, and the Quebec source
   qualifies 0 stands by the flag's own definition (a cut inside the interval).
2. **A credential string from unrelated scripts was printed to the session transcript; rotation recommended.** A text
   search on Cardinal for the New Brunswick treatment code matched lines in unrelated scripts under `~/LSOG` that hold
   a credential string. It was not written to any file of this study and is not repeated anywhere.
3. **Mislabelled column.** In `out/conf_esi_surfaces_DATA.csv` the column `res_m` holds the raster resolution in
   degrees, not metres (for example 0.000277777778 for the 30 m Acadian ESI v8 raster).
4. **Five NB NFI ground plot stands not classed.** `v143p3_conf_nbqc.py` writes 0 heavy stands for the NB NFI ground
   plots without computing the rule 7 class of the 5 stands that have a third visit. The pooled table carries them as an
   upper bound (all 5 heavy and ESI covered: 15 heavy stands), which still misses the floor of 30.
5. **Step 1 survivor counts are frame level.** The step 1 survivor counts by d / Dq class come from FIADB status (live at
   v1 and at the linked v2 record, DBH at least 5 cm, Dq expansion weighted over FIA live trees at v1), not from the
   scorer's engine split population. They decide only the "3 gated classes" floor, which is met either way, and the
   verdict turns on the heavy floor.
6. **Fitter edited after the first dry run.** The full-data fits were parallelized over forms (arithmetic unchanged).
   The first version is kept as `scripts/v143p3_fit_PREV_20261028.R` (md5 3f17dfd8); the edited version was dry run
   again (`dry2/`, identical full-data dry estimates) before its launch md5 (2851769d) was logged.
7. **Temporary directory in home.** An inventory directory `~/v143p3_tmpinv` was created in home before `~/v143p3`
   existed and was then moved to `~/v143p3/work/p2_inventory` (a new directory; nothing existing was touched).
8. **Frame script dry run on real inputs.** As in PREREG2 (its DEVIATIONS item 3), the frame script was dry run on the
   real frozen inputs into `~/v143p3/dry/`; its aggregate outputs are deterministic and match the real run's md5s.
9. **Bridge outage.** The laptop bridge that carries the Cardinal and firebreather tools was down from about 06:55 EDT
   to about 19:00 EDT on 28 October. No job was affected: the primary fit (SLURM 15946426) ran to completion
   (1 h 39 min) and wrote its selection record at 08:07:59 (md5 7a6b3374, `logs/selection_md5.txt`). The stress variants
   and the assembly were submitted after the bridge returned, after the selection md5.

10. **Basal area increment stress variant not informative.** In variant `bai` the pooled objective is of order 1e-6
    ((m² yr⁻¹)² scale after dividing by the source weights), and L-BFGS-B returned the start values for every form (for
    example T0c alpha 0.55, beta 0.06; `out/fit3_bai_full_fits_DATA.csv`), finishing in minutes. Its H0 re-selection is
    therefore reported as not informative. It was not rerun with a rescaled response, since that would be a change made
    after seeing a stress outcome; PREREG2's fitter used the raw weighted sum for this variant.

## Implementation notes (fixed before the step they govern)

11. **launch_md5s line with an empty md5.** `logs/launch_md5s.txt` holds one line with an empty md5 for
    `scripts/v143p3_conf_fia.R`, because that script ran on firebreather and was not yet on Cardinal; a corrective line
    with its md5 (2ec827b6, the md5 logged on firebreather before its run) was appended. No line was edited.
12. **New FIA data by visit year.** Step 1 counted new Maine and New Hampshire stands on the firebreather FIADB download
    of 26 September 2026 by the rule "v2 in 2025 or later", so that no identifier moved between hosts (gate H7 by
    construction). The same builder on the same download, restricted to v2 at or before 2024, reproduces the
    mefia_ph_c frame's 827 stands and 221 heavy stands.
13. **Not run (registered scope).** Step 4 of draft 1 (the engine no-harm gates N0, N1, N2, R1 with the engine harness
    gates H1, H1b, H4 and the new overlay) and step 5 (confirmation runs). The engine overlay and arm templates of
    PREREG2 were copied to `p2ref/` and not changed. The symmetric control stress variant was dropped in revision 1; the
    r_d extension variant was not triggered (the full-data r_d pick is 1.0, not 1.5).
14. **Copies to the laptop.** Laptop copies exclude `logs/find5.log` (the search log of item 2). The assembly script's
    md5 (82eaf6f4) was logged in `logs/launch_md5s.txt` at 2026-10-28T19:04:26-0400, before it ran (SLURM 15964554).
