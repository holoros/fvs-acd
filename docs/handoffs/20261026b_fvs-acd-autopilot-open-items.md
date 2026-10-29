# Session handoff, 26 October 2026 (b): FVS-ACD open items resolved on autopilot

**Summary.** Aaron asked to resolve all open items and recommendations on autopilot (11:32). Firebreather refused port 22 again from
about 11:33, so everything that runs there waits. Nothing was sent to anyone, no PR was merged, and Zenodo 1.10.0 is not uploaded or
published. Builds on `20261026_fvs-acd-v142-p46p47-docs_session_handoff.md` (part a, same day).

## Done

| Item | Outcome |
|:--|:--|
| 14.3 PREREG2 (T form) plan gate | Registered as revision 5 (md5 b7562e8b, 2026-10-26T11:35:09-0400) with the three defaults: PEF on the 80% link rule, no control as primary, sealed NH and VT set built now under read restriction. Copies verified on the laptop (`outputs/2026-10/fvs-acd-v143/`) and on Cardinal `~/v143p2/plan/`; registration line in both `logs/prereg_md5.txt` (laptop PREV kept). Not run. |
| PREREG48 (QC stems deficit split) | Registered as revision 1 (61ab907e) on the laptop copy; second arm frozen qc_rh, because PREREG46 named no candidate (choice 1a). `outputs/2026-10/fvs-acd-v14.2-recs/p48/`. Not run (firebreather). |
| PREREG49 (NS survival step) | Still a draft: its registration needs five lookups on firebreather. |
| Release notes | Revision f (08414cbc) built on e (e1f7b8e9) by asserted replacements; 6,697 to 7,481 words; content inventory diff, unified diff, build script, rendered PDF checked by eye; independent number check found no contradiction and four overstatements, fixed. `release-notes/2026-10-26_f/`. |
| PREREG46 figure | The frozen assembly figure has a clipped, duplicated legend that drops qc_lz. A companion `gyr142-p46-relht-longrun_r1_2026-10-26.png` redraws it from its own data CSVs with one legend (Python; R is not in the sandbox). The frozen figure is untouched. |
| PREREG47 figure | Checked by eye; matches the RESULT. |
| Laptop record copy | prereg47 and zenodo_190 complete; prereg46 recovered from commit d06c68ed through Cardinal as `run_20261026/2026-10-26_prereg46-from-d06c68e_DATA.tgz` (69 files; RESULT and DEVIATIONS md5 match). |
| 04a0b71d (firebreather bundle `p4e/model_b0b1b2.r`) | Resolved by reading: it differs from the benchmarked Cardinal copy bb51eead only in its source path (`path.expand("~/...")` against an absolute path). |
| Repository | Branch `v142-autopilot-20261026` stacked on PR #14 (pushed from Cardinal over SSH): PREREG2 revision 5 and its log, PREREG48, release notes f, the figure companion, this handoff and the doc rows that follow from them. No PR opened for it yet (the standing API token is on firebreather). |

## Not done, and why

1. **Zenodo 1.10.0.** Staged and gated on firebreather (`~/jobs/gh_v142/zenodo_upload_p38p47_1100/`, 100 files, GATES PASS) before release notes f existed. On firebreather's return: restage in a new folder with notes f (fold it into the cross-version zip slot or a notes zip to stay at 100), rerun gates, upload as a draft, and publish only on Aaron's go.
2. **PREREG48 and PREREG49 runs, PREREG49 registration.** Firebreather.
3. **14.3 PREREG2 run.** Registered; the run is a session of its own on Cardinal `~/v143p2/` (scripts, red team, synthetic dry run, frame step with the sealed set, fit and selection).
4. **Draft PRs** for `engine-frozen-cardinal-20261019` and `v142-autopilot-20261026`. Open with the standing token on firebreather, or from the compare links.
5. **Left for Aaron, not resolvable on autopilot.** LICENSE (code co-maintained with Midgard, a rights decision); merging PRs #9 to #14; the FCCL version check with Ben Rice (an outside send); revoking the June classic token; Seven Islands v33 title lines (outside the connected folder); deleting the p36 tgz and p38 duplicates (needs a delete permission grant).
