# Score v12.6 CFI stress runs: BA/TPA/QMD bias by horizon, plus the 12.5.0
# regression check (v126legacy must equal v125base per plot).
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
man <- read.csv("silc_cfi_longhorizon_pairs_v16.csv", stringsAsFactors=FALSE)
man$estbl <- (man$BA_CURR_FT2AC/pmax(man$BA_PREV_FT2AC,1)) > 2.0
man$hbin  <- cut(man$PERIOD_YR, c(0,7,11,20), labels=c("5-7yr","8-11yr","12-15yr"))
bias <- function(p,o){ok<-is.finite(p)&is.finite(o);if(!any(ok))return(NA);round(100*(mean(p[ok])/mean(o[ok])-1),1)}
files <- list.files(".", pattern="^v126out_.*\\.csv$")
rows <- list()
for (f in files){ r<-read.csv(f,stringsAsFactors=FALSE); if(nrow(r)==0) next
  lab <- sub("^v126out_","",sub("\\.csv$","",f))
  r <- merge(r, man[,c("PLOT","estbl","hbin","TPA_CURR","QMD_CURR")], by="PLOT"); r<-r[!r$estbl,]
  add <- function(hz,s) data.frame(config=lab,horizon=hz,n=nrow(s),
            BA_bias=bias(s$BA_PRED_ft2ac,s$BA_OBS_CURR),
            TPA_bias=bias(s$TPA_PRED,s$TPA_CURR),
            QMD_bias=bias(s$QMD_PRED_in,s$QMD_CURR))
  rows[[paste(lab,"ALL")]] <- add("ALL", r)
  for(hb in c("5-7yr","8-11yr","12-15yr")) rows[[paste(lab,hb)]] <- add(hb, r[r$hbin==hb,]) }
tab<-do.call(rbind,rows); write.csv(tab,"v126_stress_scorecard.csv",row.names=FALSE)
cat("=== v12.6 CFI stress: ALL-horizon ===\n"); print(tab[tab$horizon=="ALL",],row.names=FALSE)
cat("\n=== by horizon ===\n"); print(tab[tab$horizon!="ALL",],row.names=FALSE)

## regression: v126legacy vs v125base, per-plot BA
fb<-"v126out_v125base.csv"; fl<-"v126out_v126legacy.csv"
if (file.exists(fb) && file.exists(fl)){
  a<-read.csv(fb); b<-read.csv(fl); m<-merge(a,b,by="PLOT",suffixes=c(".base",".leg"))
  dBA <-max(abs(m$BA_PRED_ft2ac.base-m$BA_PRED_ft2ac.leg),na.rm=TRUE)
  dTPA<-max(abs(m$TPA_PRED.base-m$TPA_PRED.leg),na.rm=TRUE)
  cat(sprintf("\n=== REGRESSION v126legacy vs 12.5.0base: max|dBA|=%.6f  max|dTPA|=%.6f  (n=%d)\n", dBA,dTPA,nrow(m)))
  cat(if(dBA<1e-6 && dTPA<1e-6) "REGRESSION PASS: v12.6 reproduces 12.5.0 exactly when refinements off\n" else "REGRESSION DIFF present (investigate)\n")
}
cat("DONE\n")
