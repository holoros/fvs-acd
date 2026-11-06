# Production model, AcadianGY 12.5.2

These two files are the production FVS-ACD model maintained by Ben Rice (Midgard Natural Resources). `AcadianGY.R` is a byte copy of `fvsOL/inst/extdata/AcadianGY.R` in pull request #3 to the `main` branch of MidgardNaturalResources/ForestVegetationSimulator-Interface (https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/pull/3, head commit 1d3b116, November 6, 2026). `customRun_fvsRunAcadian.R` is a byte copy from that `main` branch at commit 0f3b3dda (November 3, 2026); pull request #3 does not change it.

| File | md5 | Role |
|:--|:--|:--|
| `AcadianGY.R` | 65ff4cbfb12d3ab5080b4e5a771f687a | the model, tag AcadianV12.5.2 |
| `customRun_fvsRunAcadian.R` | dcb970c4b9a9e228dc3421619ea68a8d | the FVS runner that calls the model at FVS stop points |

The official USDA build of FVS ships 12.5.0 (md5 3489f6b8cb68507c1530bce429683b55). Version 12.5.1 changes it in four ways. It maps 17 further FVS-NE species codes to the OH or OS attributes and drops a duplicate pin cherry row (PC, kept as PR). The thinning modifiers take basal area removed in percent, which is what the runner passes. Summary values are guarded against NA. The species calibration multipliers are joined into the tree list when it is built. Version 12.5.2 returns diameter growth to FVS inside bark, multiplying it by the FVS-NE bark ratio (BKRAT) of each species, because FVS adds DG/BRATIO to DBH (`base/update.f:115`). Before 12.5.2 FVS grew every AcadianGY tree too fast by 1/BKRAT, 3.7% to 13.6% depending on species (5.3% to 11.1% in the tested stands). AcadianGY now stops when it is not run on the 108 FVS-NE species.

Changes to the production model are made on Midgard's fork and copied here when a new production version is released.
