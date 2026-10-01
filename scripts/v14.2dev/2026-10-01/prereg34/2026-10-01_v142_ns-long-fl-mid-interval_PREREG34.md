# Why ns_long_fl under predicts end of interval height at 10 to 19 years: pre-registration 34

1 October 2026, revision 1. Written after reading the PREREG30 result and tables and a fold A look at the stand pairs
frame, before any new fold B quantity was computed. L and T stay at run 14868899. No engine run is made under this
document; only frozen outputs are read. No coordinates are read. No em dashes.

## What was seen (PREREG30, fold B, reported openly)

On ns_long_c fold B the PREREG20 NS height form (v141LTf, b1 0.034416, b2 0.005072) moves the 10 to 19 year level ratio of
tag matched survivors from 1.0441 (v141LT, 14.1) to 1.0247 and TOPHT bias from +5.84 to +2.00 percent (437 stands). On
ns_long_fl fold B, same bin, every arm under predicts: level 0.9353 (v141LT) against 0.9186 (v141LTf), 4,188 trees, 296
stands, 295 sites; TOPHT -8.69 against -11.29 percent, 334 stands. The form makes a low bin lower. Fold A repeats it
(0.9340 against 0.9188, 4,250 trees). All from `~/jobs/v142p30/assembled/gyr142-p30-height_DATA_2026-09-30.csv` and
`gyr142-p30-topht_DATA_2026-09-30.csv`.

**Fold A frame look (exploratory, already done, stated so it cannot be claimed as confirmatory).** In the ns_long_fl 10
to 19 bin, fold A, 230 of 333 stand pairs are NS_RS and 103 NS_OP; in the ns_long_c 10 to 19 bin, fold A, 481 are NS_OP
and 8 NS_RS. No ns_long_fl stand in that bin has an identical PLOTKEY, Y1 and Y2 in ns_long_c, so a same stand frame
comparison is impossible. NS_RS pairs in the bin span a median of 2 links (3 visits), NS_OP pairs 1 to 3. NS_RS ESI is old
harness on every stand. PREREG29 found NS_RS height increment ratios of 0.4 to 0.8 at every state quartile and a matched
program offset of -0.41 to -0.62 on ns_c and ns_long_c, and named NS_RS as outside the 14.2 NS height calibration. The
leading hypothesis is therefore (a), stated before the fold B reading.

## Candidate explanations and the evidence for each

**(a) Program or plot design.** Supported if the bin restricted to NS_OP meets the materiality rule; also read by plot
design variables that separate the programs: plot size (t1 EXPF 25, that is 400 m2, against other), observed diameter
floor (PLOT_OBS_MINDBH 9.1 cm and over against below), and height subsampling (share of t1 frame trees with a measured
height, 1 against below 1). Ruled out if NS_OP alone stays below 0.9947 (1.0247 minus 0.03) and below 0.97.

**(b) Size class or class crossing.** Supported if dropping any one t1 class (below 12.7, 12.7 to 25, 25 cm and over) or
restricting to non crossers meets the rule. Crossers: t2 frame DBH by the key TREE, in a class other than the t1 class,
only on key trees whose t2 frame record has HT equal to key H2 within 1e-9 (a verified match). Fold A coverage of that
match is 3,024 of 12,320 bin and non bin trees, so the crosser test is reported, and it is decision driving only if
coverage in the fold B bin is at least 50 percent of trees.

**(c) Frame effect specific to ns_long_fl.** Read by NLINKS (1, no skipped visit, against 2 and over), LINK_SRC containing
sibling against not, ESI source (cov30m against old harness), and the frame contrast at fixed program: NS_OP in the
ns_long_fl bin against NS_OP in the ns_long_c bin. The 7.0 m old harness ESI offset raises ESI in both ns_long frames,
so it would push predictions up, not down; it is tested only through the ESI source split, since no rerun is made.
Supported if a restriction meets the rule, or if the fixed program frame contrast (NS_OP fl minus NS_OP c) has a 95
percent interval excluding 0 and a magnitude of 0.03 or more.

**(d) A real growth effect.** Read by Y1 (before 1975, 1975 to 1984, 1985 and later), ESI tertile (fold B tertiles of esi8
within the bin), and interval length within the bin (10 to 14, 15 to 19). Supported if a restriction meets the rule.

Survivor status: all key trees are tag matched survivors; stand mortality between visits is read through the stand
basal area ratio BA_T2 / BA_T1 (below 1 against 1 and over), reported under (c).

## Decompositions (fold B confirmatory; the same tables on fold A, exploratory)

For each split: trees, stands, sites, observed mean H2, v141LT, v141LTf and v141LTfi level ratios with 95 percent site
cluster intervals (first 1,000 PREREG20 siteidx draws per set, as PREREG30), and the observed annual height increment.
Each split is computed on the whole bin and within program (NS_OP, NS_RS), so a factor confounded with program is seen.
Sequential (two factor Shapley) decomposition of the v141LTf level gap between the ns_long_fl and ns_long_c 10 to 19 bins
for each factor F: with s the observed H2 share and r the level by F group, gap = sum (s_fl minus s_c)(r_fl plus r_c)/2
(composition) plus sum (r_fl minus r_c)(s_fl plus s_c)/2 (within). A group with fewer than 200 trees in the ns_long_c bin
takes r_c from the ns_long_c group over all intervals. Factors: program, t1 class, NLINKS, Y1 group.

## Materiality rule, fixed now

An explanation is supported if restricting to its subset (or the complement it names) moves the fold B v141LTf level in
the bin to within 0.03 of the ns_long_c reading (1.0247) or of 1, with at least 500 trees in the subset; for the
decomposition it must also carry at least half of the gap as composition. The fixed program frame contrast of (c) is as
stated above.

## Decision rule, in order

1. The bin level ratios by arm do not reproduce PREREG30 to 1e-9: harness failure, no verdict.
2. (a) or (c) supported, and in the explaining subset the residual check passes (v141LTf level no farther from 1 than
   v141LT plus 0.02, and every t1 class with 200 trees or more within the PREREG30 L2 margin, abs(v141LTf minus 1) at most
   abs(v141LT minus 1) plus 0.03): the form is safe on the population it was fit for, and the bin is named a program or
   frame effect.
3. (a) or (c) supported but the residual check fails, or (b) or (d) supported and neither (a) nor (c): the form is not
   called safe on long intervals; the next pre-registered refit is named, for (b) an interval by size term in the
   multiplier fit on ns_long_c and ns_long_fl fold A, for (d) a period or site term.
4. Nothing supported: unexplained; the form is not called safe on long intervals and a long interval refit on fold A is
   named.

14.1 is unchanged under every outcome.

## Verification and outputs

An independent script in `verify_20261001/` with its own fold code and joins recomputes the bin level ratios by arm and
every decision driving quantity, tolerance 1e-9, and ends with `P34_VERIFY_DONE`. One fold B figure (180 mm, 300 dpi).
Files under `~/jobs/v142p34/` only.
