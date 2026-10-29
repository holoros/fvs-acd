# Pass 34: the site-ordering inversion is an artifact of the test, not a defect in the model

**Date.** 26 August 2026. **Branch.** `hardwood-formrisk-wip`. **Predecessors.** Pass 32
(`9057c0c`), which reported standing-volume site-ordering inversions at nearly every source and
attributed them to ingrowth-release gating. Pass 33 (`decea81`, addendum `2b7b183`), which built
the ingrowth fix, found a residual inversion surviving complete removal of recruitment, and named a
site-independent maximum stand density index as the next thing to repair.

## What pass 34 set out to do, and what it found instead

The task was to make SDImax rise with site index and see whether that closed the residual inversion.
Two measurements killed that plan before any refit, and a third showed the inversion itself was
never real.

The engine already carries a gated site term for SDImax. `calc_sdi_max` in `AcadianGY_13.1.r`
implements the Weiskittel and Kuehne (2019) surface, whose site component is 222.7836 divided by
csi when `ops$sdimax.site.term` is TRUE and a constant 15.6 otherwise, 15.6 being the value at csi
14.28. The production configuration sets it FALSE. That term decreases in csi, so switching it on
makes the self-thinning ceiling fall with productivity, the opposite of what pass 33 proposed, and
its full swing over csi 8 to 20 is 16.7 SDI units against a base of 650 to 1300. Running it on at
all six sources moves terminal volume by 0.14 to 2.48 percent. A refit in the other direction would
be arguing against Aaron's own published equation on the strength of an effect too small to matter.

The measurement that settles the question is different. The Bakuzis site-ordering statistic used in
passes 32 and 33 compares four **different real stands** selected at site-index quantiles. Those
stands differ in far more than site. At CTRN the four differ in initial basal area with a rank
correlation against site index of negative 0.80, spanning 41.9 down to 24.8 m² ha⁻¹, and in
composition from 78 to 100 percent softwood, one stratum being a single-species stand of 111 trees
against another's 326. A high-site stand that starts with 40 percent less basal area will finish
with less volume, and that has nothing to do with the model's site response.

## The controlled experiment

Pass 34 holds one real stand fixed per source and varies csi alone over 10, 12, 14, 16, 18 and 20,
with the same tree list, elevation, region, managed flag, ecobucket and height multiplier on every
rung. Three arms were run, the production configuration, the pass 33 maturity gate, and the
production configuration with the SDImax site term switched on, at six sources, 18 tasks, all
completed.

The result is unambiguous. Rank correlation between site index and standing volume at age 100:

| Source | production | pass 33 maturity gate | SDImax site term on |
|---|---|---|---|
| CTRN | +1.00 | +1.00 | +1.00 |
| NB | +1.00 | +1.00 | +1.00 |
| QC | +1.00 | +1.00 | +1.00 |
| NS | +1.00 | +1.00 | +1.00 |
| memat | +0.31 | +1.00 | +0.09 |
| MEFIA_L | +0.94 | +1.00 | +1.00 |

Under the production configuration the model orders standing volume perfectly by site at four of six
sources and near perfectly at a fifth, MEFIA_L, whose peak-volume ordering is a clean +1.00 and
whose terminal figure is depressed only by where each rung sits in its density cycle at exactly age
100. The magnitudes are sensible throughout. At CTRN terminal volume runs 275 to 320 m³ ha⁻¹ across
the ladder, at QC 66 to 104, at NS 230 to 259, monotone in every case, with top height rising
monotonically with site at every source.

The one source that is not clean under production is memat, at +0.31, where terminal volume plateaus
near 440 m³ ha⁻¹ from csi 12 upward and wanders by a few percent rather than continuing to climb.
Under the pass 33 maturity gate memat becomes +1.00, as does every other source.

## What this means for passes 32 and 33

Pass 32's headline, standing-volume site-ordering inverted at 97 to 100 of 100 simulated ages at
nearly every source, is measured on a design that cannot separate site response from stand-to-stand
differences. The finding is not wrong as a description of what those four trajectories did. It is
wrong as evidence about the model, and the causal readings built on top of it in passes 32 and 33
both need narrowing. Pass 32 attributed the inversion to ingrowth-release gating. Pass 33 showed
that attribution was incomplete and named SDImax as the residual driver. Pass 34 shows there is no
residual to explain, because under a design that varies site alone the model's site ordering is
already correct.

The mid-rotation basal-area and volume crash that passes 32 and 33 documented is untouched by this
finding. That crash is visible within a single trajectory and needs no cross-stand comparison, so it
remains a real long-horizon property of v13.2 driven by `ops$use.sdimort`, and the pass 33 maturity
gate's repair of the failure to recover from it stands as measured.

## Consequences for the maturity gate

Pass 33 shipped `ops$use.ingrowth.matgate` off, recommending it for long-horizon use but declining
to adopt it, on a flag ledger that was a wash. Two things have changed since. The addendum
(`2b7b183`) completed the short-interval check at all five sources with observed-basis gates passing
everywhere, worst regression 0.078 RMSE points against a 0.5 point gate, three of five improving.
And pass 34 shows the gate delivers a perfect site response at all six sources against four of six
for the production configuration, repairing memat outright. The case for adoption is now
considerably stronger than the evidence pass 33 had, and the decision belongs to Aaron rather than
to this pass.

## Limitations

NB's anchor stand carries six initial trees and reaches age 1 at 46 trees ha⁻¹ and 0.1 m² ha⁻¹, so
its trajectory is built almost entirely from ingrowth rather than from an existing stand. Its +1.00
is a legitimate site-response result for a regenerating stand but is not representative, and the
anchor rule should require a minimum initial tree count. Gate G1, which required age-1 conditions to
be near identical across rungs, failed at NB for this reason and was mis-specified in any case, since
age 1 already contains a full year of csi-dependent growth, mortality and recruitment. One stand per
source is a small sample for a claim about a source, and the ladder tests site response at a single
starting structure rather than across the structural range. PEF, Baxter, NS_LONG, SILC_L and medev
were not run.

## Verdict

`h1_v132_mortgate` remains the production default. The SDImax refinement scoped by pass 33 is
withdrawn rather than deferred, on the grounds that the existing site term points the wrong way, its
magnitude is under 2.5 percent, and the violation it was meant to repair does not survive a
controlled test. The Bakuzis site-ordering statistic should not be quoted as evidence about model
behavior unless the compared trajectories differ only in site, and the fixed-stand csi ladder built
here is the instrument for that. Passes 32 and 33 carry amendment notes rather than retractions,
since their within-trajectory findings are unaffected.
