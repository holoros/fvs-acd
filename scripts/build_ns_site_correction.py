#!/usr/bin/env python3
"""
Second-pass NS benchmark, Task 1: site-index definition reconciliation.

Finding (see 20260722_ns_benchmark_philosophy_pass.md for full writeup):

  - NS SITE_INDEX (operational PSPs, psp_si.sas7bdat via "NS Site and LC.dbf") is dominant
    height (m) read off a generalized softwood/hardwood curve family at BREAST-HEIGHT AGE 50
    (handbook/PAGE1-2.JPG, "Land Capability for Nova Scotia Softwoods/Hardwoods -- Based on
    Breast Height Age"). AVGTOPHTM (research PSPs, psp_qplot.sas7bdat) is the companion
    plot-level top-height proxy used where SITE_INDEX is absent (build_ns_bench.py).
    BOTH are therefore on the same basis pass 1 assumed for esi8: dominant height in meters,
    ~breast-height-age-50 reference. There is NO species/base-age/unit bug in the pass-1 mapping.

  - What IS mismatched is that esi8, as actually realized for the QC/NB benchmark, is a known-
    flawed raster product, not a clean ground-truth site index. Per
    active-projects/bgi-cspi-conus/v5/maine_cfi/Acadian_ESI_v8_stress_test.md (Cardinal job
    12127451, n=40,596 tree-level measured-SI records): the rendered ESI v8 surface has Pearson
    r=0.146 against measured SI, RMSE 7.9 m, and a POSITIVE BIAS of 7.0 m -- i.e. esi8 as
    extracted for the QC/NB benchmark plots (mean 18.57 m, n=549, range 15.98-20.38, confirmed
    by re-reading magp_qcnb_site_esi8.csv this session) runs ~7 m higher on average than those
    same plots' true measured site index would show, and the surface is far more spatially
    compressed than reality (measured SI spans 0.8-72.9 m; the raster spans ~14-24 m).

  - NS SITE_INDEX/AVGTOPHTM (mean 13.46 m, n=2005, range 4.4-28.2, pulled directly from field
    remeasurement, not a raster) is much closer to what TRUE unbiased site index looks like for
    this region -- consistent with mean(esi8_QCNB) - 7.0 bias = 11.57, near NS's 13.46 median.
    So NS is not an outlier on badly-mismatched footing; QC/NB's esi8 is inflated relative to
    ground truth, and NS's -41% absolute under-prediction is at least partly a byproduct of the
    model's QC/NB-side height-growth anchor terms (NB_AFAC=0.579, QC_AFAC=0.111 in
    bench_parity_split_ms_v1211.R) having been implicitly tuned against that inflated esi8 input,
    while NS (PROV != NB/QC) receives no equivalent anchor correction (dht.mult=1) and is fed the
    real, uninflated NS SITE_INDEX directly into csi-driven growth terms (ddbh ~ log(csi),
    plot_ba_incr ~ log(csi), calc_sdi_max ~ 222.7836/csi, pred_ht ~ csi^c1 -- see AcadianGY_12.11.r
    lines ~867, 1071, 3479, 501) that are all monotonically increasing in csi.

Correction produced here (defensible, documented, quantifiable -- NOT a blind rescale): put NS
onto the SAME (flawed) esi8 basis that the model's QC/NB anchor levers were calibrated against,
by adding the documented +7.0 m raster bias to the raw, ground-truth NS SITE_INDEX/AVGTOPHTM
value. This is the "esi8-matched" scenario. The raw (uncorrected) NS value is kept and scored in
parallel as the "ground-truth" scenario, since it is arguably the more scientifically honest
number; reporting both, and the resulting change in bias, is how this task quantifies how much of
the -41% absolute gap is site-index-basis artifact versus a real regional productivity signal.

Uncertainty: the +7.0 m figure is itself a point estimate from a validation with RMSE 7.9 m and
Pearson r=0.146 (i.e. the raster barely tracks measured SI at all) -- so treat the corrected
column as a coarse basis-matching adjustment, not a precise per-plot recalibration. This is
stated plainly in the memo; no attempt is made to manufacture false per-plot precision.

Input:  figures/_data/ns_bench_build/bench_ns_site_esi.csv          (pass-1 raw NS site input)
Output: figures/_data/ns_bench_build/bench_ns_site_esi_corrected.csv (esi8-matched NS site input)
        same schema (SITE, esi8), uploaded to Cardinal ~/magplot/verify/multisrc/ alongside the
        raw file so both can be swapped into bench_parity_split_ms_v1211.R via SITE_FILE= with no
        harness change.
"""
import pandas as pd
import os

BASE = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/repos/fvs-acd/figures/_data/ns_bench_build"
ESI8_RASTER_BIAS_M = 7.0  # Acadian_ESI_v8_stress_test.md, Cardinal job 12127451, n=40,596

raw = pd.read_csv(os.path.join(BASE, "bench_ns_site_esi.csv"))
corrected = raw.copy()
corrected["esi8"] = (corrected["esi8"] + ESI8_RASTER_BIAS_M).round(2)
corrected.to_csv(os.path.join(BASE, "bench_ns_site_esi_corrected.csv"), index=False)

print("raw NS site input:      n=%d mean=%.2f sd=%.2f range=(%.1f,%.1f)" % (
    len(raw), raw.esi8.mean(), raw.esi8.std(), raw.esi8.min(), raw.esi8.max()))
print("corrected (+%.1f m):     n=%d mean=%.2f sd=%.2f range=(%.1f,%.1f)" % (
    ESI8_RASTER_BIAS_M, len(corrected), corrected.esi8.mean(), corrected.esi8.std(),
    corrected.esi8.min(), corrected.esi8.max()))
print("QC/NB esi8 for reference: n=549 mean=18.57 sd~ range=(15.98,20.38) (magp_qcnb_site_esi8.csv)")
