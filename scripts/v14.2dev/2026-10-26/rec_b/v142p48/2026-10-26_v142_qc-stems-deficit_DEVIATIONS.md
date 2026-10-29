# PREREG48 deviations and implementation notes

Plan `plan/2026-10-26_v142_qc-stems-deficit_PREREG48.md`, md5 61ab907e7be70cac0e68264586e9ebec (laptop registration
2026-10-26T11:36:13-0400; server copy recorded in `logs/prereg_md5.txt` before any script ran). No em dashes.

## Deviations from the plan

1. Added coverage condition. Besides T1, a stand counts as covered only if the scorer split map built on the field tag frame
   agrees record by record (species, DBH, EXPF) with the runner t1 list of both arms. The plan does not name this check; it
   guards the link from predicted records to t1 tags without using the run frame TREE column. It excluded 0 stands
   (`gyr142-p48-T1-coverage`).
2. T3 was evaluated on both arms and required to pass on both; the plan does not say which arm. Both values are 0.
3. AR was gated on all screened fold B stands (the PREREG45 B2 population); the covered value is reported beside it and is
   identical because coverage is 160 of 160.
4. The rule 2 sub clause (observed annual survival rising with interval while predicted stays flat) has no registered
   threshold; the assembly reports it descriptively. Rule 2 did not fire, so it did not affect the outcome.
5. Post hoc, after the chain and before assembly, `scripts/p48_framecheck.R` was added to count field frame rows below the
   scoring floor and invalid tags (reported, not gated). Its md5 was appended to `logs/launch_md5s.txt` before it ran.
6. The plan says deviations are logged in the RESULT; they are listed there and in this file.

## Implementation choices within the plan

- Observed survivors are t2 records at or above the floor whose field tag matches a clean t1 tag at or above the floor.
  A clean t1 tag is valid (finite, below 9e6), unique in its stand at t1, and its t2 partner (if any) is unique and the same
  species (the scorer C2 tag rules). Upgrowth: same, with the t1 DBH below the floor. Recruitment: t2 records at or above the
  floor with a valid unique tag not present at t1. Everything else is residual R. Predicted records follow the same
  clean or not clean status of their t1 row; predicted ingrowth past the floor is the runner `ing == 1` records at or above it.
- A survivor whose t2 DBH falls below the floor is not a stem at t2, on both sides.
- Pooling is sums over stands (weight 1 each, the r2 ratio of sums); the bootstrap uses site draw counts, seed 20261001,
  B = 1000, sites sorted per fold over the screened stands (PREREG37 construction).
- Fold rule: the PREREG23 helper `fold_of`, asserted equal to the rule in `v142p22/scripts/2026-09-27_v142_p17_summ.R`.
- The dry run (`dryrun/`, 26 stand subset) ran before the script md5s were recorded; no script was edited after it.
- Server clock is UTC minus 3; times in logs are server time.
