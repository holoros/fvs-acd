# Build forest-type-group and ecobucket per recent Maine FIA plot (t1, matching the
# MagPlot methodology: BA-weighted dominant sp.attr$sp.grp.ingrowth; ecobucket from the
# CEC Level III ecoregion join already run for these plots).
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(dplyr)})
setwd("/users/PUOM0008/crsfaaron")
source("~/AcadianGY_12.7.1.r")  # sp.attr

SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM","241"="WC","261"="EH","95"="BS","91"="WS","105"="JP","129"="WP","318"="SM","531"="BC","746"="QA","833"="RO","541"="WA","934"="GB","126"="PR","136"="RP","743"="BP","356"="HH","409"="EC","491"="PC")
mapsp <- function(spcd){ s<-SPCD_to_AGY[as.character(spcd)]; s[is.na(s)]<-"99"; s }

FIA <- "/users/PUOM0008/crsfaaron/fia_data"
pl <- fread(file.path(FIA,"ME_PLOT.csv"), select=c("CN","PREV_PLT_CN","MEASYEAR","REMPER"))
pl[, CN:=as.character(CN)][, PREV_PLT_CN:=as.character(PREV_PLT_CN)]
pr <- pl[!is.na(PREV_PLT_CN) & PREV_PLT_CN!="" & PREV_PLT_CN!="NA" & is.finite(REMPER) & REMPER>=4 & REMPER<=15 & MEASYEAR>=2010]
tr <- fread(file.path(FIA,"ME_TREE.csv"), select=c("PLT_CN","SPCD","DIA","STATUSCD"))
tr[, PLT_CN:=as.character(PLT_CN)]; tr <- tr[STATUSCD==1 & is.finite(DIA) & DIA>0]
tr[, ba := pi*(DIA*2.54/200)^2][, sp := mapsp(SPCD)]
tr <- merge(tr, as.data.table(sp.attr)[,.(sp=species,sp.grp.ingrowth)], by="sp", all.x=TRUE)
dom <- tr[!is.na(sp.grp.ingrowth), .(ba=sum(ba)), by=.(PLT_CN, sp.grp.ingrowth)][order(PLT_CN,-ba)][, .SD[1], by=PLT_CN]
setnames(dom, c("PLT_CN","fortype","ba"))
cat("t1 plots with fortype:", nrow(dom), "\n")

eco <- fread("silc_cfi/me_plot_ecol3.csv", colClasses=c(CN="character"))
setnames(eco, "CN", "PLT_CN")
out <- merge(pr[,.(CN,PREV_PLT_CN)], dom[,.(PLT_CN,fortype)], by.x="PREV_PLT_CN", by.y="PLT_CN", all.x=TRUE)
out <- merge(out, eco[,.(PLT_CN,eco,eco_name)], by.x="PREV_PLT_CN", by.y="PLT_CN", all.x=TRUE)
out[, grp := ifelse(fortype %in% c("SM","BCH","QA","OH","AB"), "HW", "SW_OTHER")]
out[, ecobucket := ifelse(eco_name %in% c("Acadian Plains and Hills","Maritime Lowlands"), "ACADIAN_CORE", "OTHER_ECO")]
cat("n pairs:", nrow(out), " with fortype:", sum(!is.na(out$fortype)), " with eco:", sum(!is.na(out$eco)&out$eco!=""), "\n")
cat("grp x ecobucket table:\n"); print(table(out$grp, out$ecobucket, useNA="ifany"))
fwrite(out, "silc_cfi/fia_recent_ecobucket_fortype.csv")
cat("DONE_FIA_FORTYPE_ECOBUCKET\n")
