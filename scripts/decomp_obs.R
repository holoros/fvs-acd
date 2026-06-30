# Decompose the OBSERVED annual basal-area dynamics into gross growth, mortality, and
# ingrowth on the full DBHout matched pairs, by region. Answers whether the model's net
# over-prediction is a growth excess (stand-level dBA cap failing) or a mortality deficit
# (too few stems removed). Tree-level: each DBHout row is a tree with dbh1@t1, dbh2@t2,
# expf1/expf2. Survivor: dbh1>0 & dbh2>0. Mortality: dbh1>0 & (expf2==0 | dbh2 NA).
# Ingrowth: (dbh1 NA|0) & dbh2>0.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/fs/scratch/PUOM0008/crsfaaron/maine_cfi")
d <- fread("DBHout.csv", nThread=4, select=c("Source","Stand","Plot","year1","year2","dbh1","dbh2","expf1","expf2"))
d[, region := fifelse(Source=="Nova Scotia PSP","NS", fifelse(Source=="NB PSP","NB",
              fifelse(Source %in% c("PEF","PEF Study 58","FIA_99_05"),"ME",
              fifelse(grepl("^PQ",Source),"QC","X"))))]
d <- d[region!="X"]
d[, iv := year2-year1]; d <- d[iv>=1 & iv<=20]
ba <- function(dcm) pi*(dcm/200)^2
d[, e1 := fifelse(is.finite(expf1),expf1,0)]; d[, e2 := fifelse(is.finite(expf2),expf2,0)]
d[, surv := is.finite(dbh1)&dbh1>0&is.finite(dbh2)&dbh2>0&e2>0]
d[, dead := is.finite(dbh1)&dbh1>0&(e2==0 | !is.finite(dbh2))]
d[, ingr := (!is.finite(dbh1)|dbh1<=0)&is.finite(dbh2)&dbh2>0&e2>0]
# per tree annual BA contributions
d[, g_growth := fifelse(surv, (ba(dbh2)-ba(dbh1))*e1/iv, 0)]
d[, g_mort   := fifelse(dead, ba(dbh1)*e1/iv, 0)]
d[, g_ingr   := fifelse(ingr, ba(dbh2)*e2/iv, 0)]
pl <- d[, .(growth=sum(g_growth), mort=sum(g_mort), ingrow=sum(g_ingr),
            BA_t1=sum(ba(dbh1)*e1*(is.finite(dbh1)&dbh1>=11.43), na.rm=TRUE)),
        by=.(region,Source,Stand,Plot,year1)]
pl[, net := growth - mort + ingrow]
cat("=== Observed annual BA dynamics (m2/ha/yr), per-plot means ===\n")
cat(sprintf("%-6s %6s  %7s %7s %7s %7s %8s\n","region","nplot","growth","mort","ingrow","NET","mort/grow"))
for(rg in c("ALL","ME","NB","NS","QC")){ s<-if(rg=="ALL") pl else pl[region==rg]
  cat(sprintf("%-6s %6d  %+7.3f %7.3f %+7.3f %+7.3f %7.2f\n", rg, nrow(s),
    mean(s$growth,na.rm=TRUE), mean(s$mort,na.rm=TRUE), mean(s$ingrow,na.rm=TRUE),
    mean(s$net,na.rm=TRUE), mean(s$mort,na.rm=TRUE)/mean(s$growth,na.rm=TRUE))) }
cat("\nInterpretation: observed gross growth is offset by mortality; NET is what the model must match.\n")
cat("Mortality fraction = mort/growth. If the model's NET is too high, compare its growth (should ~match\n")
cat("observed gross growth, capped by stand dBA) vs its mortality (likely below observed mort).\n")
DONE <- TRUE; cat("DONE\n")
