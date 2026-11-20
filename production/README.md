# Production model, AcadianGY 12.5.1

These two files are the production FVS-ACD model maintained by Ben Rice (Midgard Natural Resources). They are byte copies of `fvsOL/inst/extdata/` on the `main` branch of MidgardNaturalResources/ForestVegetationSimulator-Interface at commit a8036ef3 (November 20, 2026).

| File | md5 | Role |
|:--|:--|:--|
| `AcadianGY.R` | 285ae5fd2cca0314efbf6f996c70f0e0 | the model, tag AcadianV12.5.1 |
| `customRun_fvsRunAcadian.R` | 5595b151fb75680eb10f438647642866 | the FVS runner that calls the model at FVS stop points |

The official USDA build of FVS ships 12.5.0 (md5 3489f6b8cb68507c1530bce429683b55). Version 12.5.1 changes it in four ways. It maps 17 further FVS-NE species codes to the OH or OS attributes and drops a duplicate pin cherry row (PC, kept as PR). The thinning modifiers take basal area removed in percent, which is what the runner passes. Summary values are guarded against NA. The species calibration multipliers are joined into the tree list when it is built. The November 20 revision passes diameter growth to FVS inside bark using FVS-NE bark ratios, fixes taper and dib calculations, keeps ingrowth tree IDs from colliding with FVS tree IDs, and moves the runner's fvsGetTreeAttrs() call to the correct step.

Changes to the production model are made on Midgard's fork and copied here when a new production version is released.
