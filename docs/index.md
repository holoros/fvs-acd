# Documentation map

Start with `../README.md`. This page lists everything else by what a reader is trying to do.

## Use the model

| Document | Contents |
|:--|:--|
| `guide/user-guide-14.1.md` | user guide for 14.1, written from the engine code: the layer stack, inputs, every switch with its effect, a ten year projection in R without the runner, outputs, md5 checks and known limitations |
| `reference/running-14.1.md` | how a 14.1 projection is assembled and launched, file and coefficient md5s, and what a clone cannot yet run |
| `reference/switches.md` | every 14.0.4, 14.1 and runner environment variable with its default and its 14.1 benchmark value |
| `handoffs/20260629_FVS-ACD_user_guide.md` | the 12.6 era user guide, superseded for 14.x by `guide/user-guide-14.1.md` |
| `reports/FVS-ACD_variant_overview_GTR.docx` | variant overview in the FVS general technical report style (12.6 era; the 12.9 revision is `FVS-ACD_variant_overview_GTR_v129.docx`) |

## Understand what changed and why

| Document | Contents |
|:--|:--|
| `../VERSION_HISTORY.md` | every engine version from 12.3.6 to 14.1, with status, gates and stated limitations, in nine eras |
| `history.md` | the dated status sections the README carried from June to October 16, 2026 |
| [`v14.3/`](v14.3/) | 14.3 pre-registration 1 (registered October 18, 2026, md5 7f3e67c2), its registration log, change log and the five red team reviews in `review/`; the run of October 18 to 19 in `run_v143p1/` (`result/` holds the RESULT, deviations and tables; `explore/` the post hoc stress test); the PREREG2 drafts in `prereg2_draft/` and its registered revision 5 (October 26, md5 b7562e8b) at the top of `v14.3/`; the October 28 runs in `run_v143p3/` (pre-registration 3, T form beyond the PREREG2 family), `run_v143p4/` (pre-registration 4, senescence by forest type) and `run_howland_decline/` (the Howland decline diagnostic) |
| [`preregistrations.md`](preregistrations.md) | index of the 14.2 refinement pre-registrations and results, PREREG13b to PREREG50, and of the 14.3 pre-registrations |
| `../scripts/v14.2dev/2026-10-28/release-notes/2026-10-28_fvs-acd-v14.2_release-notes_DRAFT.md` | 14.2 release notes, revision h (October 28); revision g is in `../scripts/v14.2dev/2026-10-27/release-notes/`; PREREG50 is in `../scripts/v14.2dev/2026-10-28/prereg50/` |
| `../scripts/v14.2dev/2026-10-26/release-notes/2026-10-26_fvs-acd-v14.2_release-notes_DRAFT.md` | 14.2 release notes, revision f (October 26); revision e is in `../scripts/v14.2dev/2026-10-16/release-notes/` |
| `GY_model_evaluation_scorecard.md` | the multi-dimensional growth and yield evaluation framework the benchmarks score against |
| `../CHARTER.md`, `HANDOFF_FVS-ACD.md` | the June 2026 site driver modernization charter and its handoff |

## Find a script

`../scripts/README.md` indexes every file in `scripts/` by role, version and status, and records
header and version tag mismatches. Paths there are frozen; nothing is moved.

## Check the evidence

| Document | Contents |
|:--|:--|
| [`benchmarks/2026-10-16_cross-version/README.md`](benchmarks/2026-10-16_cross-version/README.md) | 13.1h, 14.0.4 L2 and 14.1 on 19 frozen sets, 827 post-harvest Maine FIA stands and 200 yr projections; the 14.2 arms p38_fit and qc_rh on the Maine frames (October 26) are in `../scripts/v14.2dev/2026-10-26/acdx_arms/` |
| `reports/` | finished benchmark reports, decks and the Seven Islands v25 package; superseded versions in `reports/archive/` |
| `../results/`, `../data/`, `../figures/` | aggregate scorecards, frozen composite scores and publication figures |
| `handoffs/` | dated session records, `YYYYMMDD_topic.md`, read chronologically for the day by day history |

