# Changelog

## Releases

Each release below is retrievable from tag `archive-2026-11-02` at the path given, for example `git show archive-2026-11-02:scripts/AcadianGY_12.11.r > AcadianGY_12.11.r`. Identify a file by its md5, since several files share a version tag.

| Version | Date | What changed | Path at `archive-2026-11-02` | md5 |
|:--|:--|:--|:--|:--|
| **14.1** | September 24, 2026 | Two diameter increment terms on 14.0.4, a large stem level term L and a thinning release term T, both off by default. Research release, in `engine/`. | `engine/cardinal_frozen_20261019/AcadianGY_14.1.r` | 0bf27dde81240e6bdf59c9a90f0051bd |
| 14.0.4 | September 17, 2026 | Three stage linked mortality and a refitted stand basal area increment target. | `engine/cardinal_frozen_20261019/AcadianGY_14.0.4.r` | 61f95d99f896e8e513930d6e33a7391a |
| 13.1 | August 13, 2026 | Hierarchical refit. Model of record and the base every 14.x file sources. | `engine/cardinal_frozen_20261019/AcadianGY_13.1.r` | 5894df6013c701d09e7ba67ba6c2f090 |
| 12.11.1 | September 8, 2026 | Mortality shutoff repairs M1 to M3 on 12.11; no fitted coefficient changed. | `scripts/AcadianGY_12.11_hardwood-branch-20260908.r` | 127cffc33ec35607e3b138a7acf12384 |
| 12.11 | July 22, 2026 | Hardwood form and risk update. | `scripts/AcadianGY_12.11.r` | 6b4e0b37285d581b2a861c64c99d47d0 |
| 12.10.1 | July 3, 2026 | Frozen operational baseline for August 2026. | `scripts/AcadianGY_12.10.1.r` | 027ad5e5532b801718f8ad0b22bada9d |
| **12.5.1** | October 24, 2026 | Production model, maintained by Ben Rice: 17 further FVS-NE species codes mapped to OH or OS, thinning modifiers take percent basal area removed, NA guards on summaries, species calibration joined into the tree list. Revised November 3, 2026, in `production/`. | `production/AcadianGY.R` on `main` | acdcb964b2bf75da965b39ec212423f7 |
| 12.5.0 | June 6, 2026 | Production refactor of 12.3.5. The version in the official USDA build of FVS. | `scripts/AcadianGY_12.5.0.r` | 3489f6b8cb68507c1530bce429683b55 |

Two lines descend from 12.5.0. The production line (12.5.1) runs inside FVS and is maintained on Midgard's fork of the FVS interface. The research line (12.11 to 14.1) runs in R only.

The file `scripts/AcadianGY_13.1.r` at the archive tag is not the 13.1 release. It is the release file with its version line changed to AcadianV13.2 (md5 6ec1823690ab6756b11e4f6fc684a325). Versions between those listed, and the 12.3.x prototypes, are described in `VERSION_HISTORY.md` at the archive tag.

## Studies since 14.1

Every change proposed since 14.1 was tested under a written pre-registration before any fit, and none has yet replaced a 14.1 component. The full plans, gates, and results are at the archive tag (`docs/preregistrations.md`) and in Zenodo version 1.10.0.

| Study | Question | Outcome |
|:--|:--|:--|
| 14.2 PREREG46 to PREREG49 | Quebec height increment, Quebec long run behavior, the Quebec stems deficit, and a multiyear survival step for Nova Scotia | No candidate adopted. The Quebec stems deficit is ingrowth entering below the inventory floor. |
| 14.2 PREREG50 | Match the ingrowth threshold to the Quebec inventory floor | The stems deviation moves from 24.2 points low to 1.8 points high, so the deficit is mostly a floor handling artifact. Carried to 14.3 as a benchmark convention. |
| 14.3 PREREG1 | Limit T to partial removals | No eligibility rule adopted. Large residual trees after removals grow about two thirds of what 14.1 predicts. |
| 14.3 PREREG2 and PREREG3 | Re-estimate the form of T | Neither selected form adopted; 14.3 keeps the 14.1 T. |
| 14.3 PREREG4 | Senescence conditioned on forest type | No verdict, since a stand count gate failed and FIA tree identifiers do not reliably pair the same tree across visits. |
| Howland decline diagnostic | Why 14.x loses biomass at Howland Research Forest | The linked mortality carries most of the decline relative to 13.1h. The hindcast could not be scored without repeat measurements. |

## Zenodo deposits

Concept DOI [10.5281/zenodo.22996790](https://doi.org/10.5281/zenodo.22996790). Version 1.9.0 (10.5281/zenodo.23665173) and version 1.10.0 (10.5281/zenodo.23670727, October 27, 2026), which adds the cross-version benchmark and PREREG46 to PREREG49.

## Production model added, November 3, 2026

`production/` now holds the 12.5.1 production model and its FVS runner, copied from Midgard's fork at commit 0f3b3dda. The README states which version runs in FVS (12.5.1 on Midgard's fork, 12.5.0 in the USDA build) and which runs in R only (14.1).

## Repository cleanup, November 2, 2026

`main` was reduced from 3,681 files (304 MB) to the 14.1 release, its loader, one example, and three documents. Nothing was deleted from history. The prior state of `main` is tag `archive-2026-11-02`, and each of the 18 former branches is a tag under `branch/`.
