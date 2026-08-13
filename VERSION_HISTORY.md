# AcadianGY / FVS-ACD version history

Built 13 August 2026 to accompany the 31-file version lineage now in `scripts/` (`AcadianGY_12.3.6.r`
through the current model of record `AcadianGY_13.1.r`). Sourced from the dated handoffs in
`docs/handoffs/`, the model source itself, and Cardinal file metadata; every claim below is
traceable to one of those. Where a detail could not be verified from a primary source it is marked
`[unverified]` rather than guessed. No em dashes.

## How to read this

Dates are the file's last-modified timestamp on Cardinal (when the version was finalized), not
necessarily when work on it started. Versions marked **shipped** were an actual operational base at
some point; **prototype** versions were exploratory branches that did not become the operational
base; **superseded** versions were replaced before or shortly after reaching production. "Frozen"
means the file is pinned as an unchanging reference point other work is scored against.

## Era 1: v12.3.x, early prototypes (21 to 28 May 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.3.6` | 21 May | 154 KB | prototype |
| `12.3.6_uploaded` | 21 May | 154 KB | prototype (byte-identical upload copy of 12.3.6, `[unverified]` whether any diff exists) |
| `12.3.7` | 22 May | 155 KB | prototype |
| `12.3.7_dbg` | 26 May | 155 KB | prototype, debug build |
| `12.3.8` | 26 May | 155 KB | prototype |
| `12.3.9` | 28 May | 156 KB | prototype |
| `12.3.10` | 28 Jun | 158 KB | prototype |

Per `docs/handoffs/20260629_v12_version_history_and_reversion.md`, the Chen et al. (in prep) stand
basal-area increment cap was added at version 12.3.0 and initially applied at the plot level before
being moved to the stand level (a cap on summed tree diameter increment, itself capped at 0.227
percent of plot BA, the 5th percentile of Maine FIA). The 12.3.x line is this refinement's
development arc. Kuehne et al. (2022) diameter and height increment equations (replacing Russell,
Weiskittel et al. 2013/2014) were adopted at 12.1.1, before this repo's lineage starts.

## Era 2: v12.5 to v12.7, production refactor (6 Jun to 30 Jun 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.5.0` | 6 Jun | 176 KB | shipped, production refactor baseline |
| `12.5.0_mortcal` | 8 Jun | 175 KB | variant, MORTCAL enabled |
| `12.6.0` | 28 Jun | 178 KB | shipped |
| `12.6.1` | 28 Jun | 179 KB | shipped, was the README's stated "production candidate" as of late June |
| `12.6.2_proto` | 28 Jun | 180 KB | prototype |
| `12.6.2b_proto` | 29 Jun | 180 KB | prototype |
| `12.6.4` | 29 Jun | 179 KB | shipped |
| `12.6.5` | 30 Jun | 180 KB | shipped |
| `12.7.0` | 30 Jun | 181 KB | shipped |
| `12.7.1` | 30 Jun | 183 KB | shipped |

