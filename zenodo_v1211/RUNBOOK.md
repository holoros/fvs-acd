# Runbook: FVS-ACD v12.11 Zenodo deposit

Staged 4 August 2026. Nothing has been uploaded. This is a NEW concept record, not a version of the
v12.10.1 package in `../zenodo_v12101/`, which was itself staged on 10 July and, on the evidence in this
repository, never fired.

## Why a new record and not a version

The v12.10.1 package is `upload_type: software` and titled for the model. This one is `upload_type: dataset`
and is the benchmark: six model generations, the scorecards behind every number, and the height-coverage
census. Cutting it in as a version of a software record would give a reader who follows the citation a landing
page titled for a model release, and the two have different resource types. Separate concept records is the
correct shape.

## The one command

Publishing cannot originate from the Cowork environment by design, so you run this from wherever your
`~/.zenodo_token` lives (Cardinal or the laptop). From inside `zenodo_v1211/`:

```
python3 check_deposit.py && \
python3 upload_to_zenodo.py --token-file ~/.zenodo_token \
    --metadata zenodo_metadata.json --files-list files_to_upload.txt
```

That creates a reviewable DRAFT and prints the deposition id, the edit URL and the reserved DOI. Look at the
draft before publishing, specifically that the graphical abstract previews at the top rather than a CSV. Then
publish from the edit page, or re-run with `--publish` appended.

Publishing a NEW record is NOT idempotent. Re-running after a successful publish creates a second record
rather than a no-op.

## Gate results, run 4 August 2026

All six gates pass. 33 files staged, 0 missing.

| Gate | Result |
|---|---|
| 1 lead file | pass. `00_FVS-ACD_v1211_graphical_abstract.png` is first in the manifest, sorts first, and is named in `default_preview` |
| 2 source freshness | pass. 2 rendered docx/md pairs, 0 stale |
| 3 restricted data | pass. 30 files, 759,833 characters scanned, 0 hard hits, 0 waived |
| 4 checksums | 33 SHA-256 written to `CHECKSUMS.sha256` AFTER the last render |
| 5 code reproduces data | pass. 18 CSVs, 0 without a deposited producer |
| 6 metadata | pass |

### Gate 3 detail, the restricted-data audit

Patterns searched across every staged text, code and data file: FIA true-coordinate field names
(`LAT_ACTUAL`, `LON_ACTUAL`, `ACTUAL_LAT`, `ACTUAL_LON`, `TRUE_LAT`, `TRUE_LON`, `LAT_FUZZ`, `LON_FUZZ`,
`PLT_CN`), restricted-file tokens (`_SERVERSIDE`, `FIA.xy`, `per_plot_embedding`, `plot_coords`), decimal
degrees inside the Acadian envelope at three or more decimals, adjacent latitude and longitude pairs, and
degree-minute-second strings. Zero hard hits, zero waivers.

One calibration note, because the first run of this gate was wrong in the noisy direction. A bare numeric
range test on decimal degrees is useless here: RMSE, percent RMSE and bias values land in the latitude and
longitude ranges constantly, and the first run failed on five of them, including an `rmse` of
47.0614864894249 and a `pooled_rmse_wmean` of 70.18032664756446. Neither is a coordinate. The gate now
requires coordinate CONTEXT before a literal counts: a coordinate-named column header in a CSV, a lat or lon
term within 40 characters in prose or code, or an adjacent latitude and longitude pair. The field-name,
token, pair and DMS checks are unchanged and remain hard failures everywhere.

### Gate 5 detail

Every deposited table now ships the script that writes it. Five producing scripts were added to the manifest
for this reason, two of them pulled off the analysis cluster where they had never been committed:
`regen_five_way_scorecard_frozen.R` and `forestgroup_scorecard_v1211.R`. Four tables are declared compiled
reference tables with a named source rather than script outputs: `data_dictionary.csv`, `master_scorecard.csv`,
`overall_ranking.csv` and `overall_ranking_summary.csv`, all compiled from the deposited per-source scorecards
and documented in report Section 12. `five_way_scorecard.csv` is declared a superseded legacy table and is
deposited only so a reader can see why it disagrees with the frozen in-domain file.

## Not deposited, and why

FIA true plot coordinates and any per-plot coordinate file. Restricted; server-side only.

The staged per-tree benchmark lists (`bench_*_tree_t2.csv`, `magp_qcnb_tree_t2.csv`). These carry per-plot
records for proprietary provincial and ownership inventories. The census and rescore tables derived from them
are deposited; the tree lists are not.

J.D. Irving per-parcel outputs. Proprietary; aggregates only by agreement.

The Hennigar August 2026 deck. A talk, not an archival artifact, and it duplicates the report.

## After it mints

1. Put the CONCEPT DOI in `CITATION.cff` (`doi` and `url`).
2. Re-run `python3 build_graphical_abstract.py --doi <concept DOI>` so the DOI is stamped on the figure,
   re-run `check_deposit.py` to regenerate the checksums, and upload the refreshed PNG as a new version.
   This is optional polish; do not invent a DOI to fill the space.
3. Add the DOI to the report's data availability statement and to the GTR.
4. Record the DOI in `_context/handoffs/` so the next session has it.

Re-verify any backfill list that is more than a day old before executing it; the exact strings rot fast.
