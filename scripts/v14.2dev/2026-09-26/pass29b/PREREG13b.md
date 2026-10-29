# PREREG13b: pass 29b, MNAP split by owner (written 2026-09-26 before any 29b run)

Context: pass 29 (~/jobs/v142p29, untouched) FAILED as written on M2 (frozen DBH rounded to 0.01 cm vs exact inch
conversion in LiveTrees, max 0.004 cm, stems identical; v142p29/diag/m2_dbh_diag.R) and M4 (State passes, TNC fails).
Approved by Aaron, run on autopilot.

## Build
- Database: the pass 29 step 1 copy (md5 f55bf733b628da91c08a519cdd00dc90), copied, not rebuilt. Step 1 script reused
  unchanged (empty diff). Owner per plot key from pass29-step1-plots.
- Builder: frozen pass 29 builder plus the least invasive split: a virtual set MNAP_TNC over dataset 8 (same mechanism
  as NSPOOL), and an owner filter on plot keys for MNAP (State) and MNAP_TNC (TNC). No new dataset id, no DB change.
  - mnap_c = State plots only (expect 348 pairs); MNAP stays in TAG_STABLE.
  - mnap_tnc_c = TNC plots only (expect 136 pairs); NOT in TAG_STABLE, churn flags tag free (as NB).
  - Plots with Owner UNKNOWN enter neither set.
- Frames keep PROVISIONAL placement (out/PROVISIONAL_p29b/frames).

## Gates
- F: firewall as in pass 29 (no coordinate columns, no DBH/EXPF/HT/year sentinels), on both sets; plus set membership
  matches the owner table and TAG_STABLE is 1 for State, 0 for TNC.
- F5: magnitude check. mnap_c + mnap_tnc_c pairs = pass 29 mnap_c pairs (484); pair keys, stand BA/TPH per pair
  (pairs columns and recomputed from trees) and tree rows identical to pass 29 for every pair (pure split).
- M0: datasets other than 8 identical to pass 28.
- M1: all non MNAP frame files md5 identical to pass 28b.
- M2: the 99 frozen mnap_c pairs, split by owner as they fall. DEVIATION FROM PREREG13 M2: DBH rounded to 2 decimals
  on BOTH sides before stand BA and TPH are computed. Same tolerances (0.001 m2/ha, 0.01 trees/ha, DBH >= 4 cm) and
  same recovered rows rule.
- M3: State pairs >= 300 of 378 dated State plots [SET ON AUTOPILOT, scaled from 400/519]. TNC pairs reported with
  exclusions by reason, not gating.
- M4: Phase D criteria (same species >= 0.97, both criteria >= 0.98) required on mnap_c (State), both size classes
  (<15, >=15 cm). TNC reported, not gating.

## Run
One detached process, nice 5. Status logs/_status_p29b.txt ends P29B_DONE or P29B_FAIL <step>. Outputs md5 list and a
tables tgz. No coordinates in any output. Nothing sent to anyone.
