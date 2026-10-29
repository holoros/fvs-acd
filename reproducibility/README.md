# AcadianGY / FVS-ACD reproducibility bundle

*Compiled 11 August 2026, ahead of the 18 August 2026 NRCan CFS Acadian growth-and-yield meeting
in Fredericton. Read-only inventory of what exists in this repository; nothing was executed to
produce this document (Cardinal is currently unreachable and there is no R in the sandbox that
built it).*

## What AcadianGY is

AcadianGY, called "FVS-ACD" in most of this project's documents, is a fully open R
reimplementation of the Acadian variant growth-and-yield model. It is not the compiled Fortran FVS
Acadian variant maintained separately by Ben Rice at Midgard Natural Resources
(`github.com/MidgardNaturalResources/ForestVegetationSimulator`), though the two share lineage and
some documents in this repo use the names loosely. AcadianGY's source has been openly readable in
this repository throughout its development. The gap this bundle closes is not "the code is
closed," it is that the scored, production-relevant versions were never git-tagged cleanly and the
engine files, build derivations, and scoring harnesses were scattered across dated filenames tied
to an interactive Cardinal HPC workflow, so nobody outside this project, including Chris Hennigar
(the maintainer of the competing closed-source OSM-ACD model), could actually locate and rerun a
specific scored version. This bundle is a map, not a portability claim: AcadianGY still requires
OSC Cardinal for its data and R environment (see "What still requires Cardinal" below).

## Version to file map

Four kinds of file appear in this repo: (a) the AcadianGY engine itself, (b) the build/derivation
script that produced one engine version from its predecessor by patching the previous file's
source text, (c) the scoring/benchmark harness that runs a version against a dataset and produces
`results/*.csv`, and (d) one-off analysis and plotting scripts, which are out of scope for
reproducibility and not listed here.

| Version | Engine (a) | Build/derivation (b) | Scoring harness (c) | Datasets scored | Git tag |
|---|---|---|---|---|---|
| v12.6.1 | `scripts/AcadianGY_12.6.1.r` | `scripts/build_v1261.R` (derived from 12.6.0) | `scripts/run_region.R` + `scripts/score_region.R` (regional set, `MODEL_FILE=AcadianGY_12.6.1.r`); `scripts/score_v126.R` (Seven Islands CFI stress) | Seven Islands CFI (65 long-horizon pairs), Maine FIA (694 pairs, 5-7 yr), NB/NS/ME regional full 682-plot set | `v12.6.1-candidate` (commit `64c203d`) |
| v12.7.0 | `scripts/AcadianGY_12.7.0.r` | `scripts/build_v1270.R` (derived from 12.6.5) | `scripts/comprehensive_bench.R` (`MODEL_FILE=AcadianGY_12.7.0.r`, produces `cb_v1270_results.csv`, NSVB-metric per-stand); `scripts/run_region.R` / `scripts/score_region.R` for the regional set | Same as 12.6.1 plus independent MAGPlot New Brunswick CFI (262 pairs) | `v12.7.0-operational` (commit `ae94b53`) |
| v12.10.1 | `scripts/AcadianGY_12.10.1.r` | evolved through 12.6.x-12.9.x build scripts (not a single derivation file; see git log `--follow`) | `scripts/scorecard_v1210.R` and `scripts/regen_five_way_scorecard_frozen.R` aggregate per-stand `cb_v12101_results.csv` / `cb_v12102_results.csv` into the five-way scorecard (`scorecard_five_v1210_frozen.csv`); domain mask in `scripts/v12101_domain_scorecard.R`; gate-off regression check in `scripts/smoke1210.R` | 705-stand in-domain pooled MagPlot set (`POOLED_indomain`) | `v12.10.1-frozen-aug2026` (commit `e5d7457`) |
| v12.11 | `scripts/AcadianGY_12.11.r` | lever fits: `fit_mort_v1211.R`, `lever4_RO_coef_castle.R` | `scripts/forestgroup_scorecard_v1211.R` (forest-group scorecard); `scripts/bench_ns_long_scorecard.R` and `scripts/bench_ns_scorecard.R` (Nova Scotia); `scripts/smoke1211.R` (gate-off regression vs 12.10.2) | 11 staged sources per the 4 August height-coverage census, including CTRN, PEF, Baxter, NB+QC MagPlot, NS PSP | `v12.11-candidate-aug2026` (commit `ba05a5d`) |
| v13.1 | `scripts/AcadianGY_13.1_DRAFT.r` | `v131_hier_assembly.R`, `v131_hier_fit.R`, `v131_growth_assembly_fit.R`, `v131_brms_fit.R`, `v131_mort_repair*.R`, `v131_subplot_refit*.R` | `scripts/bench_parity_split_ms_v131*.R`, `scripts/v131r_gate.R`, `scripts/v131_loro.R` | **DRAFT, not reproducible.** Mid-refit on Cardinal as of the 5 August pass-6 handoff; Bayesian brms fit has not converged on the full crossed-effects geometry (job left RUNNING). Not adopted, not scored to release standard. Filename carries `_DRAFT` deliberately. | **Not tagged.** Explicitly excluded from the "scored" set below. |

### Tag audit: existing tags verified, not duplicated

Four annotated tags already existed (`v12.6.1-candidate`, `v12.7.0-operational`,
`v12.10.1-frozen-aug2026`, `v12.11-candidate-aug2026`). Each was checked with `git diff <tag> HEAD
-- <engine file>`, and each tag's commit contains the exact, unchanged engine file listed above (the
diff is empty in all four cases; the last commit to touch each engine file is the same commit each
tag points at, confirmed independently with `git log --oneline --follow -- <file>`). No new
`*-scored` tags were created, since that would duplicate correct, existing tags. Instead, each
commit received a `git notes` entry (`refs/notes/commits`, view with `git log --show-notes` or `git
notes show <tag>`) recording the audit, the harness, and the datasets. This is documented rather
than silently done: see the commands below.

