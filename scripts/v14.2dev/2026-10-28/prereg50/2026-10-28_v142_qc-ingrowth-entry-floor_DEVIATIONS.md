# PREREG50 deviations (QC ingrowth entry size and scoring floor handling)

Plan revision 1, md5 6ea850d4a9d0cf058dde4665e8e7b095, registered 2026-10-28T06:55:09-03:00. None of these deviations touched
a registered threshold, gate, arm or rule, and none happened after an outcome was read.

1. **Plan upload.** The first laptop commit of the plan carried the text from before red team 2 (md5 1a9efe02, 25281 bytes)
   instead of revision 1 (md5 6ea850d4, 26762 bytes). The server md5 check refused registration. The stale copy was kept,
   unregistered, as `plan/2026-10-28_v142_qc-ingrowth-entry-floor_PREREG50_PREV_20261028.md` (server and laptop), and
   revision 1 was then registered.
2. **`p50_boot.R` parse error.** A parenthesis error was found by a parse check before any run. The fix was made before the
   dry run; the old copy is `scripts/_prev/p50_boot_PREV_20261028.R`.
3. **Dry run output names.** The first dry run named its runner outputs `dry_SERVERONLY_*`, which the `c[0-9]+` reader pattern
   does not match, so the dry G2 and G5 found no output. The files were renamed to `c000_SERVERONLY_*` with contents unchanged
   (logged in `logs/dryrun_chain.txt`), and `dry_p50.sh` was fixed (name c000; the stand pick is skipped if the stand file
   exists; old copy `scripts/_prev/dry_p50_PREV_20261028.sh`). The partial dry analysis was moved to
   `dryrun_PREV_20261028/` and the dry analysis rerun. This was a fold A, 20 stand dry run, done before the launch md5s were
   recorded.
4. **L2 scope.** L2 searched firebreather, including the git mirrors in `~/repos-mirror`. The laptop repository was not
   searched, as the plan states. Result: not found, so the label "threshold support unknown".
5. **Bridge outage.** The laptop bridge was unreachable from about 08:00 server time until after the chain ended. The chain ran
   detached under `setsid nohup` on firebreather and finished (CHAIN_DONE 2026-10-28T08:17:50-03:00) with all 57 runner tasks at
   exit 0. Assembly, its md5 record (20:00:47) and this write up followed once the bridge returned. No step was rerun.
