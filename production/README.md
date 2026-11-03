# Production model, AcadianGY 12.5.1

These two files are the production FVS-ACD model maintained by Ben Rice (Midgard Natural Resources). They are byte copies of `fvsOL/inst/extdata/` on the `main` branch of MidgardNaturalResources/ForestVegetationSimulator-Interface at commit 0f3b3dda (November 3, 2026).

| File | md5 | Role |
|:--|:--|:--|
| `AcadianGY.R` | acdcb964b2bf75da965b39ec212423f7 | the model, tag AcadianV12.5.1 |
| `customRun_fvsRunAcadian.R` | dcb970c4b9a9e228dc3421619ea68a8d | the FVS runner that calls the model at FVS stop points |

The official USDA build of FVS ships 12.5.0 (md5 3489f6b8cb68507c1530bce429683b55). Version 12.5.1 changes it in four ways. It maps 17 further FVS-NE species codes to the OH or OS attributes and drops a duplicate pin cherry row (PC, kept as PR). The thinning modifiers take basal area removed in percent, which is what the runner passes. Summary values are guarded against NA. The species calibration multipliers are joined into the tree list when it is built.

Changes to the production model are made on Midgard's fork and copied here when a new production version is released.
