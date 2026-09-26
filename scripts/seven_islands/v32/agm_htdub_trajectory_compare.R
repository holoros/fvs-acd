# AGM starting-height sensitivity along the full projection, September 23, 2026.
# Reads Carroll's native CFI_GrownDB tables for the 73 benchmark stands (StandID = PLOT*10000 + base
# year) from the v8.36 byStrata delivery (UseWeiskittelHeight on, heights dubbed at the start) and
# the v8.40 noHTdub delivery (switch off, measured heights kept where present). Native AGM
# accounting throughout (GrossCords, NetCords, BA, TPA, BiomassWgt are per acre, already expanded
# by TPA), so this is Carroll's own volume, not our Kozak recompute. Imperial units as delivered.
suppressPackageStartupMessages(library(data.table))
ps <- fread("silc_cfi_longhorizon_pairs_v16.csv"); setnames(ps, toupper(names(ps)))
ps[, estbl := (BA_CURR_FT2AC/pmax(BA_PREV_FT2AC,1)) > 2.0]
ps[, StandID := PLOT*10000L + YEAR_PREV]
cols <- c("StandID","Year","TPA","DBH","Ht","GrossCords","NetCords","P0Cords","P1Cords","P2Cords","BA","BiomassWgt","Sawlog","Pallet","Pulpwood")
rd <- function(f, tag){ d <- fread(f, select=cols); d <- d[StandID %in% ps$StandID]; d[, run := tag]; d }
a <- rd("../silc_agm_v836/v836_CFI_GrownDB_byStrata_ALL.csv", "v836_dub")
b <- rd("CFI_GrownDB_byStrata_noHTdub_ALL.csv", "v840_meas")
d <- rbind(a, b)
d <- merge(d, ps[, .(StandID, PLOT, YEAR_PREV, YEAR_CURR, estbl)], by="StandID")
d[, age := Year - YEAR_PREV]
live <- d[TPA > 0 & DBH >= 4.5]
st <- live[, .(gross_cd=sum(GrossCords), net_cd=sum(NetCords), ba_ft2=sum(BA), tpa=sum(TPA),
               ht_ft_tpaw=sum(Ht*TPA)/sum(TPA), bio=sum(BiomassWgt),
               saw=sum(Sawlog), pallet=sum(Pallet), pulp=sum(Pulpwood)), by=.(run, StandID, PLOT, estbl, age, Year)]
fwrite(st, "agm_htdub_stand_year_DATA_2026-09-23.csv")
w <- dcast(st, StandID + PLOT + estbl + age ~ run, value.var=c("gross_cd","net_cd","ba_ft2","tpa","ht_ft_tpaw","saw"))
w <- w[is.finite(gross_cd_v836_dub) & is.finite(gross_cd_v840_meas)]
s <- w[estbl==FALSE & age %in% c(0,5,10,15,20,30,40,50,60,70,80), .(
  n_stands=.N,
  net_dub=round(mean(net_cd_v836_dub),2), net_meas=round(mean(net_cd_v840_meas),2),
  net_diff_cd=round(mean(net_cd_v836_dub-net_cd_v840_meas),2),
  net_diff_pct=round(100*(mean(net_cd_v836_dub)/mean(net_cd_v840_meas)-1),1),
  max_abs_stand_diff_cd=round(max(abs(net_cd_v836_dub-net_cd_v840_meas)),2),
  share_within_1cd=round(mean(abs(net_cd_v836_dub-net_cd_v840_meas)<=1),3),
  ba_diff_pct=round(100*(mean(ba_ft2_v836_dub)/mean(ba_ft2_v840_meas)-1),1),
  tpa_diff_pct=round(100*(mean(tpa_v836_dub)/mean(tpa_v840_meas)-1),1),
  ht_dub_ft=round(mean(ht_ft_tpaw_v836_dub),1), ht_meas_ft=round(mean(ht_ft_tpaw_v840_meas),1),
  saw_diff_pct=round(100*(mean(saw_v836_dub)/mean(saw_v840_meas)-1),1)), by=age][order(age)]
print(s)
fwrite(s, "agm_htdub_trajectory_summary_DATA_2026-09-23.csv")
cat("DONE\n")