## Branches

On October 28, 2026 every branch below was merged into `main` through the branch `integrate-20261028`, by Aaron's decision of
that day. Conflicts were resolved by one declared rule: the 12.11 and 13.1 draft engine files keep the main lineage copy at their
paths, and the hardwood branch copies are kept beside them as `scripts/AcadianGY_12.11_hardwood-branch-20260908.r` and
`scripts/AcadianGY_13.1_DRAFT_hardwood-branch-20260908.r`; eight archive decks deleted on the hardwood branch were kept; the
documentation is that of the latest documentation branch. Nothing was deleted. The table is the branch map as it stood before
the merge, as of October 26, 2026:

| Branch | Holds | Relation |
|:--|:--|:--|
| `main` | 12.3.6 to 13.1 lineage, frozen v12.10.1 deposit, 12.x reports | default branch |
| `engines-13.1-13.3-20260908` | 13.1 brought up to the Cardinal copy, and 13.3 | PR #8 into `main` |
| `engines-14.0.1-20260916` | 14.0 and 14.0.1 | one commit on PR #8's branch, no PR of its own |
| `engines-14.0.3-20260917`, `engines-14.0.4-20260917` | intermediate engine branches | superseded by `engines-14.1-20260924` |
| `engines-14.1-20260924` | 14.0.2 to 14.1 engine files, coefficients, the v141 runner and the 14.1 gate pre-registration | PR #9 into `engines-14.0.1-20260916` |
| `v142-refinement-20260926` | the 14.2 refinement record (`scripts/v14.2dev/`) | branched from `main`; does not contain the 14.x engine files |
| `acdx-crossversion-20261016` | the October 16 cross-version benchmark and release notes revision e | PR #10 into `v142-refinement-20260926` |
| `docs-v142-p46p47-v143-20261017` | PREREG46 and PREREG47 records (October 11 and 15) | PR #11, stacked on PR #10 |
| `docs-overhaul-20261017` | the documentation set, the user guide and the `scripts/` index | PR #12, stacked on PR #11 |
| `v143-prereg1-run-20261019` | the 14.3 PREREG1 run and RESULT, the T form diagnostics and the PREREG2 draft | draft PR #13, stacked on PR #12 |
| `engine-frozen-cardinal-20261019` | the frozen Cardinal engine copies with an md5 manifest | no pull request yet; off PR #12's branch |
| `v142-p46p47-docs-20261026` | the October 26 runs (PREREG46, the PREREG47 reading, the acdx arms, Zenodo 1.9.0 scripts) and the October 26 documentation update | draft PR #14, stacked on `v143-prereg1-run-20261019` |
| `v142-autopilot-20261026` | PREREG2 (14.3) and PREREG48 registration, release notes f and g, the Howland cross-version projections, the PREREG48 and PREREG49 runs, the Zenodo 1.10.0 drivers, the October 28 records (PREREG50, 14.3 PREREG3 and PREREG4, the Howland decline diagnostic), release notes h and this documentation update | draft PR #15, stacked on PR #14 |
| `mortality-shutoff-repairs-20260908` | mortality shutoff diagnosis and Bakuzis three way comparison | PR #7 into `hardwood-formrisk-wip` |
| `rescue/dc5df3d` | v12.11 benchmark of August 4, 2026 (height coverage census, rescores, Zenodo deposit package) | kept as a recovery branch; not merged into `main` |
| `hardwood-formrisk-wip` | 13.1 passes 9 to 11 (August 2026) | diverged from `main`; base of PR #7 |
| `silc-benchmark-v32-20260926` | Seven Islands v32 benchmark | one commit on `main` |

Because the engine line and the refinement line branch separately from `main`, no single branch yet
holds both the 14.1 engine files and the 14.2 record. The engine branches form a straight stack on `main`
(`engines-14.1-20260924` is 8 commits ahead and none behind), so merging PR #8 and then retargeting
PR #9 to `main` and merging it, followed by the refinement line, would bring them together.
