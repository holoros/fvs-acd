# FVS-ACD v13.1: three decisions Aaron owes

28 July 2026. Short brief. Three decisions are blocking or shaping the v13.1 deliverables. Each is a multiple
choice with the recommended option first, the evidence for it, and the evidence against. Each option is short
enough to answer in one line. No em dashes.

---

## Decision 1. Ratify the ingrowth hook basis: absolute replacement or multiplicative modifier

The hierarchical recruitment hook originally applied the posterior as an absolute replacement of predicted
ingrowth while the mortality hook applied multiplicatively. The hook has been changed to multiplicative, with the
modifier equal to unity at training-mean covariates, and gate-off byte-identity was re-verified at 0.000e+00
after the change. This is a structural choice about what the posterior means at runtime and it needs ratifying
before it hardens into published methods.

- **Option A (recommended). Ratify multiplicative. Keep the change as shipped, document it in the methods of
  both the report and the GTR, and cite the post-change gate-off job as the contract of record.**
- Option B. Revert to absolute replacement and treat the fourteenfold PEF blow-up as a scaling bug to be fixed
  inside the absolute form.
- Option C. Ratify multiplicative now, but carry absolute replacement as a gated alternative for a later
  sensitivity.

For Option A. It mirrors the mortality hook, so both fitted components enter the model by the same construction
and a user reasoning about one can reason about the other. It is gate-safe, with byte-identity preserved at
0.000e+00 after the change, so the contract to shipped 12.10.1 is untouched. It fails safe, because a modifier
that equals unity at training-mean covariates returns the frozen baseline when a posterior directory is missing,
whereas an absolute replacement silently substitutes a fitted surface. It cut the anomalous PEF ingrowth preview
from 186 to 66 stems ha⁻¹ yr⁻¹, which is not a fix on its own but is evidence that the absolute form was
amplifying the underlying problem. It preserves the calibrated FVS-ACD ingrowth prediction as the anchor and lets
the posterior express a deviation from it, which is the same philosophy the mortality hazard uses on the Reineke
ramp.

Against Option A. A multiplicative modifier anchored on the existing ingrowth prediction inherits any bias in
that prediction, so if the v12.11 ingrowth surface is wrong in shape the posterior can only rescale it, not
correct it. Absolute replacement would in principle let the hierarchical fit fully own recruitment, which is the
cleaner statistical position if the fit is trustworthy. The counterargument is that the recruitment fit has
failed verification twice and is not yet trustworthy enough to own the component outright.

Against Option B. It reopens a settled gate-off verification, and the residual PEF overprediction has since been
traced to a response-scale defect in the fit rather than to the hook, so reverting the hook would not address the
cause. Option C costs a second code path and a second gate-off verification for a sensitivity nobody has asked
for, and can be revisited later at low cost if the v7 recruitment fit turns out to be strong.

---

## Decision 2. Confirm the v13.1 candidate direction

The hierarchical mortality scores essentially neutral on volume, moving Maine FIA whole-plot bias from -16.53% to
-16.49%, and its density signal is gentle and thresholdless, falling about 11% across relative density 0.10 to
0.80 against the v12.11 hand gate's roughly 86% near-step at 0.38. The recruitment component is the remaining
candidate lever on the developing-plot deficit and is on its third generation.

- **Option A (recommended). Confirm the direction: corrected hierarchical recruitment plus gentle hierarchical
  mortality, dropping the v12.11 hand gate, and frame v13.1 as a defensibility gain on mortality plus a
  bias-lever attempt on recruitment.**
- Option B. Keep the v12.11 hand gate alongside the fitted hazard, on the grounds that the hand gate is what
  actually moved managed-source bias in v12.11.
- Option C. Ship v13.1 as a mortality-only release now and defer recruitment to v13.2, given that recruitment has
  failed verification twice.

For Option A. The fitted hazard has the same sign as the hand gate, so the hand gate is not contradicted, only
found to be far steeper than the data support, which retires it on evidence rather than on preference. Dropping a
hand-tuned management gate removes the least defensible object in the v12.11 lever block, which is the part
hardest to justify to Hennigar or to a GTR reader. The neutrality result is itself a clean finding that narrows
the search, since population-level mortality is now ruled out as the lever and recruitment is the only remaining
candidate in the current structure. Both components enter multiplicatively and gated, so the direction is
reversible at no cost to the byte-identity contract.

