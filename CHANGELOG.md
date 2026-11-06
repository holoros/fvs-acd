# Changelog

## Production releases

| Version | Date | Changes | md5 of `AcadianGY.R` |
|:--|:--|:--|:--|
| 12.5.2 | November 6, 2026 | Diameter growth returned to FVS inside bark: `make_fvs_tree()` multiplies it by the FVS-NE bark ratio (BKRAT) of each species, since FVS adds DG/BRATIO to DBH. On 12.5.1 FVS grew every AcadianGY tree too fast by 1/BKRAT (3.7% to 13.6% across FVS-NE species, 5.3% to 11.1% in the tested stands). Stops if not run on the 108 FVS-NE species. Tested through `customRun_fvsRunAcadian.R` on FVS-NE in eight stands; details in https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/pull/3. In `production/`. | 65ff4cbfb12d3ab5080b4e5a771f687a |
| 12.5.1 | October 24, 2026, revised November 3, 2026 | 17 further FVS-NE species codes mapped to the other hardwood (OH) or other softwood (OS) attributes; duplicate pin cherry row removed (PC, kept as PR); thinning modifiers take basal area removed in percent, which is what the runner passes; summary values guarded against missing values; species calibration multipliers joined into the tree list. In `production/`. | acdcb964b2bf75da965b39ec212423f7 |
| 12.5.0 | June 6, 2026 | Rewrite of 12.3.5 with standardized names, one calculation function per model component, and no plyr dependency. The version in the official USDA build of FVS. | 3489f6b8cb68507c1530bce429683b55 |

Ben Rice's notes at the top of `production/AcadianGY.R` list the changes back to 12.3.0.

## Research versions

These ran in R outside FVS and are not production code. Retrieve a file with `git show <tag>:<path>`.

| Version | Date | Changes | Tag and path | md5 |
|:--|:--|:--|:--|:--|
| 14.1 | September 24, 2026 | Two optional diameter increment multipliers on 14.0.4, one for stems above 12.7 cm in every stand and one for release after commercial thinning. | `research-14.1`, `engine/AcadianGY_14.1.r` | 0bf27dde81240e6bdf59c9a90f0051bd |
| 14.0.4 | September 17, 2026 | Optional mortality in three linked steps (whether a plot loses trees, how much basal area it loses, and which trees die) and a refitted stand basal area growth limit. | `research-14.1`, `engine/AcadianGY_14.0.4.r` | 61f95d99f896e8e513930d6e33a7391a |
| 13.1 | August 13, 2026 | Hierarchical (mixed model) refit. The base file that 14.0.4 and 14.1 load. | `research-14.1`, `engine/AcadianGY_13.1.r` | 5894df6013c701d09e7ba67ba6c2f090 |
| 12.11.1 | September 8, 2026 | Repairs to 12.11 for cases where mortality stopped and projections became growth only; no fitted coefficient changed. | `archive-2026-11-02`, `scripts/AcadianGY_12.11_hardwood-branch-20260908.r` | 127cffc33ec35607e3b138a7acf12384 |
| 12.11 | July 22, 2026 | Hardwood form and risk update. | `archive-2026-11-02`, `scripts/AcadianGY_12.11.r` | 6b4e0b37285d581b2a861c64c99d47d0 |

In a benchmark of October 16, 2026 across 19 sets of remeasured plots, 14.1 had the smallest ten year error of the versions compared, a median absolute biomass bias of 3.8% against 9.6% for a 13.1 configuration. It also overpredicted growth after heavy harvests and lost biomass in most unmanaged stands over 200 year projections, so none of it has moved into production. Studies after 14.1 tested changes to height growth in Quebec, ingrowth, survival in Nova Scotia, and the thinning response, and none was adopted. The reports are in Zenodo version 1.10.0 (https://doi.org/10.5281/zenodo.23670727).

## Repository changes

November 3, 2026. `main` now holds only the production model, its documentation, and these notes. The 14.1 research files moved to tag `research-14.1`. `CLAUDE.md` collects Ben Rice's rules for AI assistants.

November 2, 2026. `main` was reduced from 3,681 files to the 14.1 release. Everything removed is at tag `archive-2026-11-02`, and the 18 former branches are tags under `branch/`.
