# DRAFT, not registered: a relative height term for the QC height increment, for 14.3 (PREREG45)

5 October 2026, draft for Aaron's decision. Not registered, nothing run. It opens 14.3 engine work, which is Aaron's call;
everything below is a proposal. No coordinates. No em dashes.

## Why, from results already on record

PREREG44 showed that no scalar QC multiplier gives a credible 100 year top height path from measured stand lists: 0.111 stalls
(14.49 to 17.29 m, 0.92 of ESI) and 1.242 keeps rising (28.01 m, 1.50 of ESI). PREREG37 already holds the mechanism. On field
tag pairs, fold B, the unanchored predicted increment is flat across relative height (0.147, 0.150, 0.139 and 0.143 m/yr for
HT1/ESI below 0.5, 0.5 to 0.75, 0.75 to 1 and 1 to 1.25) while observed increment falls (0.243, 0.191, 0.119 and 0.075 m/yr),
so observed over predicted falls from 1.655 (1.377 to 1.929) to 0.523 (0.260 to 0.774); fold A agrees (1.514 to 0.654).
The coded `dht` (Kuehne et al. 2022, AcadianGY_13.1.r lines 1584 to 1598) has no relative height or site curve term; ESI
enters only as exp(b7 csi²), worth a factor of 1.028 across the QC ESI range. Any single multiplier that fits the pooled
increment (near 1.17 to 1.24) therefore over predicts tall trees by about a factor of two, which is the unbounded rise in
PREREG44, and 0.111 under predicts every class.

## Proposed design

Arm `qc_rh`: replace the QC scalar by m(r) = exp(a + b r), r = current HT / stand ESI, reassigned every annual step (the
PREREG33 per year reassignment hook, applied to height rather than DBH). Fit a and b on fold A field tag survivors (`pass28qc`
field tags), obs ~ p0 m(r), the PREREG37 estimator; nothing else refit. Benchmark gates on fold B as PREREG38 (pooled ratio
0.90 to 1.10, every DBH class and every relative height bin within 0.04 m/yr of zero bias, dominant cohort level, published
and measured TOPHT, C1 volume, BA and stems). Long run: the PREREG44 stand list grid (same 36 stands, driver_p44 with a new
reassignment branch and the G0 and G0b identity gates), non inferior to qc141 and, in addition, a credibility bound on 100
year top height relative to ESI whose value and source must be fixed at registration. NB untouched; its scalar 0.579 has the
same hand calculated origin (PREREG43 addendum 3) and could be a second arm.

## Choices for Aaron

1. Open the 14.3 QC height increment track at all, or park QC for 14.3.
2. The form: exponential in r (two parameters) or a piecewise linear knot at r = 1.
3. The source of the 100 year top height bound (a published QC site index curve, or the measured stand frontier).
4. Whether NB gets the same treatment as a second arm.