```
git notes add -m "REPRODUCIBILITY AUDIT ..." v12.6.1-candidate
git notes add -m "REPRODUCIBILITY AUDIT ..." v12.7.0-operational
git notes add -m "REPRODUCIBILITY AUDIT ..." v12.10.1-frozen-aug2026
git notes add -m "REPRODUCIBILITY AUDIT ..." v12.11-candidate-aug2026
```

Git notes are not pushed by a normal `git push` (they need `git push origin refs/notes/commits`);
flag this to whoever owns the remote so the notes travel with the tags.

### Known gap, stated honestly

For v12.10.1 and v12.11, the harness scripts in this repo aggregate and score pre-computed
per-stand result files (`cb_v12101_results.csv`, `cb_v1211_results.csv`, etc.), but the driver
script that actually executes the engine against the raw stand records to produce those CSVs was
not found as a distinct, checked-in file for either version.
`scripts/forestgroup_scorecard_v1211.R` says so explicitly in its own header ("this script does not
edit or execute AcadianGY_12.11.r"). For v12.7.0 and v12.7.1 that driver does exist in-repo
(`scripts/comprehensive_bench.R` and `scripts/comprehensive_bench_coupled.R`, both parameterized by
a `MODEL_FILE` environment variable), and it is very likely the same pattern was reused on Cardinal
for 12.10.1 and 12.11 with `MODEL_FILE` repointed, but no 12.10.1- or 12.11-specific copy was
preserved under its own filename in this repository. This is flagged rather than guessed at; do not
assume a script exists just because the pattern is obvious.

## How to actually rerun this

None of this is portable off Cardinal today. The honest reproduction path:

1. **Connect to OSC Cardinal**, account `puom0008` (the `osc-cardinal` connector, or SSH directly;
   do not attempt this from the Cowork sandbox, which has no R and cannot reach Cardinal).
2. **Load the R module exactly as pinned**: `module purge; module load gcc/12.3.0 R/4.5.2`. The gcc
   prerequisite is required, and the purge first avoids a silent intel-compiler swap. This pin
   matters: the 5 August pass-6 handoff records that R/4.4.0 against the 4.5.2 library path fails
   with an undefined symbol on `data.table`, so an R version mismatch is a real, previously-hit
   failure mode, not a theoretical one.
3. **Personal library path**: `/users/PUOM0008/crsfaaron/R/rhel9/4.5.2` (the harness scripts set
   this explicitly via `.libPaths()`; several also list the older 4.4.0 path as a fallback).
4. **Install the dependency manifest** (below) with `install.packages()`; CRAN is reachable from
   Cardinal (it is not reachable from the Cowork sandbox).
5. **Locate the input data on Cardinal**, not in this repository. The engine and harness scripts
   reference working directories such as `~/magplot/verify`, `~/silc_cfi`, and `/fs/scratch/
   PUOM0008/crsfaaron/maine_cfi`; these hold the tree lists, plot manifests, and coordinate data
   that never enter git or Zenodo in raw form. FIA true plot coordinates in particular are
   restricted and stay server-side on Cardinal; only fuzzed or aggregated positions ever leave.
6. **Source the tagged engine file**, then run the matching harness from the table above,
   pointing `MODEL_FILE` (where the harness supports it) at the tagged version.
7. **Compare against the frozen numbers** in the corresponding benchmark report / GTR in this repo
   as the acceptance check; the scorecard CSVs under `results/` here are the aggregate (coordinate-
   free) output of that process and are already checked in.

This is a Cardinal-resident reproduction path, not a portable one. Nothing here claims a plain
`install.packages()`-and-go story; the real dependency is Cardinal's R module and its
licensed/restricted data holdings, and that is stated rather than hidden.

## Dependency manifest

Extracted by grepping every `library(...)` / `require(...)` call across the engine files (a) and
scoring harnesses (c) identified above (v12.6.1, v12.7.0, v12.10.1, v12.11, plus their harnesses):

- `data.table`
- `dplyr`
- `nlme`
- `purrr`

The v13.1 draft development scripts (not part of the reproducible/scored set, listed for
completeness since v13.1 is included in this bundle in DRAFT state) additionally pull in:

- `lme4` (glmer hierarchical mortality fits)
- `brms` (Bayesian refit, not yet converged as of the 5 August pass-6 handoff)

No other packages appeared in the engine or harness files inventoried for this bundle. This is not
a claim that the full Cardinal environment has no other dependencies (build/plotting/data-prep
scripts outside the (a)/(c) categories were not exhaustively grepped), only that these four are
what the scored engine-plus-harness pairs require.

## What is now tagged and documented vs what still requires Cardinal

Tagged and documented in this repo: the exact engine file for v12.6.1, v12.7.0, v12.10.1, and
v12.11, each confirmed unchanged at its tag; the harness scripts that scored each version, to the
extent they exist as checked-in files (the v12.10.1/v12.11 driver gap is stated above, not papered
over); the dependency manifest; the R version pin.

Still requires Cardinal: all input data (tree lists, plot manifests, coordinates), the actual
compute to rerun a projection, and, for v12.10.1 and v12.11, the specific driver invocation that
turns raw stand records into per-stand predictions. v13.1 is excluded from the reproducible set
entirely; it is mid-refit and not scored to release standard.
