# Data-description map aggregates (FVS-ACD benchmark)

Aggregated, privacy-safe outputs for figures 12 and 13. Built on OSC Cardinal from
the frozen benchmark (`magplot/verify/frozen_subsidiary_W.rds`, n = 705) joined to
MAGPlot site coordinates. True plot coordinates were used only server-side to bin
stands into a 50 km equal-area hex grid (Lambert azimuthal equal-area, centered at
46.5 N, 68 W). No plot coordinate leaves Cardinal; every file here holds hex cells
and counts only.

Files:
- `hex_counts_50km.gpkg`: 74 hex cells with total stand counts (fields hex_id, n).
- `hex_counts_by_fortype_50km.gpkg`: hex counts split by forest type (softwood, mixedwood, hardwood).
- `stand_counts_by_province.csv`: NB 355, QC 350.
- `stand_counts_by_fortype.csv`: Softwood 321, Mixedwood 186, Hardwood 178, Unknown 20.
- `stand_counts_prov_x_fortype.csv`: province by forest type cross-tab.

Build script (server-side): `magplot/verify/build_data_maps.R` on Cardinal.