Against Option A. It rests on a recruitment component that has not yet passed verification, so the direction
could be confirmed and then fail to deliver. It also depends on the whole-plot mortality posterior, which is on
its second attempt after a multimodal timeout, so the coarse-grain half of the mortality story is still unproven.
The honest framing is that Option A confirms a direction, not a result, and the report must say so.

Against Option B. Carrying both a fitted hazard and a hand gate on the same removal fraction double-counts the
density effect and makes the fitted posterior uninterpretable, and the hand gate is also the suspected cause of
the v12.11 Quebec volume over-correction. Against Option C. A mortality-only v13.1 would ship a release whose
headline is that nothing measurably improved, which is a weak story for the August meeting, and it would split
the Nova Scotia disclosure across two releases.

---

## Decision 3. Land the Castle red oak term, and whether to add a managed hazard term

Two related integration questions. The Castle field data show that high-risk red oak are not shorter at a given
diameter but marginally taller, by 3.9% (p = 0.017, n = 618), reversing the shipped in-model value of -0.1520 and
both prior candidate values. Separately, 924 managed Nova Scotia stands are now in the whole-plot mortality
fitset while the current mortality formula has no management fixed effect.

### 3a. The Castle hardwood term

- **Option A (recommended). Land the Castle term using the re-anchor table, gated, with the merchantable-only
  caveat stated in the report, the GTR and Table 2.**
- Option B. Land the Castle term using the primary table, which differences Castle species deficits against the
  existing FIA-derived paper birch base of -0.1380.
- Option C. Hold the Castle term gated off and keep the shipped -0.1520 red oak value until a below-25 cm height
  sample is available.

For Option A. It is field data on 618 complete red oak records against an in-model value fitted on a sample of
one, and the finding was reproduced independently in R at +0.0384, p = 0.018. The re-anchor table is internally
consistent, since every coefficient comes from one source on one specification, whereas the primary table mixes a
field-fitted deficit with a proxy-fitted base. The implied modifier of about 1.039 applies no penalty and does
not bind the clamp, so the term is a small, well-behaved correction rather than a large intervention. It is
gated, so nothing changes until it is switched on and the gate-off contract is unaffected.

Against Option A. The re-anchor table gives no risk penalty at all to hardwoods absent from the Castle
compilation, including paper birch, which loses the -0.1380 reference it currently carries. Castle is
merchantable-only at 25.4 to 82.0 cm, so the term is unanchored in exactly the size class where a height-risk
relationship is most plausible, and red maple's coefficient is not distinguishable from zero (p = 0.209). Option B
preserves the paper birch reference but at the cost of a cross-source construction that cannot be defended
cleanly in a GTR. Option C keeps a value fitted on a single tree, which is the weakest position of the three.

### 3b. An explicit managed hazard term

- **Option A (recommended). Do not add a management fixed effect in v13.1. Record the 924 managed Nova Scotia
  stands as a v13.2 opportunity and check the existing forest-type and region groups for managed structure
  first.**
- Option B. Add a management fixed effect to the whole-plot mortality formula and refit.
- Option C. Add management as a random slope on the region grouping rather than as a fixed effect.

For Option A. The whole-plot fit is on its second attempt after a multimodal timeout, and adding a fixed effect
now means discarding a running 48 h job and restarting the identification problem from scratch. The managed
sample is also modest and unevenly distributed, at 924 managed stands of 3,922 Nova Scotia stands and 812 managed
of the 3,426 in-fit after holdout, against a fitset of 212,768 rows, so a population-level management term would
be estimated almost entirely from Nova Scotia and would confound management with province. The v12.11 experience
also argues for caution, since the management-gated hand lever is the object v13.1 is retiring and reintroducing
management as a fixed effect risks recreating it in fitted form without first establishing that the data ask for
it.

Against Option A. Management is a real driver of mortality in these stands and leaving it out means the fitted
hazard averages over managed and unmanaged regimes, which is part of why the effect may be so gentle. Option B is
the direct test of that and would settle the question, at the cost of the current job and a further fit cycle.
Option C is statistically the better form if a management effect is wanted, since it lets the effect vary by
region rather than forcing one national value, but it adds a group-level variance parameter to a model that has
already shown boundary-funnel and multimodality problems, so it is the highest-risk option on convergence
grounds.
