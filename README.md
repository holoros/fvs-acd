# FVS-ACD (AcadianGY)

AcadianGY is the R implementation of the Acadian variant of the Forest Vegetation Simulator (FVS-ACD), an individual tree growth and yield model for the spruce-fir and northern hardwood forests of Maine, New Brunswick, Nova Scotia, and Quebec. The model is maintained jointly by the University of Maine and Midgard Natural Resources.

## Production model

The production model is maintained by Ben Rice on the `main` branch of https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface. `production/` holds version 12.5.2: `AcadianGY.R` from pull request #3 to that branch (https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/pull/3, head commit 1d3b116, November 6, 2026) and the runner from commit 0f3b3dda (November 3, 2026). The official USDA build of FVS ships the earlier 12.5.0.

FVS-ACD runs with three files: `AcadianGY.R`, `customRun_fvsRunAcadian.R`, and the FVS-NE shared library (`.dll` on Windows, `.so` on Linux). In R it also needs the `fvsOL` and `rFVS` packages, both built from the FVS interface repository. FVS loads the two R files from `fvsOL/inst/extdata/`, and the runner calls the model at FVS stop points to impute missing heights and crown ratios and to replace diameter growth, height growth, mortality, ingrowth, and optionally merchantable volume.

`docs/production/AcadianModelOverview.html` describes each model component with its source and R function, and `docs/production/FvsAcdUserGuide.pdf` explains how to run the variant in FVS.

## Research versions

Research versions from 12.11 to 14.1 (September 24, 2026) tested new mortality, diameter increment, and ingrowth components in R outside FVS. They are not on `main`. The 14.1 files are at tag `research-14.1` (https://github.com/holoros/fvs-acd/tree/research-14.1), and every earlier file is at tag `archive-2026-11-02` (https://github.com/holoros/fvs-acd/tree/archive-2026-11-02). Components that earn a place in production will be added to `AcadianGY.R` in its coding style, each behind a switch, meaning a setting in `ops` that turns the component on and is off unless a user sets it. Open work is listed in the issues (https://github.com/holoros/fvs-acd/issues).

## What is here

| Path | Contents |
|:--|:--|
| `production/` | the 12.5.2 model and its FVS runner |
| `docs/production/` | the model overview and the FVS-ACD user guide |
| `CLAUDE.md` | rules for AI assistants working on this code |
| `CHANGELOG.md` | releases with file checksums, and where to find each |
| `CITATION.cff` | citation record |

## Data policy

FIA true plot coordinates, tree lists keyed to plots, and proprietary industry inventories are never committed.

## Citation

Cite the Zenodo concept DOI, https://doi.org/10.5281/zenodo.22996790, which resolves to the latest deposited version, and state the version used. The deposit is licensed CC BY 4.0. The code does not yet carry a license file. For the diameter and height increment equations, cite Kuehne, Weiskittel, and Kershaw (2022, *Mathematical and Computational Forestry & Natural-Resource Sciences* 14(2):9-31).

## Contact

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine (aaron.weiskittel@maine.edu), and Ben Rice, Midgard Natural Resources.
