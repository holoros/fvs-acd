# Lever 4 fitted coefficients: hardwood form/risk height modifier

*21 July 2026. Replaces the placeholder form coefficient in dht_hw_mod with a field fit. Fitted from the
Ryan Smith NHRI form/risk dataset (local EquivalenceData.csv), the authoritative source that carries observed
form and risk classes together with total height, so no FIA damage proxy is needed. Castle 2017 Master Stem
Form and Risk data on Google Drive was inspected but holds only County/Plot/SubPlot/Tree + Form(1-8) + Risk(1-4)
with no species, DBH, or height, so it needs a join to reach heights; the Smith set is already integrated and
was used directly. No em dashes.*

## Data and fit

EquivalenceData.csv: 635 trees across Smith, Rangeley, AshlandEast, AshlandWest; columns SPP, DBH (cm), HT
(total height, m), Form (NHRI 1-8), Risk (NHRI 1-4), plus FormObserved (IF/AF/PF/UF) and RiskObserved (LR/HR).
Usable hardwoods with height: YB (n=266), SM (n=251), RM (n=117); RO n=1 (dropped), no PB or QA in the height
set. Engine collapse applied exactly: form A = NHRI {1,3,4,7} else B; risk LR = {1,2} else HR.

Model log(HT) ~ log(DBH) + form_B + risk_HR, per species:

| species | n | form_B (poor form) | risk_HR (high risk) |
|---|---|---|---|
| YB | 266 | +0.4% (p=0.89, NS) | -10.9% (p=0.0005) |
| SM | 251 | -5.8% (p=0.057) | -10.8% (p=0.0013) |
| RM | 117 | -0.6% (p=0.86, NS) | -2.3% (p=0.59, NS) |
| pooled | 634 | -1.9% (p=0.31, NS) | -9.7% (p=1.4e-6) |

The dominant hardwood height lever is RISK, not form. High-risk trees are about 10 to 11 percent shorter in YB
and SM (both strongly significant), weaker in RM. Poor form has a weak total-height effect (SM -5.8 percent
marginal, others near zero), which is expected: form drives sawlog and merchantable height and defect, not total
height, and that partition is already carried downstream by hw_sawfrac_smith.R. So Lever 4 corrects total-height
volume mainly through the risk term, and keeps a small form term.

## Level to increment translation

The engine modifier multiplies the annual height INCREMENT. A tree carrying a constant fractional
height-growth penalty ends a fixed fraction shorter, so a level log-height deficit d maps to a sustained
increment log-multiplier of approximately d (first order). The Smith fit is a cross-sectional level deficit at
observed DBH, taken as the sustained increment coefficient. Caveat: if risk develops late in life the level
deficit understates the true increment effect; the FIA GRM increment fit (scoping note) gave slightly larger
magnitudes for SM and RM, so these coefficients are a conservative field-anchored choice.

## Final coefficients (in AcadianGY_12.11.r)

base.risk.coeff = -0.1380 (PB reference). gamma.form = -0.020 (pooled Smith form_B, conservative).

dht.hw.mod.spp (spp.coeff.risk = species total risk log-deficit minus base):

| species | spp.coeff.risk | source of total risk effect |
|---|---|---|
| RO | -0.1520 | FIA GRM (not in Smith height set) |
| SM |  0.0230 | Smith field (total -0.115) |
| YB |  0.0220 | Smith field (total -0.116) |
| RM |  0.1150 | Smith field (total -0.023) |
| QA |  0.0210 | FIA GRM |
| PB |  0.0000 | reference |

dht.hw.mod = exp(base.risk.coeff*hr + spp.coeff.risk*hr + gamma.form*form.b), clamped [0.5, 1.2], = 1 exactly at
form A / low risk, so gate-off and reference trees are unchanged (byte-identical when ops$use.dht.hw.mod is off).

## SM sanity check against Aaron's framing

Worst-quality SM (high risk and poor form): multiplier exp(-0.115 + -0.058) = 0.841, a 16 percent height deficit,
about 3.7 m at a 23 m mature SM. That matches Aaron's estimate that roughly 4 m of SM height deficit explains
about 18 percent of the hardwood volume gap, since volume scales about linearly with height at a fixed taper.

## Double-count guard

Enabling Lever 4 lowers simulated height at a given DBH for poor-form and high-risk hardwoods, shifting the
htdbh ratio that hw_sawfrac_smith.R consumes. Revalidate the Smith sawlog-fraction self-test (Table A.10) with
Lever 4 on before shipping it enabled.

## Caveats

RO, QA, PB risk coefficients rest on the FIA GRM damage proxy, not Smith field NHRI, because they are absent
from the Smith height set. The form coefficient is a single pooled value; only SM showed a marginal
species-specific form effect. A larger integrated Castle join (Master form/risk to HRF_INVENTORY heights) could
extend the species coverage and separate a species-specific form term, and is the natural refinement.