Per the (now historical) README section: 12.5.0 was the production refactor baseline, with legacy
flags reproducing an even earlier state bit-for-bit. Refinements over that baseline, all gated:
ESI site input, site-independent SDImax, SDImax-ceiling self-thinning, expected-value ingrowth;
MORTCAL optional and off by default (hence the separate `12.5.0_mortcal` variant). 12.5.0 to 12.6.0
roughly halved the regional over-prediction, basal area bias +6.8 percent to +3.3 percent
(`docs/handoffs/20260629_AcadianGY_v126_benchmarking.md` and the README's key findings).

## Era 3: v12.9 to v12.10, operational base and the freeze (1 Jul to 4 Jul 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.9.0` | 1 Jul | 186 KB | shipped |
| `12.9.2` | 2 Jul | 194 KB | shipped, became the actual file behind the frozen "v12.10.1" operational base |
| `12.10` | 2 Jul | 191 KB | shipped |
| `12.10.1` | 3 Jul | 193 KB | **frozen**, the August operational baseline |
| `12.10.2` | 4 Jul | 193 KB | shipped |

This is the most load-bearing entry in the whole lineage and the one detail most worth getting
right. Per `docs/handoffs/20260710_v1210_freeze_and_v13_migration_plan.md`: "the scorecard baseline
`cb_v12102` was produced from `AcadianGY_12.9.2.r` plus a specific ops recipe, not from a standalone
12.10.x file, so 'freeze v12.10.1' means freezing that model-plus-recipe." The shipped model is
`AcadianGY_12.9.2.r` run through `bench_parity.R` with: the ESI-consistent dominant-height anchor
recalibration (`ops$use.esi.anchor.recal`, region coefficients `ops$esi.anchor.coef`, NB
`c(0.885, 0.01027)`, QC `c(0.441, 0.03783)`, applied inside `calc_dht` every year), the brms
composition- and ecoregion-aware SDImax, a region-aware two-segment self-thinning break, a
density-released ingrowth term, and per-province dominant-height afac factors (NB_AFAC 0.579,
QC_AFAC 0.111). The in-domain base scorecard carries an offsetting-bias signature: pooled BA about
-9 percent, top height about +4 percent, TOTVOL about -1.6 percent by cancellation (FIA NSVB, TOST,
Bakuzis). `AcadianGY_12.10.1.r` itself (the file) is the frozen reference used by later Bakuzis
comparisons (for example pass 10's `bakuzis_ship18.R`, which loads `~/_scripts/AcadianGY_12.10.1.r`
as its BASE arm).

## Era 4: v13.0, joint re-anchor, parked (10 to 11 Jul 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `13.0` | 10 Jul | 196 KB | **superseded / parked**, not adopted |
| `13.0_v2` | 11 Jul | 198 KB | superseded / parked |
| `13.0_wideclamp` | 11 Jul | 198 KB | superseded / parked, widened ESI-anchor clamp variant |

Per the same freeze/migration handoff: the v13.0 joint dominant-height and basal-area re-anchor was
fit on 13,894 ME/NH/VT clean in-domain remeasurement pairs and each component was individually
unbiased (increment ratio 1.00 for both height and net BA). But the height half initially targeted
a code path (`ops$use.esi.domht`) the operational harness has disabled, so it had to be redirected
to the harness-native hook (`ops$use.esi.anchor.recal` / `ops$esi.anchor.coef` inside `calc_dht`).
After that redirect and a BA-fix iteration, the gate runs still failed: the first fixed-BA harvest
inverted the bias (-9.8 percent under to +9.8 percent over, driven by New Brunswick, not Quebec) and
a later fully-fixed run moved the failing axis to the height re-anchor instead. Verdict across all
harvests: **PARK v13.0**. It did not clear the gate on either axis simultaneously. v12.10.1 stayed
the shipped August base. The BA-only correction is preserved in the file for reference but was never
adopted operationally.

## Era 5: v12.11, hardwood fold-in (22 Jul 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.11` | 22 Jul | 215 KB | shipped, hardwood form/risk update |

Per the repo commit history (`04d4064`, "Hardwood plan: fold in Ryan Smith 2022 thesis"): v12.11
folds in Ryan Smith's 2022 thesis, an 8-species hardwood form/risk and product-ratio model set with
usable coefficients. The thesis (Chapter 2) independently found FVS over-predicts hardwood sawlog
volume by 44 to 66 percent, which corroborates this project's own benchmark findings; hardwood
form/risk itself is noted as hard to predict. The thesis PDF is archived in `refs/`.

## Era 6: v13.1, hierarchical refit and the current model of record (15 Jul to 13 Aug 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `13.1proto_hwmod` | 15 Jul | 196 KB | prototype, hardwood modification |
| `13.1_DRAFT` | 22 Jul | 225 KB | draft, pre-canonical |
| `13.1_PREV_20260725_ingfix` | 25 Jul | 229 KB | superseded waypoint, ingrowth fix |
| `13.1_PREV_20260728_ingnorm` | 28 Jul | 231 KB | superseded waypoint, ingrowth normalizer |
| `13.1` | 13 Aug (current) | 235 KB | **shipped, current model of record** |

Per the freeze/migration handoff, v13.1 (hierarchical mortality and ingrowth refit) initially failed
on two independent problems: a trivial ingrowth code bug and a real mortality convergence
pathology (divergences, treedepth, and low E-BFMI together, pointing at posterior geometry rather
than a simple knob). The dated waypoint files trace the fix sequence: `_PREV_20260725_ingfix` is the
state after the ingrowth code bug fix; `_PREV_20260728_ingnorm` is the state after the ingrowth
normalizer was introduced (the same normalizer whose silent-fallback failure mode pass 9 Track E
diagnosed and pass 11 fixed on 13 August, unrelated to this file's own correctness, since the
normalizer file itself, not the model code, was what went missing at runtime). `AcadianGY_13.1.r`
(current) is the file `~/AcadianGY_13.1.r` on Cardinal, never edited directly since; all subsequent
tuning (ONSET, LEVER 3b, ingrowth multiplier, the ship18 configuration) is applied as overlay
scripts sourced after it loads, per the model-of-record discipline documented in every pass 9
through 11 handoff.

As of pass 10 (12 August 2026, `docs/handoffs` on the `hardwood-formrisk-wip` branch, not yet merged
to `main`), the leading configuration is **ship18**: `sdimort.onset=0.55`, the LEVER 3b
survivor-increment correction, `ingrowth.mult=2.5`, r2 refit. Scored across 10 benchmark sources, 7
of 8 with a prior baseline improve on TOTVOL and basal area bias, one (pef) worsens slightly, and
the Bakuzis biological-realism battery passes 4 of 5 relations (one new flag, softwood Reineke
self-thinning, right at the acceptance boundary, shipped as a disclosed tradeoff). Pass 11 (13
August) fixed a silent-failure defect in the hierarchical-posterior ingrowth path unrelated to
ship18's hand-lever configuration (ship18 never touches the hierarchical posterior switches).

## What this document does not cover

This traces the `AcadianGY_*.r` model file lineage only. It does not repeat the full pass-by-pass
benchmark numbers, which live in the dated handoffs themselves (`docs/handoffs/` for the pre-August
history, `hardwood-formrisk-wip` branch handoffs for pass 9 onward), nor the Zenodo-deposited
v12.10.1 package (`zenodo_v12101/`), which packages that frozen version's data and metadata
separately for citation.
