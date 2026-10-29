# Crown ratio dynamics in AcadianGY_12.11.r: is this a common-cause Lever 5?

Investigation date 2026-07-21. Model file examined: local copy of AcadianGY_12.11.r
(214,449 bytes, 4,488 lines) and the Cardinal copy at ~/_scripts/AcadianGY_12.11.r.
Read only, no edits made. An empirical trace was also run on Cardinal using the
smoke1211.R harness pattern (see section 5).

## Summary answer up front

Crown ratio is not static and imputation is not disabled. Both the version-history
comment that triggered this investigation ("temporarily disabled height and crown
ratio imputation due to problems with FVS stop point 7") is historical: it dates to
the 12.3.2 entry in the changelog (roughly four years before 12.11), and the 12.5.0
"significant rewrite" that followed modularized the model into calc_*() functions,
one of which (calc_hcb(), backed by pred_hcb()) re-implements exactly this
imputation. It runs unconditionally, every cycle, with no ops$ gate. Separately, crown
ratio is updated every projection year by a real, published crown-recession equation
(dhcb(), Russell, Weiskittel & Kershaw 2014), also ungated and always active. The
empirical trace (section 5) confirms CR declines steadily for both survivors and
recruits as a young stand closes canopy, exactly the behavior the biology predicts.

So the mechanism itself is sound and already running in every build back through at
least 12.5.0 (and unchanged through 12.10.2 -> 12.11, since the gate-off smoke test is
byte-identical). Lever 5 is therefore not "turn on CR dynamics" (already on) but a
narrower question: is the existing crown-recession equation well calibrated for the
regimes we now care about (young, high-density, fast-closing developing-end stands),
and does it interact cleanly with the other four levers. See section 6 for the
recommendation.

## 1. CR initialization and imputation

**Initial read from the FVS tree list.** make_acd_tree() (~line 2868-2903) reads the
FVS `cratio` field and converts it to a 0-1 proportion:

```
cr = abs(cratio) * 0.01
hcb = ht - cr * ht
```

(the abs() handles FVS's negative-cratio convention, which signals that a fire or
insect/disease sub-model already computed the HCB change for that tree; sign is
restored on write-back, see make_fvs_tree() ~line 3298-3299.)

**Imputation of missing/invalid values, run every cycle.** Inside
AcadianGYOneStand(), the block at lines 3698-3714 ("Height and crown ratio") runs on
every annual call:

```r
tree = tree %>%
  calc_ht(plot.data = plot.smry) %>%
  dplyr::mutate(ht = case_when((ht %in% c(NA,0) | ht>50) & dbh>2.5 ~ pht, TRUE ~ ht)) %>%
  calc_hcb(plot.data = plot.smry) %>%
  dplyr::mutate(
    hcb = case_when(cr %in% c(NA,0) | cr>99 | is.na(hcb) | hcb>ht ~ phcb, TRUE ~ hcb),
    cr  = case_when(cr %in% c(NA,0) | cr>99 ~ 1-(phcb/ht), TRUE ~ cr))
```

`phcb` comes from pred_hcb() (line 592-606), the Rijal, Weiskittel & Kershaw (2012b)
height-to-crown-base equation, a function of dbh, ht, dominant-height ratio, CCF, and
BAL, with species random-effect intercepts (hcb.pred.spp table, line 538). This is a
real fitted statistical model, not a placeholder default.

There is no `ops$` flag anywhere in the file that gates this imputation (grepped for
`ops$*cr*`, `ops$*hcb*`, `ops$*crown*`: zero hits besides unrelated comments). Unlike
Levers 1-4, which are explicit `ops$use.*` toggles, crown ratio handling has no
on/off switch — it is unconditionally part of every projection.

## 2. Is CR static or dynamic across cycles?

Dynamic, via a genuine crown-recession model, every cycle. The mechanism:

1. `dhcb()` (line 1689-1708), cited to Russell, Weiskittel & Kershaw (2014, Eur J
   For Res 133:1121-1135), computes the annual change in height to crown base as a
   function of current crown length, height increment, current CR, CCF, and species
   shade tolerance:
   ```r
   cl = ht - hcb; cr = cl/ht
   dhcb = (cl + dht) / (1 + exp(b1 + b2*log(cr+0.01) + b3*log(ccf+1) +
                                  b4*log(1.01-cr) + b5*shade^2 + b6*log(shade*cr)))
   ```
2. `calc_dhcb()` (line 1765-1805) is called unconditionally in AcadianGYOneStand at
   line 3746-3748, immediately after `calc_dht()`. A post-commercial-thinning
   modifier (`dhcb_thin_mod`, BF/RS only) can scale it, but the base recession term
   always runs.
3. The output block (line 3768-3776) applies the update and recomputes CR every
   cycle:
   ```r
   tree = tree %>% mutate(year=year+1, dbh=dbh+ddbh, ht=ht+dht,
                           hcb=hcb+dhcb, expf=expf-dexpf, cr=1-(hcb/ht))
   ```

AcadianGYOneStand() runs one year per call (per its own docstring) and is called
once per projection year, so this hcb-update / cr-recompute step executes every
single year of a multi-year run. There is no code path that freezes CR at its
initial value. The only case where CR stops changing is when `ht` itself is stuck at
NA (an edge case observed in the trace below, section 5), which prevents both growth
and the CR update for that specific tree.

## 3. How CR feeds the three components

- **ddbh() (diameter increment, line 850-870, Kuehne model form).** `cr` enters as
  `log(cr)` with coefficient `b3 + ddbh.b3.spp`, base b3 = 0.713456. This is a strong,
  positive elasticity: on the log-log form, a tree with higher CR grows measurably
  faster in diameter, all else equal.
- **dht() (height increment, line 1405-1420, Kuehne model form).** `cr` enters
  linearly with fixed coefficient b3 = 0.394836682501739 (confirms the +0.395 figure
  in the task brief). Positive: taller live crown increases height growth.
- **Survival/mortality — CR's role here is narrower than the WHY framing assumes.**
  The base tree survival function `tree_surv_prob()` (line 1967-1973) is
  `logistic(b0 + b1*dbh + b2*dbh^2)` — dbh only, no CR term. CR enters mortality
  only through `tsurv_sbw_mod()` (line 2014-2021), the spruce-budworm outbreak
  modifier, which is gated (`ops$use.sbw.mod`), restricted to BF/RS/BS/WS, and only
  active in ME/NB during a declared outbreak window (`sbw.cdef>0` and
  `sbw.yr <= year <= sbw.yr+sbw.dur`). The v12.6+ SDImax-ceiling self-thinning block
  (line 3804-3861) and the base stand-mortality functions (`stand_mort_prob`,
  `stand_mort_ba`) use SDI/RD, BA, QMD and composition, not CR. **So under normal
  (non-outbreak) conditions, CR does not directly bias background survivor
  mortality** — it only reaches mortality by way of its effect on ddbh (which feeds
  `tree.mortba` sizing) and indirectly via stand density (RD), which CR does not
  itself drive. This is worth noting because it means a CR fix would have no direct
  first-order effect on the baseline mortality lever (Lever 3/the density-scaled
  mortality work); its leverage is concentrated in ddbh and dht.

## 4. Recruit CR behavior

`create_ingrowth_tree()` (line 2614-2681) does **not** assign new trees a fixed or
default CR. It runs the same statistical apparatus as imputation:

```r
tree.ingrowth = ... %>%
  calc_bal() %>%
  mutate(bal = bal + bal.plot.max) %>%   # place recruits below every existing tree
  calc_ht(...) %>% mutate(ht = pht) %>%
  calc_hcb(...) %>% mutate(hcb = phcb, cr = 1-(phcb/ht))
```

Recruits enter at `ops$ingrowth.entry.dbh` (or `min.dbh.ingrowth`, typically the FIA
5 cm/2-inch merchantable-ingrowth convention) with a BAL set to the plot maximum
(i.e., treated as the most-suppressed tree on the plot), then get a model-predicted
HCB/CR from the same Rijal-Weiskittel-Kershaw equation used for imputed trees. This
naturally produces a high initial CR appropriate for a small, recently-recruited
tree.

Ordering matters: `calc_ingrowth()` is called after `calc_ddbh`/`calc_dht`/`calc_dhcb`
for existing survivors but the new ingrowth rows are only `bind_rows()`-appended to
the output at the very end (line 3878-3882), after the survivor growth-increment
mutate. So recruits do **not** get a diameter/height increment or crown-recession
update in the same year they are created — they enter fully formed at their
recruitment size and CR. Starting the following year, though, they are ordinary rows
in the tree list and go through the identical `calc_ht`/`calc_hcb`/`calc_ddbh`/
`calc_dht`/`calc_dhcb` pipeline as every other tree, so their CR recedes on exactly
the same dynamic footing as everyone else's from cycle two onward. This is confirmed
empirically below.

## 5. Empirical trace (Cardinal)

Ran a standalone script (`cr_trace_1211.R`, written into
`~/magplot/verify/`, reusing the smoke1211.R harness's `init_young()`/`base_ops()`/
`AcadianGYOneStand()` call pattern) against `~/_scripts/AcadianGY_12.11.r`: a 40-tree
young mixed RS/WS/BF stand (dbh 2-5 cm, cr initially NA), ME region, CSI 18,
projected 20 years with ingrowth on. CR snapshotted at years 0, 5, 10, 20.

Selected survivor trees (tree ids 1, 10, 30, 40):

| tree | sp | yr0 dbh/cr | yr5 dbh/cr | yr10 dbh/cr | yr20 dbh/cr |
|---|---|---|---|---|---|
| 1  | RS | 3.12 / NA | 4.32 / 0.538 | 5.58 / 0.544 | 8.07 / 0.507 |
| 10 | RS | 3.64 / NA | 4.92 / 0.532 | 6.23 / 0.535 | 8.79 / 0.497 |
| 30 | BF | 3.98 / NA | 5.58 / 0.533 | 7.12 / 0.510 | 9.95 / 0.462 |
| 40 | RS | 4.77 / NA | 6.40 / 0.524 | 7.96 / 0.521 | 10.85 / 0.481 |

CR is imputed to a plausible mid-range value (0.52-0.54) once ht/hcb become defined,
holds roughly flat through the open-canopy years, then declines measurably (roughly
0.51-0.54 down to 0.46-0.51, an 8-15% relative drop) by year 20 as the stand closes
and CCF rises — exactly the crown-recession signature the model form should produce,
and clearly not static.

Recruit CR trajectory, tree 41 (BF, entered as ingrowth around year 2-3, dbh 5.0 cm
at entry):

| yr | dbh | ht | cr |
|---|---|---|---|
| 5  | 6.45  | 5.10 | 0.525 |
| 10 | 8.22  | 5.77 | 0.501 |
| 20 | 11.30 | 7.17 | 0.452 |

The recruit enters with a high CR (consistent with a small, recently-released tree)
and recedes on essentially the same trajectory and magnitude as the established
survivors above — confirming section 4's code-level conclusion. No evidence of a
fixed/frozen recruit CR that would bias DGR/HGR/survival for the developing end.

One edge case surfaced in the trace worth flagging: tree 20 (WS, smallest starting
dbh, 2.12 cm) never grows and its ht/cr remain NA through all 20 years. This looks
like a tree stuck below a growth-eligibility or height-prediction threshold (dbh
2.12 cm is under the 2.5 cm cutoff used in the ht-imputation case_when at line 3706,
`dbh>2.5`), which means it never gets an imputed height, and therefore calc_hcb/CR
never resolve for it either. This is the one place CR is genuinely "stuck" — not
because dynamics are disabled, but because a small-diameter edge case falls through
the height-imputation gate. Worth a follow-up look since these are exactly the
smallest, youngest trees at the developing end, but it looks like a narrow
input-validation gap rather than evidence against the crown-dynamics mechanism.

## 6. Recommendation: is CR dynamics a worthwhile Lever 5?

**Not as an on/off lever — it's already on and has been since at least 12.5.0, and
the 20-year gate-off smoke test shows 12.11 is byte-identical to 12.10.2 with all new
levers off, meaning nothing in the recent lever work touched this pathway.** The
premise in the task brief (that CR might still be running with imputation "disabled"
per the old 12.3.2 note, or held static, biasing recruitment/diameter/mortality
identically) does not hold up against the code or the trace: imputation is active,
unconditional, and re-implemented in the modular calc_hcb()/calc_ht() functions;
crown recession is active, unconditional, and literature-based (Russell, Weiskittel &
Kershaw 2014); and recruits get a modeled, not fixed, entry CR that recedes
identically to survivors starting the cycle after entry.

That said, three things make a scoped Lever 5 worth doing, distinct from "turn on
dynamics":

1. **Calibration check, not a mechanism fix.** The dhcb() coefficients are fixed
   values baked into source (no species-specific terms beyond the shade-tolerance
   covariate, no region term, no refit history visible in the changelog the way
   ddbh/dht/mortality have been iterated through Levers 1-4). Given that CR feeds
   ddbh with a strong elasticity (0.713 on log-cr) and dht linearly (0.395), if the
   crown-recession rate is even modestly mis-calibrated for young, fast-closing
   Maine developing-end stands, it would propagate into exactly the DGR/HGR
   under-prediction pattern the other four levers are chasing — this is the
   "common-cause" argument, and it survives even though the mechanism is not static.
   A worthwhile Lever 5 would refit or validate dhcb() against a modern Maine/Acadian
   HCB remeasurement dataset (the same kind of FIA-remeasured or CFI panel data used
   for Levers 3/4), specifically checking whether predicted CR recession rates in
   young, high-CCF stands match observed.
2. **Close the tree-20-style edge case.** The height-imputation gate at `dbh>2.5`
   (line 3706) leaves the smallest ingrowth-adjacent trees (2-2.5 cm) with
   perpetually undefined ht/hcb/cr, meaning they also never grow (ddbh/dht both
   presumably return non-finite or zero for these). This directly touches the
   developing end and is cheap to check/fix (either lower the threshold or give
   these trees an explicit small-tree height estimate) — worth folding into the
   guardrail battery regardless of whether the dhcb refit goes forward.
3. **Not the survival lever.** Because CR only enters mortality via the gated SBW
   modifier, a CR fix will not directly move the density-scaled mortality
   correction (Lever 2) or SDImax self-thinning ceiling; expect its effect to show
   up almost entirely through ddbh/dht magnitudes, i.e., growth rate, not survivor
   count.

**Suggested form if pursued:** not a new gate on the crown-recession *mechanism*
(already always on), but (a) a gated coefficient refit of dhcb() — `ops$use.hcb.refit`
or similar, defaulting to the current 2014 coefficients for backward compatibility —
fit against contemporary Acadian HCB remeasurements weighted toward young/high-CCF
stands, and (b) a small, ungated fix to the height-imputation dbh threshold so no
tree is left with undefined CR. Expected effect on the developing end: if the current
recession rate is too slow for young closing-canopy stands (plausible, since a stale
2014-vintage fixed-coefficient equation is exactly the kind of thing that would drift
as stand structure assumptions age), a refit would produce faster CR decline in dense
young stands, which — via the ddbh/dht cr terms — would slightly reduce growth of
suppressed small trees relative to dominants, sharpening the size differentiation
that under-prediction analyses have been flagging, without touching the mortality
lever at all. This is a plausible but unconfirmed direction; the refit itself would
need to be run before claiming a magnitude.
