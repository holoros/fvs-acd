# FVS-ACD (AcadianGY): modernization and benchmark record

AcadianGY is the R implementation of the Acadian variant of the Forest Vegetation Simulator
(FVS-ACD), the individual tree growth and yield model for the spruce-fir and northern hardwood
forests of Maine, New Brunswick, Nova Scotia and Quebec. This repository holds its version lineage
from 12.3.6 to 14.1, the pre-registered studies behind the 14.x changes, the benchmark packages
that test each version, and the reports built from them. Code and aggregate results live here.
Tree lists, plot identifiers and coordinates stay on the compute hosts and are never committed.

The canonical model is maintained with Ben Rice (Midgard Natural Resources), and the Fortran FVS
implementation of the variant is in Midgard's fork of the Forest Vegetation Simulator. Changes made
here are coordinated with both.

## Status (October 17, 2026)

| Version | State | Where |
|:--|:--|:--|
| **14.1** | **current release**, shipped September 24, 2026: 14.0.4 plus two diameter increment terms, L (large stem level) and T (thinning release), both off by default; one named standing gate failure, GT1 | engine files on branch `engines-14.1-20260924`, PR #9 |
| 14.2 | refinement in progress; no engine file, coefficient or default of 14.1 changed so far | record in `scripts/v14.2dev/`, release notes revision e |
| 14.3 | planned; the first pre-registration (thinning response limited to partial removals) is drafted and under red team review, not yet in this repository | `docs/v14.3/` once registered |
| 13.1 | model of record and the base every 14.x file sources | the benchmarked copy (md5 5894df60) is on Cardinal only; `scripts/AcadianGY_13.1.r` here is an older copy (md5 5140bf9b), see `docs/reference/running-14.1.md` |
| 12.10.1 | frozen August 2026 operational baseline, packaged for deposit | `zenodo_v12101/` |

What the October 16, 2026 cross-version benchmark found
(`docs/benchmarks/2026-10-16_cross-version/README.md`): 14.1 is the best ten year model across the
19 frozen benchmark sets, with a median absolute biomass bias of 3.8% against 9.6% for 13.1h. It
overstates biomass recovery after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹ (1.13 to 1.64), and over 200
years without harvest it declines in 64 to 84% of stands in every forest type, where the Maine FIA
curves decline only in spruce-fir. 13.1h has the smallest post-harvest biomass bias overall (14.0.4 L2 is closer on heavy removals and
14.1 on light ones), and it declines in at most 2% of stands in any forest type. Every version underpredicts ten year growth on unmanaged Maine FIA plots by about 10 to 14%
in biomass.

Open work waits on firebreather, the host of the 14.2 runs, which has been unreachable since
October 11, 2026: the PREREG46 run and the PREREG47 reading, the 14.2 arms p38_fit and qc_rh on the
Maine sets, and Zenodo version 1.9.0 and the version after it, which will carry the cross-version benchmark.

## Quick start

To run 14.1, read `docs/reference/running-14.1.md`. In short, a projection sources four layers in
order (13.1, the 14.x base, the 14.0.4 engine, the 14.1 overlay), reads every setting from
environment variables, and is driven by the benchmark runner. The defaults of several variables do
not reproduce the release, so start from the launcher block in that guide. Every variable, with its
default and its release value, is in `docs/reference/switches.md`.

A clone cannot yet run 14.1 end to end. The benchmarked 13.1 base, the 14.x base file, the trajectory
hooks, four lookup tables, two helper scripts and the counters runner are still on OSC Cardinal, and the frozen stand sets stay on the compute hosts by
policy. The running guide lists each one.

To reproduce a benchmark, follow the Reproduction section of its package, for example
`docs/benchmarks/2026-10-16_cross-version/README.md`; every route currently needs Cardinal. To
understand a version, read its era in `VERSION_HISTORY.md`. To check a decision, find its study
in `docs/preregistrations.md`, which links each pre-registration to its RESULT.

## How changes are made

Since 14.1, every change to the model goes through a written pre-registration before any fit or
projection. It
states the arms, the gates with the provenance of each threshold, and the decision rule, and it is
recorded by md5 and time in a `prereg_md5.txt` beside it (from PREREG26 on; the folders for
PREREG13b to PREREG25 carry no such record, and the plan texts of PREREG23 and PREREG24 are not in
the repository). A RESULT file reports every gate, passing
or failing. Frozen runs are read and never rerun, and nothing is overwritten. A failed gate is
reported as failed. GT1 in 14.1 is the standing example: its release half life condition fails and
the record says so in every document. For the recent studies, red team reviews of each plan and its scripts are
kept with the plan.

## Where things are

| Path | Contents |
|:--|:--|
| `docs/index.md` | documentation map, including the branch map |
| `docs/reference/` | running guide and switch reference |
| `VERSION_HISTORY.md` | every engine version, nine eras, from 12.3.6 to 14.1 |
| `docs/preregistrations.md` | index of the 14.2 pre-registrations and results |
| `docs/benchmarks/` | dated benchmark packages, each with its README, figures, aggregate CSVs and scripts |
| `docs/reports/` | finished reports and decks; superseded versions in `docs/reports/archive/` |
| `docs/handoffs/` | dated session records, `YYYYMMDD_topic.md` |
| `docs/history.md` | the status sections this README carried from June to October 16, 2026 |
| `scripts/` | engine files (`AcadianGY_*.r`), build and patch scripts, harnesses; `scripts/v14.2dev/` holds the 14.2 record by date |
| `results/`, `data/`, `figures/` | aggregate scorecards, frozen composite scores, publication figures |
| `refs/` | archived reference material |
| `zenodo_v12101/` | the v12.10.1 Zenodo deposit package |
| `_context/` | standing prompts and specifications |
| `CHARTER.md` | the June 2026 site driver modernization charter |

Several lines of work sit on branches not yet merged into `main`, and the 14.x engine files and the
14.2 record are on different branches. `docs/index.md` maps them.

## Data policy

FIA true plot coordinates are restricted and are processed only on the compute hosts. Proprietary
industry data is used under its owners' terms and only aggregates leave the host. Large inputs stay on the compute hosts
and go to Zenodo at release, as in the other holoros data repositories. The cross-version benchmark
package documents a screen of its files for plot and stand identifier columns and coordinate fields,
and a file that carries one is refused. The PREREG46 and PREREG47 records were screened the same way
on October 17, 2026; earlier 14.2 refinement folders carry no record of a screen.

## Citation

Cite the Zenodo concept DOI, 10.5281/zenodo.22996790, which resolves to the latest deposited version
(1.8.0, 10.5281/zenodo.23168366, as of this writing). `CITATION.cff` carries the same record. The
deposit is licensed CC BY 4.0. The code in this repository does not yet carry a license file.

## Contact

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine,
aaron.weiskittel@maine.edu.
