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

## Status (October 27, 2026)

| Version | State | Where |
|:--|:--|:--|
| **14.1** | **current release**, shipped September 24, 2026: 14.0.4 plus two diameter increment terms, L (large stem level) and T (thinning release), both off by default; one named standing gate failure, GT1 | engine files on branch `engines-14.1-20260924`, PR #9 |
| 14.2 | refinement in progress; no engine file, coefficient or default of 14.1 changed so far; PREREG46 to PREREG49 ran in October | record in `scripts/v14.2dev/` (PREREG46, the PREREG47 reading and PREREG48 in `scripts/v14.2dev/2026-10-26/`, PREREG49 in `scripts/v14.2dev/2026-10-27/prereg49/`), release notes revision g (`scripts/v14.2dev/2026-10-27/release-notes/`) |
| 14.3 | in study; pre-registration 1 (the 14.1 thinning response limited to partial removals) ran October 18 to 19, 2026: no eligibility rule adopted, and large residual trees after removals grow about two thirds of what 14.1 predicts; pre-registration 2 (re-estimating the form of T) was registered on October 26, 2026 and ran on October 27, 2026: the selected form C2 is not adopted (rule 3, it fails the survivor gate on mefia_ph_c), so 14.3 keeps the 14.1 T, and the sealed NH and VT confirmation is open | [`docs/v14.3/`](docs/v14.3/), result in [`docs/v14.3/run_v143p1/result/`](docs/v14.3/run_v143p1/result/) |
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

October 26, 2026. Firebreather, the host of the 14.2 runs, refused connections from October 11 to at least October 19
and is reachable again; the work queued on it ran:

- Zenodo version 1.9.0 was published (10.5281/zenodo.23665173). Version 1.10.0, which adds the cross-version
  benchmark and the records below, is staged and not published.
- PREREG46 (a QC height increment multiplier with a zero in relative height, for 14.3) found no candidate. qc_ez stopped at rule 1
  at its fit (b not negative with the zero fixed at 1.285). qc_lz passed every harness gate but failed rule 2 on the new relative
  height gates (fold B ratio 1.341 in the 1 to 1.25 bin), and gate C failed too (`scripts/v14.2dev/2026-10-26/prereg46/`).
- The PREREG47 reading r1 (absolute QC Bakuzis gates) finds every arm read not credible on the long run: 14.1 keeps QC top
  height nearly flat after its first decades (7 of 36 stands keep gaining in every late window), while p38_fit, qc_rh and qc_lz
  overshoot the measured frontier (`scripts/v14.2dev/2026-10-26/prereg47/`). 14.2 keeps QC_AFAC 0.111.
- The 14.2 arms p38_fit and qc_rh reproduce 14.1 exactly on the three Maine frames of the cross-version benchmark
  (ten year hindcast, post-harvest set, 200 yr projections): every compared value differs by 0. Both arms change only
  the Quebec height path, so this was the expected identity, now measured
  (`scripts/v14.2dev/2026-10-26/acdx_arms/`).
- PREREG48 split the QC stems deficit (about 24 points on qc_c fold B) and found it is ingrowth past the scoring floor, on both
  14.1 and qc_rh (rule 3, a 14.3 ingrowth track; the split does not depend on the height form). An independent recomputation
  reproduced every point value and showed why: engine ingrowth enters near 5 cm and stays below QC scoring floors of 9.1 to 33.7 cm
  (7 of 6,042 records cross), so the track starts with ingrowth entry size and floor handling
  (`scripts/v14.2dev/2026-10-26/rec_b/v142p48/`).
- PREREG49 tested a gamma frailty survival step for NS over multi year intervals and reran the v141LTfi Bakuzis question on
  measured stand lists. The step fixes the long interval survivor ratios (0.930 and 0.993 against 0.868 and 0.921) but fails
  annual survival by interval (5 of 11 classes, predicted too low) and two PREREG22 gates, so it is not adopted; v141LTfi is
  not cleared (new Eichhorn and top height monotonicity flags) and loses a median 15.6% of 100 year top height against v141LT
  (`scripts/v14.2dev/2026-10-27/prereg49/`). 14.2 is unchanged.
