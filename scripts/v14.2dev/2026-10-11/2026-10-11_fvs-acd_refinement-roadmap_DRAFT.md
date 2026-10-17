# FVS-ACD refinement roadmap after PREREG45

Aaron Weiskittel, 11 October 2026. Draft. Grounded in the open items of the 14.2 release notes revision d and the PREREG45
and PREREG45b results; every number below is quoted from those records, not re-derived.

## Where the model stands

14.1 remains the release. The 14.2 series changed no engine file and produced a scoring convention (C1 volume, scorer r2),
one NS candidate held by a Bakuzis grid (v141LTfi), and a chain of QC results that locate the dominant QC error in the
height increment form rather than its scalar. Under the shipped QC_AFAC 0.111, QC top height stalls (17.29 m at 100 years
from 14.49 m, falls in 36 of 36 stands); at the field tag scalar 1.242 it reaches 1.5 times ESI; the relative height
multiplier of PREREG45 fixes the held out increment (pooled ratio 1.003) but still overshoots the measured frontier
(median 1.309 against 1.175). The QC height form is therefore the highest value target, followed by the QC stems deficit
and the NS mortality step.

## Next steps, in order

**1. Unblock and close the books.** Restore firebreather, publish Zenodo 1.9.0 under the standing go, put its DOI in
CITATION.cff and README.md, and merge PR #9. Nothing below starts until the server is back.

**2. Run PREREG46 (QC height form with a zero, 14.3).** Registered 11 October (md5 eb4b753d); the fit, the driver edit,
the build, the chain, G0x and the trace gate are written and need a server review before launch. Two outcomes matter.
If an arm clears, the next study is a confirmation on data not used in fold A or fold B (later QC remeasurements, or the
qc_fl frame held back from fitting), then the Bakuzis QC grid from measured stand lists against an absolute rule (step 4).
If neither clears and the failure is again above r = 1, the binding constraint is data, since fold A holds 58 tags at r of
1 or more and 4 at 1.25 or more; the remedy is then a pooled QC and ME field tag fit of the relative height term, with
the extrapolation domain stated, rather than a third functional form.

**3. QC stems deficit.** Every QC anchor arm runs about 24 points low on stems (PREREG28), and PREREG19 placed the QC
volume excess in diameters and stems rather than height. Once a height form is settled, a diagnostic study should split
the deficit into survivor mortality and ingrowth on field tag survivors, the design that located the NS survivor loss
(PREREG27). Height feeds crown ratio and competition, so this waits on step 2.

**4. Fix the Bakuzis reference for QC.** Non inferiority to 14.1 is a weak gate when the 14.1 QC reference is itself not
credible (top height falls in every stand; benchmark ratio 0.093). A short preregistration should replace it, for QC only,
with absolute relation gates (site ordering, Reineke against the measured frontier, monotone top height, the 1.175 bound),
fixed before any arm is run. This is a decision for Aaron and should precede any QC candidate entering a release.

**5. NS: clear or retire v141LTfi.** It fails PREREG26 by one basal area inversion in one pure balsam fir cell, attributed
to threshold matching at IMULT 1.5. Two linked items decide its fate: NS survivor mortality over multi year steps
(predicted annual survival 0.987 to 0.991 against observed 0.992 to 1.000 beyond 20 years, PREREG27), and the 100 year
size of the height form top height loss, tested only to 35 years (PREREG30). A survival step correction refit on
NS_OP stands, followed by a rerun of the NS grid from measured stand lists (the PREREG44 design), is the efficient path.

**6. NB height.** Parked until a tree paired NB height sample exists (PREREG45b: fold B ratio 0.556, fold to fold factor
1.7 in observed increment). The candidate source is tag linkage in the provincial PSP records; until then NB stays at
0.579.

**7. Harness and records.** Repair the 7.0 m ESI offset between ns_c and ns_long_c (PREREG29); finish the MNAP State t1
height imputation and the unread mefia_l_c control (PREREG21); recover or formally retire the PREREG23 and PREREG24
texts and the PREREG24 RESULT.

## Release path

14.2 ships as 14.1 plus the scoring convention, scorer r2 and the documented named failures, with QC 0.111 and NB 0.579
and the low QC height bias stated in the notes. 14.3 is the QC height form (step 2, confirmed and passing step 4), with
v141LTfi as an NS regional setting only if step 5 clears it.
