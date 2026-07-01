# Seeded long-horizon trajectories for v12.9 (ecoregion x forest-type gated self-thinning),
# fixing the reproducibility gap flagged earlier (traj scripts had no set.seed()). Projects
# both a softwood-dominated stand (BF/RS, gets NO fortype correction regardless of ecobucket)
# and a hardwood-dominated stand (SM/BCH, gets the FTMULT correction only if OTHER_ECO) to
# confirm the plateau still holds at the realistic Acadian maximum (28-32 m2/ha) under v12.9.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
source("~/AcadianGY_12.9.0.r")
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE; ops$sdimort.onset<-0.30; ops$sdimort.break<-0.62; ops$sdimort.beta.gentle<-0.02; ops$sdimort.beta.steep<-0.80; ops$sdimort.max<-1.0; ops$sdimax.site.term<-FALSE; ops$use.mortcal<-FALSE
ops$use.ingrowth.release<-TRUE; ops$ingrowth.rd.center<-0.58; ops$ingrowth.rd.k<-12
ops$sdimax.region.mult <- list(c(NB=1.0, QC=1.0, ME=1.0, NS=1.0))
ops$sdimax.fortype.tight.mult <- 0.65
ops$sdimax.fortype.tight.groups <- list(c("SM","BCH","QA","OH","AB"))
ops$sdimax.fortype.region <- list("OTHER_ECO")

init <- function(seed, sp_mix){
  set.seed(seed)
  n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(sp_mix,each=n/length(sp_mix)),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
}
sdi_of <- function(d){ live<-d[d$dbh>=4&is.finite(d$dbh),]; sum((live$dbh/25.4)^1.6*live$expf) }

scenarios <- list(
  list(label="SW_softwood_baseline", sp=c("BF","RS","BS","WS"), ecobucket="OTHER_ECO", seed=101),
  list(label="HW_hardwood_OTHER_ECO_corrected", sp=c("SM","BCH"), ecobucket="OTHER_ECO", seed=102),
  list(label="HW_hardwood_ACADIAN_CORE_untouched", sp=c("SM","BCH"), ecobucket="ACADIAN_CORE", seed=102)
)

out <- list()
for(scn in scenarios){
  for(esi in c(12,16,20)){
    cur <- init(scn$seed, scn$sp)
    stand <<- make_stand(stand.id=paste0(scn$label,"_E",esi), csi=esi, elev=200, region="ME")
    ops$active_ecobucket <- scn$ecobucket
    for(age in 1:160){
      nx <- tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops), error=function(e) NULL)
      if(is.null(nx)||nrow(nx)==0) break
      cur <- bf(nx)
      live <- cur[cur$dbh>=4&is.finite(cur$dbh),]
      if(nrow(live)<1) break
      ba<-sum(pi*(live$dbh/200)^2*live$expf); tph<-sum(live$expf); qmd<-sqrt((ba/tph)/(pi/40000))
      htd<-{o<-order(-live$dbh); cw<-cumsum(live$expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; mean(live$ht[o][idx],na.rm=TRUE)}
      sdi<-sdi_of(live)
      out[[length(out)+1]] <- data.frame(scenario=scn$label, ecobucket=scn$ecobucket, site=esi, age=age,
        HT=round(htd,2), TPH=round(tph,0), BAPH=round(ba,2), QMD=round(qmd,2), SDI=round(sdi,0))
    }
  }
}
tr <- rbindlist(out)
fwrite(tr, "traj_v129_seeded.csv")
cat("=== v12.9 seeded long-horizon asymptotes (max BA over age, by scenario x site) ===\n")
for(g in unique(tr$scenario)){
  s <- tr[scenario==g]
  for(e in unique(s$site)){
    ss <- s[site==e]
    cat(sprintf("%-38s ESI%2d: BA@120 %.1f  BA@160 %.1f  TPH@160 %.0f  plateauSD(last20) %.2f\n",
      g, e, ss$BAPH[ss$age==120][1], ss$BAPH[ss$age==max(ss$age)][1], ss$TPH[ss$age==max(ss$age)][1],
      sd(tail(ss$BAPH,20))))
  }
}
cat("DONE_TRAJ_V129_SEEDED\n")
