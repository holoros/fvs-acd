# FVS-ACD (AcadianGY)

AcadianGY is the R implementation of the Acadian variant of the Forest Vegetation Simulator (FVS-ACD), an individual tree growth and yield model for the spruce-fir and northern hardwood forests of Maine, New Brunswick, Nova Scotia, and Quebec. The model is maintained jointly by the University of Maine and Midgard Natural Resources.

Two versions live here, and they serve different purposes.

| Version | Role | Where | Runs in FVS |
|:--|:--|:--|:--|
| **12.5.1** | production model, maintained by Ben Rice | `production/` | yes, through `fvsOL` and `customRun_fvsRunAcadian.R` |
| **14.1** | research release, September 24, 2026 | `engine/` | no, R only |

The official USDA build of FVS currently ships 12.5.0. Version 12.5.1 is on Midgard's fork of the FVS interface (commit 0f3b3dda, November 3, 2026), and `production/` holds byte copies of those two files. Version 14.1 adds linked mortality, a refitted stand basal area increment target, and two diameter increment terms, and it has not been moved into FVS.

## Running the production model

FVS loads `AcadianGY.R` and `customRun_fvsRunAcadian.R` from `fvsOL/inst/extdata/`, and the runner calls the R model at FVS stop points to impute missing heights and crown ratios and to replace diameter growth, height growth, mortality, ingrowth, and optionally merchantable volume. To use these files, copy them into that folder of an FVS interface installation.

## Running the 14.1 research release

From the repository root in R:

```r
source("engine/load_acd141.R")
load_acd141()
```

The loader checks every engine file by md5 and sources the stack in order. `examples/ten_year_projection.R` runs one stand for ten years under the release configuration, and `docs/user-guide.md` explains the inputs, the switches, and the outputs. Both were run on November 2, 2026 with R 4.5.1.

## What is here

| Path | Contents |
|:--|:--|
| `production/` | the 12.5.1 production model and its FVS runner |
| `engine/` | the four 14.1 engine files, their two coefficient bundles, and the loader |
| `examples/` | a ten year projection of one stand under 14.1 |
| `docs/user-guide.md` | the 14.1 user guide: inputs, switches, outputs, and the domain of use |
| `CHANGELOG.md` | every release from 12.5.0 to 14.1, with file and md5, and the studies since 14.1 |
| `CITATION.cff` | citation record |

## Earlier versions and the research record

Everything that used to sit on `main`, including every earlier engine file, the pre-registered studies, benchmark packages, reports, and session records, is preserved unchanged at tag `archive-2026-11-02`. Former branches are preserved as tags under `branch/`. `CHANGELOG.md` gives the archive path and md5 of each earlier release, so any of them can be retrieved without a branch. The same record is deposited on Zenodo.

## Data policy

FIA true plot coordinates, tree lists keyed to plots, and proprietary industry inventories stay on the compute hosts and are never committed. Only engine code, coefficients, and aggregate results enter this repository.

## Citation

Cite the Zenodo concept DOI, [10.5281/zenodo.22996790](https://doi.org/10.5281/zenodo.22996790), which resolves to the latest deposited version, and state the version used (AcadianGY 12.5.1 or 14.1). The deposit is licensed CC BY 4.0. The code does not yet carry a license file. For the diameter and height increment equations, cite Kuehne, Weiskittel, and Kershaw (2022, *Mathematical and Computational Forestry & Natural-Resource Sciences* 14(2):9-31).

## Contact

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine (aaron.weiskittel@maine.edu), and Ben Rice, Midgard Natural Resources.