- 14.3 PREREG2 re-estimated the form of T on 46,521 tree records from 17 installations (PEF excluded by its link test). The
  registered selection picked C2 (tied with C3; its threshold pair sits on the grid edge, and an extended grid picks it again),
  with a cross validated error of 0.1517 against 0.1541 for the refit 14.1 form. Every harness gate passed, but on mefia_ph_c
  C2 fails the survivor gate (ratio 0.867 above d/Dq 1.5, outside 0.90 to 1.10) and gates V1-L, P1-S, P3 and N1, so it is not
  adopted (rule 3) and 14.3 keeps the 14.1 T. The sealed New Hampshire and Vermont confirmation is open: ESI covers 37% of its
  108 stands (68 use climate site index as a fallback, by Aaron's decision) and only 16 are heavy removals
  (`docs/v14.3/run_v143p2/`).
- Howland Research Forest: 13.1h and 14.0.4 L2 were run on the 93 Howland plots beside 14.1 and the earlier 12.3.6 and 13.1
  ship18 runs. By year 50 at mid site, biomass changes by +29.7% (12.3.6), +8.3% (13.1h, after an early drop), -4.2% (13.1
  ship18), -11.0% (14.0.4 L2) and -8.3% (14.1); the 14.x engines lose basal area from 41.5 to about 31 m² ha⁻¹. Only 12.3.6
  shows the sustained gain that repeat ALS reports there (`results/howland_20261026/`).
- Zenodo version 1.10.0 (10.5281/zenodo.23670727) was published on October 27, 2026 with the cross-version benchmark,
  PREREG46 to PREREG49, the 14.2 arms and release notes revision g.

## Quick start

To run 14.1, start with the user guide, `docs/guide/user-guide-14.1.md`, which shows a ten year
projection called directly in R; `docs/reference/running-14.1.md` covers the benchmark runner. In short, a projection sources four layers in
order (13.1, the 14.x base, the 14.0.4 engine, the 14.1 overlay), and in the benchmarks reads every
setting from environment variables through the runner. The defaults of several variables do not
reproduce the release, so start from the worked example in the user guide or the launcher block in
the running guide. Every variable, with its
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
| [`docs/index.md`](docs/index.md) | documentation map, including the branch map |
| `docs/guide/` | the 14.1 user guide |
| `docs/reference/` | runner guide and switch reference |
| [`VERSION_HISTORY.md`](VERSION_HISTORY.md) | every engine version from 12.3.6 to 14.1 in nine eras, and the 14.3 studies in a tenth |
| [`docs/preregistrations.md`](docs/preregistrations.md) | index of the 14.2 and 14.3 pre-registrations and results |
| `docs/benchmarks/` | dated benchmark packages, each with its README, figures, aggregate CSVs and scripts |
| `docs/reports/` | finished reports and decks; superseded versions in `docs/reports/archive/` |
| `docs/handoffs/` | dated session records, `YYYYMMDD_topic.md` |
| `docs/history.md` | the status sections this README carried from June to October 16, 2026 |
| `scripts/` | engine files (`AcadianGY_*.r`), build and patch scripts, harnesses, indexed in `scripts/README.md`; `scripts/v14.2dev/` holds the 14.2 record by date |
| `results/`, `data/`, `figures/` | aggregate scorecards, frozen composite scores, publication figures; `results/howland_20261026/` holds the five version Howland comparison |
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
(1.10.0, 10.5281/zenodo.23670727, published October 27, 2026, as of this writing). `CITATION.cff` carries the same record. The
deposit is licensed CC BY 4.0. The code in this repository does not yet carry a license file.

## Contact

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine,
aaron.weiskittel@maine.edu.
