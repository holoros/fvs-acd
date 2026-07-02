suppressMessages({library(data.table); library(bit64)})
d <- as.data.table(readRDS("~/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds"))
d <- d[STATECD %in% c(23L,33L,50L)]
d <- d[is.finite(DBH1)&DBH1>=2.54&is.finite(DBH2)&TREESTATUS1==1&TREESTATUS2==1&
       is.finite(YEARS)&YEARS>=1&YEARS<=20&is.finite(HT1)&HT1>1.5&is.finite(HT2)&HT2>1.5&
       is.finite(TPH1)&TPH1>0]
d[, dg_a := (DBH2-DBH1)/YEARS]; d <- d[dg_a > -0.5 & dg_a < 5.0]
d[, PLT_CHR := as.character(PLT_CN_cond1)]
setorder(d, PLT_CHR, -DBH1)
d[, csum_tph := cumsum(TPH1), by=PLT_CHR]
d[, is_dom := csum_tph <= pmax(100, min(TPH1)), by=PLT_CHR]
d[, any_dom := any(is_dom), by=PLT_CHR]
d[any_dom==FALSE, is_dom := (csum_tph==min(csum_tph)), by=PLT_CHR]
agg <- d[, .(
  STATECD=STATECD[1],
  topht1=weighted.mean(HT1[is_dom], TPH1[is_dom]),
  topht2=weighted.mean(HT2[is_dom], TPH1[is_dom]),
  stdage=STDAGE[1], years=YEARS[1], dg_a_plot=mean(dg_a),
  dbh1_qmd=sqrt(mean(DBH1^2)), cr1=mean(CR1[is.finite(CR1)]),
  bal_sw1=mean(BAL_SW1), bal_hw1=mean(BAL_HW1),
  ba1=BA1[1], sdi1=SDI1[1], rd_sdimax=rd_sdimax[1],
  bgi=bgi[1], climate_si=climate_si[1], cspi=cspi[1], sicond=SICOND[1],
  fortyp=FORTYPCD_cond1[1], epaL2=as.character(EPA_L2_CODE)[1], epaL3=as.character(EPA_L3_CODE)[1],
  LAT=LAT[1], LON=LON[1], ntree=.N
), by=PLT_CHR]
agg[, hgi_o := (topht2-topht1)/years]
agg[, rid := .I]
cat("plots:", nrow(agg), "\n")
saveRDS(agg, "~/bakeoff_v13/ne_plot_table.rds")
fwrite(unique(agg[is.finite(LAT)&is.finite(LON), .(rid, LON, LAT)]), "~/bakeoff_v13/ne_plot_coords.csv")
cat("DONE_ASSEMBLE\n")
