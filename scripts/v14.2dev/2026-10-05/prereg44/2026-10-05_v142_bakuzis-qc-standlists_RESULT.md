# Bakuzis QC grid from measured stand lists, 1.242 against 0.111: PREREG44 result

5 October 2026. Pre-registration `plan/2026-10-05_v142_bakuzis-qc-standlists_PREREG44.md` (revision 1, md5 37cde199, recorded
13:18:06 server time before any stand was drawn or projected). Decision weight fixed by Aaron before the run: the outcome
informs 14.3 only and cannot reopen the 14.2 QC decision. No coordinates; stand identifiers stay in `*_SERVERONLY` files. No
em dashes.

## Verdict

**Rule 2, not cleared. p38_fit (QC_AFAC 1.242) is not non inferior to qc141 (0.111) on the long run relations from measured
stand lists, so 1.242 is not supported on long run grounds for 14.3. 14.2 is unchanged.** Every harness gate passed. Three
relations fail: Reineke (3 new flags; worst margin 1.101 against 0.768), yield density (2 new flags, ESI bins 3 and 4; worst
margin 0.062 against 0.040) and HT monotone on margin (11 flags against 36, but the largest top height fall is 4.87 m against
1.04 m). No new flag on frontier, magnitude, Sukachev, Eichhorn or site ordering.

## Harness gates

| Gate | Result | Threshold |
|:--|:--|:--|
| G0, mode g0 against frozen p19_a0111 | worst scaled difference 0 over 3 stands, 12 columns | at or below 1e-9 |
| G0b, mode grid against frozen PREREG31 dry trajectory | identical, 101 rows, 23 columns | identical |
| G1, trajectories complete | 72 of 72, 101 rows | all |
| G2, age 0 against measured t1 lists | worst scaled difference 2.6e-15 over 72 stand arms | at or below 1e-6 |

G0 and G0b show the driver edit left the existing modes unchanged.

## Stands

36 fold B stands, 3 in each of 12 cells (pool 9 to 17 per cell). ESI bin edges 18.17, 18.80 and 19.20 m; SDI bin edges 322
and 545 (4 cm and over). Cell mean SDI 98 to 881; the largest is below the qc_c 99.9th percentile of 1,178 [F5].

## Relations

| Relation | Unit | Flags p38_fit | Flags qc141 | New | Worst margin p38_fit | Worst margin qc141 | NI |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|
| Reineke (from RD 0.5) | stand, 21 evaluated | 11 | 12 | 3 | 1.101 | 0.768 | fail |
| Frontier | stand | 0 | 0 | 0 | 0 | 0 | pass |
| Magnitude | stand | 0 | 0 | 0 | 0 | 0 | pass |
| HT monotone | stand | 11 | 36 | 0 | 4.87 m | 1.04 m | fail (margin) |
| Site ordering HT, VOL, BA | SDI bin | 3 each | 3 each | 0 | 20 | 20 | pass |
| Eichhorn | SDI bin | 1 | 3 | 0 | 0.013 | not evaluated in S3 | pass |
| Sukachev | ESI bin | 0 | 0 | 0 | 0 | 0 | pass |
| Yield density | ESI bin | 3 | 1 | 2 | 0.062 | 0.040 | fail |

Reineke was evaluated on 21 of 36 stands in each arm (15 never reach RD 0.5 or have fewer than three advancing points);
median slopes -1.27 (p38_fit) and -1.21 (qc141). Site ordering on ESI bin means inverts at all 20 ages in every SDI bin in
both arms, so it does not discriminate: the measured stands differ in more than ESI, as the plan expected.

## Realism, reported

| Arm | Top height, m: t1, 25, 50, 100 yr | Top height over ESI at 100 yr | Stems ha⁻¹ at 100 yr | Volume at 100 yr, m³ ha⁻¹ |
|:--|:--:|:--:|:--:|:--:|
| qc141 (0.111) | 14.49, 16.46, 16.52, 17.29 | 0.92 | 1,034 | 214 |
| p38_fit (1.242) | 14.49, 20.34, 23.62, 28.01 | 1.50 | 1,039 | 281 |

Under 0.111 top height rises 2.8 m in 100 years from a measured start and falls at some point in every stand. Under 1.242
it rises 13.5 m, still climbing at 100 years, with 5 stands above 30 m (maximum 34.8 m). Neither is a credible long run
height path; the first stagnates and the second has no asymptote within the horizon. Figure:
`figs/gyr142-p44-topht-stems_2026-10-05.png` (ESI bin means with 95% intervals).

## Deviation

The registered assembly stopped on an integer and double type clash in the reported dht.mult table. `assemble_p44_r2.R` (md5
5ac535e6) adds `as.numeric()` there only; no gate, relation or rule line changed; no model run was repeated. The r1 log is kept
as `logs/assemble_r1_typeerror.log`.

## Consequence

14.2 keeps 0.111 (unchanged by design). For 14.3, the QC anchor needs more than a scalar: 0.111 starves height growth and 1.242
lifts it without bound over 100 years, which points at the QC height increment form rather than its multiplier. Not decided here.

## Files

Firebreather `~/jobs/v142p44/`: `plan/` (plan, selection tables), `scripts/` (driver, wrapper, selection, chain, assembly r1
and r2), `diffs/`, `logs/`, `g0/`, `out/` (SERVERONLY stand IDs), `assembled/`, `figs/`.
