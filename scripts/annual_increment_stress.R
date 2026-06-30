# Stress test: assess the model on the ANNUAL INCREMENT, not the end-state level.
# A growth model only predicts the change; the starting stand (shared by pred and obs)
# dominates the level bias. Annual increment = (end - start)/interval, in absolute units
# (m2/ha/yr for BA, m3/ha/yr for volume). Report bias and RMSE of the annual increment,
# by region and projection-length class, for 12.5.0, 12.7.0, and OSM.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
swc <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
sg <- function(sp){ sp<-toupper(sp); ifelse(sp %in% acadgy, sp, ifelse(sp %in% swc,"OS","OH")) }
# t1 metrics from input trees (same H-D as the validation)
ti <- fread("region_input_trees.csv")
ti[, spn := sg(sp)]; ti[, sw := spn %in% swc]
ti[, ht := ifelse(sw, 1.3+27*(1-exp(-0.030*dbh_cm)), 1.3+25*(1-exp(-0.028*dbh_cm)))]
ti[, vol := pi*(dbh_cm/200)^2*ht*0.45]
t1 <- ti[, .(BA_t1=sum(pi*(dbh_cm/200)^2*expf_tph*(dbh_cm>=11.43)),
             VOL_t1=sum(vol*expf_tph*(dbh_cm>=4))), by=pid]
man <- fread("region_manifest.csv")[,.(pid,region,remper)]
ob  <- fread("region_obs_fullmetric.csv")[,.(pid,BA_o=BA,VOL_o=totvol)]
p7  <- fread("region_pred_fullmetric.csv")[,.(pid,BA_7=BA,VOL_7=totvol)]
p5  <- fread("region_pred_fullmetric_125.csv")[,.(pid,BA_5=BA,VOL_5=totvol)]
os  <- fread("region_osm_pred.csv")[,.(pid,BA_os=BA_osm)]
d <- Reduce(function(a,b) merge(a,b,by="pid"), list(man,t1,ob,p7,p5,os))
d <- d[remper>0 & is.finite(BA_t1)]
ann <- function(end,start,iv) (end-start)/iv
d[, dBA_obs:=ann(BA_o,BA_t1,remper)]
for(v in c("5","7")) d[[paste0("dBA_",v)]] <- ann(d[[paste0("BA_",v)]], d$BA_t1, d$remper)
d[, dBA_os:=ann(BA_os,BA_t1,remper)]
d[, dVOL_obs:=ann(VOL_o,VOL_t1,remper)]
for(v in c("5","7")) d[[paste0("dVOL_",v)]] <- ann(d[[paste0("VOL_",v)]], d$VOL_t1, d$remper)
st <- function(p,o){ ok<-is.finite(p)&is.finite(o); p<-p[ok];o<-o[ok]
  list(bias=mean(p)-mean(o), rmse=sqrt(mean((p-o)^2)), n=length(o), obsmean=mean(o)) }
cat("=== ANNUAL BASAL-AREA INCREMENT (m2/ha/yr), pred vs obs ===\n")
cat(sprintf("observed mean annual dBA: %.3f m2/ha/yr (n=%d)\n", mean(d$dBA_obs,na.rm=TRUE), nrow(d)))
for(mdl in c("5"="12.5.0","7"="12.7.0")){}
for(nm in list(c("dBA_5","12.5.0"),c("dBA_7","12.7.0"),c("dBA_os","OSM"))){
  s<-st(d[[nm[1]]],d$dBA_obs); cat(sprintf("  %-8s bias %+.3f m2/ha/yr (%+.0f%% of obs incr)  RMSE %.3f\n",nm[2],s$bias,100*s$bias/s$obsmean,s$rmse)) }
cat("=== ANNUAL TOTAL-VOLUME INCREMENT (m3/ha/yr) ===\n")
cat(sprintf("observed mean annual dVOL: %.2f m3/ha/yr\n", mean(d$dVOL_obs,na.rm=TRUE)))
for(nm in list(c("dVOL_5","12.5.0"),c("dVOL_7","12.7.0"))){
  s<-st(d[[nm[1]]],d$dVOL_obs); cat(sprintf("  %-8s bias %+.2f m3/ha/yr (%+.0f%%)  RMSE %.2f\n",nm[2],s$bias,100*s$bias/s$obsmean,s$rmse)) }
cat("=== by projection length (12.7.0 BA increment) ===\n")
d[, ivcls:=cut(remper,c(0,5,8,12,40))]
print(d[,.(n=.N, obs_dBA=round(mean(dBA_obs),3), pred_dBA=round(mean(dBA_7),3), bias=round(mean(dBA_7-dBA_obs),3), rmse=round(sqrt(mean((dBA_7-dBA_obs)^2)),3)),by=ivcls][order(ivcls)])
cat("=== by region (12.7.0 BA increment) ===\n")
print(d[,.(n=.N, bias=round(mean(dBA_7-dBA_obs),3), rmse=round(sqrt(mean((dBA_7-dBA_obs)^2)),3)),by=region])
fwrite(d, "region_annual_increment.csv")
cat("DONE\n")
