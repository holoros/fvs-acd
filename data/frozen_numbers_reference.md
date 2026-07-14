# FVS-ACD five-way, FROZEN-HARNESS authoritative numbers (14 July 2026)

Source: scorecard_five_v1210_frozen.csv, produced by re-benching every model on the exact frozen operational harness (NB_AFAC 0.579, QC_AFAC 0.111, esi.anchor.coef NB c(0.885,0.01027) QC c(0.441,0.03783), USE_BRMS/USE_ANCHOR TRUE, IRC 0.58, IRK 8, SDMAX 1.0, INDOMAIN, ingrowth min DBH 5.0, management gate OFF for the base). Step 1 verification reproduced the frozen cb_v12101_results.csv to the sixth decimal, so this harness is confirmed. These supersede all earlier scorecard numbers. No em dashes. n = 705 in-domain stands.

IMPORTANT harness note: because bench_parity fully specifies the operational ops, v12.7.1, v12.9.x, and v12.10.1 (gate off) are byte-identical on the pooled base scorecard. The five-way therefore has three distinct engines at pooled scale: v12.5.0, v12.7.0, and the shared v12.7.1 / v12.9.x / v12.10.1. v12.9.x and v12.10.1 differ only in the managed cells (the Chapter 11 gate), shown in the management-class table.

## Pooled five-way level bias (percent), nine NSVB metrics

| metric | v12.5.0 | v12.7.0 | v12.9.x | v12.10.1 | OSM |
|---|---|---|---|---|---|
| basal area | +2.9 | -13.4 | -9.9 | -9.9 | -2.0 |
| stand density index | +5.1 | -12.1 | -9.4 | -9.4 | -4.1 |
| quadratic mean diameter | -4.9 | -0.7 | +1.0 | +1.0 | +11.0 |
| top height | +4.6 | +3.7 | +4.0 | +4.0 | +4.4 |
| total volume | +9.3 | -8.3 | -3.9 | -3.9 | +1.6 |
| merch volume | +8.4 | -9.1 | -4.8 | -4.8 | +1.0 |
| sawlog volume | +7.8 | -9.5 | -5.2 | -5.2 | +1.5 |
| aboveground biomass | +9.7 | -8.1 | -3.9 | -3.9 | +1.1 |
| stand value | +11.0 | -6.7 | -2.1 | -2.1 | +2.6 |

## Pooled rollup

| model | mean abs level bias (%) | mean NSE | RMSE total volume (m3 ha-1) | TOST level equiv (of 9) |
|---|---|---|---|---|
| v12.5.0 | 7.1 | 0.71 | 53.1 | 4 |
| v12.7.0 | 8.0 | 0.73 | 49.6 | 2 |
| v12.9.x | 4.9 | 0.71 | 52.3 | 7 |
| v12.10.1 | 4.9 | 0.71 | 52.3 | 7 |
| OSM | 3.2 | 0.75 | 48.5 | 8 |

## What changed vs the numbers currently in the documents

v12.9.x, v12.10.1, and OSM are UNCHANGED (already correct). Only v12.5.0 and v12.7.0 change, because the docs still carry their inflated afac=1 values:
- v12.5.0: top height +10.7 to +4.6, total volume +18.1 to +9.3, basal area +4.9 to +2.9, MAB 13.0 to 7.1.
- v12.7.0: top height +9.6 to +3.7, total volume -2.1 to -8.3, MAB 5.1 to 8.0.

Narrative: on the frozen harness every model's top height lands in the +3.7 to +4.6 band (the older versions were not actually over-predicting height by +9 to +11; that was the afac bug). v12.5.0 is a strong volume over-predictor (+9.3), v12.7.0 a volume under-predictor (-8.3). OSM still leads pooled bias (3.2 vs 4.9) and NSE (0.75 vs 0.71); FVS-ACD leads QMD (+1.0 vs +11.0).

## Province table (bias %, NB n=355, QC n=350)

NB: BA v12.5.0 +0.8, v12.7.0 -10.0, v12.9.x/10.1 -8.8, OSM -2.4; TOPHT +4.6 / +4.1 / +4.2 / +5.7; TOTVOL -1.6 / -13.4 / -11.8 / -8.0; VALUE -2.3 / -13.9 / -12.2 / -8.9.
QC: BA v12.5.0 +4.5, v12.7.0 -16.2, v12.9.x/10.1 -10.8, OSM -1.6; TOPHT +4.6 / +3.4 / +3.9 / +3.5; TOTVOL +18.7 / -3.9 / +2.9 / +9.8; VALUE +22.6 / -0.6 / +6.6 / +12.6.

## Forest-type table (bias %, Softwood n=321, Mixedwood n=186, Hardwood n=178; 20 unclassified excluded)

Softwood: BA v12.5.0 +0.8, v12.7.0 -16.0, v12.9.x/10.1 -14.0, OSM -2.3; TOPHT -0.6 / -1.4 / -1.2 / +3.9; TOTVOL +0.6 / -16.4 / -14.1 / -1.0.
Mixedwood: BA -2.1 / -17.0 / -12.5 / -7.7; TOPHT +3.2 / +2.1 / +2.6 / +1.8; TOTVOL +7.2 / -9.5 / -4.1 / -3.9.
Hardwood: BA +15.3 / -1.9 / +3.9 / +7.1; TOPHT +12.3 / +11.4 / +11.7 / +6.9; TOTVOL +31.3 / +11.4 / +19.0 / +14.6.
(v12.9.x and v12.10.1 identical in every forest-type cell; hardwood is the shared frontier for every model including OSM.)

## Management-class table (bias %; v12.9.x = gate off, v12.10.1 = gate on)

unmanaged (n=266): BA v12.5.0 +2.5, v12.7.0 -13.7, v12.9.x -9.9, v12.10.1 -9.9, OSM -2.0; TOTVOL +7.5 / -9.7 / -5.3 / -5.3 / -1.6. (v12.9.x = v12.10.1, the gate confirmation.)
planted (n=51): BA -14.5 / -28.2 / -24.9 / -4.4 / -20.9; TOTVOL -14.0 / -28.0 / -23.7 / -10.8 / -19.7.
PCT (n=95): BA -3.2 / -17.2 / -15.6 / -1.3 / -5.4; TOTVOL +1.9 / -13.6 / -11.3 / -2.0 / -0.1.
managed (n=146): BA -7.4 / -21.3 / -19.0 / -2.5 / -11.2; TOTVOL -4.0 / -19.0 / -15.9 / -5.3 / -7.4.

Managed-cell story (holds, frozen numbers): the Chapter 11 gate closes the managed gap sharply (planted BA -24.9 to -4.4; PCT BA -15.6 to -1.3; managed BA -19.0 to -2.5) and v12.10.1 beats OSM on every managed class in absolute basal-area bias (managed 2.5 vs OSM 11.2, planted 4.4 vs 20.9, PCT 1.3 vs 5.4). FROZEN-BASIS SHIFT to flag: gate-on planted total volume is now -10.8 (was -4.0 in the pre-freeze mgmt scorecard), because the frozen afac lowers untreated planted-stand (mostly QC softwood) volume so the fixed additive release closes less of the volume gap. Basal-area releases are unchanged.
