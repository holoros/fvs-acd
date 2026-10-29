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
| `v14.3/` | 14.3 pre-registration 1 (registered October 18, 2026, md5 7f3e67c2), its registration log, change log and the five red team reviews |
| `preregistrations.md` | index of the 14.2 refinement pre-registrations and results, PREREG13b to PREREG49 |
| `../scripts/v14.2dev/2026-10-16/release-notes/2026-10-16_fvs-acd-v14.2_release-notes_DRAFT.md` | 14.2 release notes, revision e |
| `GY_model_evaluation_scorecard.md` | the multi-dimensional growth and yield evaluation framework the benchmarks score against |
| `../CHARTER.md`, `HANDOFF_FVS-ACD.md` | the June 2026 site driver modernization charter and its handoff |

## Find a script

`../scripts/README.md` indexes every file in `scripts/` by role, version and status, and records
header and version tag mismatches. Paths there are frozen; nothing is moved.

## Check the evidence

| Document | Contents |
|:--|:--|
| `benchmarks/2026-10-16_cross-version/README.md` | 13.1h, 14.0.4 L2 and 14.1 on 19 frozen sets, 827 post-harvest Maine FIA stands and 200 yr projections |
| `reports/` | finished benchmark reports, decks and the Seven Islands v25 package; superseded versions in `reports/archive/` |
| `../results/`, `../data/`, `../figures/` | aggregate scorecards, frozen composite scores and publication figures |
| `handoffs/` | dated session records, `YYYYMMDD_topic.md`, read chronologically for the day by day history |

## Branches

The repository holds several lines of work that have not been merged into `main`. As of October 17,
2026:

| Branch | Holds | Relation |
|:--|:--|:--|
| `main` | 12.3.6 to 13.1 lineage, frozen v12.10.1 deposit, 12.x reports | default branch |
| `engines-13.1-13.3-20260908` | 13.1 brought up to the Cardinal copy, and 13.3 | PR #8 into `main` |
| `engines-14.0.1-20260916` | 14.0 and 14.0.1 | one commit on PR #8's branch, no PR of its own |
| `engines-14.0.3-20260917`, `engines-14.0.4-20260917` | intermediate engine branches | superseded by `engines-14.1-20260924` |
| `engines-14.1-20260924` | 14.0.2 to 14.1 engine files, coefficients, the v141 runner and the 14.1 gate pre-registration | PR #9 into `engines-14.0.1-20260916` |
| `v142-refinement-20260926` | the 14.2 refinement record (`scripts/v14.2dev/`) | branched from `main`; does not contain the 14.x engine files |
| `acdx-crossversion-20261016` | the October 16 cross-version benchmark and release notes revision e | PR #10 into `v142-refinement-20260926` |
| `docs-v142-p46p47-v143-20261017` | PREREG46 and PREREG47 records (October 11 and 15) | stacked on PR #10 |
| `docs-overhaul-20261017` | this documentation set, the user guide and the `scripts/` index | stacked on the branch above |
| `mortality-shutoff-repairs-20260908` | mortality shutoff diagnosis and Bakuzis three way comparison | PR #7 into `hardwood-formrisk-wip` |
| `rescue/dc5df3d` | v12.11 benchmark of August 4, 2026 (height coverage census, rescores, Zenodo deposit package) | kept as a recovery branch; not merged into `main` |
| `hardwood-formrisk-wip` | 13.1 passes 9 to 11 (August 2026) | diverged from `main`; base of PR #7 |
| `silc-benchmark-v32-20260926` | Seven Islands v32 benchmark | one commit on `main` |

Because the engine line and the refinement line branch separately from `main`, no single branch yet
holds both the 14.1 engine files and the 14.2 record. The engine branches form a straight stack on `main`
(`engines-14.1-20260924` is 8 commits ahead and none behind), so merging PR #8 and then retargeting
PR #9 to `main` and merging it, followed by the refinement line, would bring them together.
