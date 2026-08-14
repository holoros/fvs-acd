# plot_ba_incr reparameterization: mechanism proven exactly, refit scoped, not built

Written 13 August 2026, pass 13. Aaron's decision: reparameterize to separate site from density
rather than a sign-constrained refit or dropping the site term. Model of record
`~/AcadianGY_13.1.r` unmodified; scoping only, no coefficients changed. No em dashes.

## The collinearity, proven algebraically from the actual coefficients

`plot_ba_incr` (model lines 1218-1244) computes the density-dependent term as

    rt = q0 + q1*log(rd+1e-6) + q2*log(csi) + q3*log(ba.perc.hw*100+1e-6) + q4*log(csi*rd+1e-6)

with q1 = -0.15018, q2 = -0.13355, q4 = 0.11753. Because `log(csi*rd) = log(csi) + log(rd)`
whenever csi*rd is not near the 1e-6 floor (true for essentially every real stand), the fifth term
is not a genuine interaction, it is a near-exact linear recombination of the first two log terms
already in the equation. The model is fit with four coefficients (q1, q2, and the log(rd) and
log(csi) pieces hidden inside q4) doing the work of two identifiable slopes. The net, identifiable
coefficient on log(rd) is q1 + q4 = -0.15018 + 0.11753 = **-0.03265**, and on log(csi) is
q2 + q4 = -0.13355 + 0.11753 = **-0.01602**. These are exactly the two numbers pass 9 Track C
reported as the "net" site and density gradients, and reproducing them from the raw coefficients
this way (rather than from a numerical sweep) confirms the mechanism is exactly what Track C
described, not approximately: q4 is not adding information, it is silently cannibalizing q1 and
q2, collapsing both toward zero and inverting whichever sign the fitting procedure happened to
land on for the recombined pair.

## What "reparameterize to separate site from density" means concretely

The fifth term needs to stop being algebraically redundant with the first two. Two candidate forms
that would restore identifiability, neither fit here, both requiring a refit on the original
calibration data:

1. **Drop the interaction term entirely.** `rt = q0 + q1*log(rd+1e-6) + q2*log(csi) +
   q3*log(ba.perc.hw*100+1e-6)`, three free slopes, refit from scratch. Simplest, removes the rank
   deficiency by construction, loses whatever genuine site-by-density interaction (if any) the
   original equation was reaching for.
2. **Replace it with a non-redundant interaction.** Something like `q4*log(rd+1e-6)*log(csi)` (the
   product of the two logs, not the log of the product) or `q4*rd*csi` (raw product, unlogged) is
   not expressible as a linear combination of `log(rd)` and `log(csi)` alone, so it stays
   identifiable alongside them. This preserves an interaction term if the underlying biology calls
   for one (site quality modulating how relative density suppresses basal-area growth), at the
   cost of a real refit rather than a coefficient rename.

Deciding between these two is itself a modeling call about whether `plot_ba_incr` should carry an
interaction at all, not something to default without fitting both and comparing.

## Why this pass stops at scoping

Refitting either candidate form needs the original calibration dataset (stand-level basal-area
increment against relative density, climate site index, hardwood basal-area percent, and plot
basal area), an actual `nls` or `gnls` fit with convergence diagnostics, a residual and
biological-realism check against the Bakuzis battery the way every other structural change in
this project has been checked, and per the standing modeling philosophy an uncertainty interval
on every recovered coefficient, not point estimates alone. None of that is available or
appropriate to fabricate in a scoping pass. Building it without the data and diagnostics would be
exactly the kind of unverified result the firewall discipline exists to prevent.

## Recommended next step

A dedicated pass, sized similarly to Track F or Track G: locate the calibration dataset
`plot_ba_incr` was originally fit on (likely referenced in the same source material the "Weiskittel
revised parameter estimates" comment points to), fit both candidate forms in R on Cardinal, compare
by AIC/BIC and residual pattern against relative density and site index, run the winner through
the Bakuzis site-ordering relation (since this function directly governs how basal-area growth
responds to site quality, a canonical Bakuzis check), and only then propose new coefficients with
confidence intervals for review. Not attempted here.
