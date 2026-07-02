# Per-model long-horizon trajectories (ESI gradient) + explicit Bakuzis relations.
# Models: v125, v1270, v1271, v129x (=12.9.2). OSM added from documented benchmark.
# Aggregates only; no coordinates. Plaintext, data.table.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

MODELS <- list(
  v125  = "~/AcadianGY_12.5.0.r",
  v1270 = "~/AcadianGY_12.7.0.r",
  v1271 = "~/AcadianGY_12.7.1.r",
  v129x = "~/AcadianGY_12.9.2.r"
)
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult")) if(c %in% names(x)) x[[c]][is.na(x[[c]])]<-1
  if("max.dbh" %in% names(x)) x$max.dbh[is.na(x$max.dbh)]<-200; if("max.height" %in% names(x)) x$max.height[is.na(x$max.height)]<-50; x}
init <- function(seed){ set.seed(seed); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("BF","RS","BS","WS"),each=n/4),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
setops <- function(mod){
  o <- make_ops(verbose=FALSE)
  set_if <- function(nm,val){ if(nm %in% names(o)) o[[nm]]<<-val }
  o$verbose<-FALSE
  for(nm in c("use.ingrowth","use.cap.dbh","use.cap.ht")) set_if(nm,TRUE)
  if("use.hw.mod" %in% names(o)) o$use.hw.mod<-FALSE
  if(mod %in% c("v1270","v1271","v129x")){ set_if("use.sdimort",TRUE) }
  if(mod=="v1270"){ set_if("sdimort.onset",0.55); set_if("sdimort.beta",0.10) }
  if(mod %in% c("v1271","v129x")){
    set_if("sdimort.onset",0.30); set_if("sdimort.break",0.62); set_if("sdimort.beta.gentle",0.02)
    set_if("sdimort.beta.steep",0.80); set_if("sdimort.max",1.0)
    set_if("use.ingrowth.release",TRUE); set_if("ingrowth.rd.center",0.58); set_if("ingrowth.rd.k",12)
  }
  if(mod=="v129x"){
    if("sdimax.fortype.tight.mult" %in% names(o)) o$sdimax.fortype.tight.mult<-0.65
    if("sdimax.fortype.tight.groups" %in% names(o)) o$sdimax.fortype.tight.groups<-list(c("SM","BCH","QA","OH","AB"))
    if("sdimax.fortype.region" %in% names(o)) o$sdimax.fortype.region<-list("OTHER_ECO")
  }
  o
}
sdi_of <- function(d){ live<-d[d$dbh>=4 & is.finite(d$dbh),]; sum((live$dbh/25.4)^1.6*live$expf) }

alltraj <- list()
for(mod in names(MODELS)){
  source(MODELS[[mod]]); ops <<- setops(mod)
  for(esi in c(12,16,20)){
    cur <- init(101)
    stand <<- tryCatch(make_stand(stand.id=paste0(mod,"_E",esi), csi=esi, elev=200, region="ME"), error=function(e) NULL)
    if(is.null(stand)) next
    if("active_ecobucket" %in% names(ops)) ops$active_ecobucket <- "OTHER_ECO"
    for(age in 1:160){
      nx <- tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops), error=function(e) NULL)
      if(is.null(nx)||nrow(nx)==0) break
      cur <- bf(nx); live <- cur[cur$dbh>=4 & is.finite(cur$dbh),]; if(nrow(live)<1) break
      ba<-sum(pi*(live$dbh/200)^2*live$expf); tph<-sum(live$expf); qmd<-sqrt((ba/tph)/(pi/40000))
      htd<-{o<-order(-live$dbh); cw<-cumsum(live$expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; mean(live$ht[o][idx],na.rm=TRUE)}
      sdi<-sdi_of(live); vol<-0.45*ba*htd
      alltraj[[length(alltraj)+1]]<-data.table(model=mod,site=esi,age=age,HT=htd,TPH=tph,BAPH=ba,QMD=qmd,SDI=sdi,VOL=vol)
    }
  }
  cat(sprintf("traj done: %s\n", mod))
}
TR<-rbindlist(alltraj); TR<-TR[is.finite(HT)&is.finite(BAPH)]; fwrite(TR,"bakuzis_traj_allmodels.csv")

# --- Bakuzis relations per model ---
rel<-list()
for(mod in unique(TR$model)){
  s<-TR[model==mod]
  # 1 Eichhorn: V nearly unique function of HT across sites. CV of VOL at matched HT bins.
  s[,htbin:=round(HT/2)*2]
  ei<-s[,.(v=mean(VOL),n=length(unique(site))),by=htbin][n>=2]
  cvv<-s[htbin %in% ei$htbin, .(cv=sd(VOL)/mean(VOL)), by=htbin]
  eich_cv<-100*mean(cvv$cv,na.rm=TRUE)
  eich<-ifelse(eich_cv<15,"PASS","FLAG")
  # 2 Reineke self-thinning slope: mature phase where TPH declining, log(TPH)~log(QMD)
  reslope<-NA_real_
  st<-s[site==16][order(age)]; st[,dTPH:=c(NA,diff(TPH))]
  mat<-st[is.finite(dTPH) & dTPH< -1 & QMD>10]
  if(nrow(mat)>=5) reslope<-coef(lm(log(TPH)~log(QMD),data=mat))[2]
  reineke<-ifelse(is.finite(reslope) && reslope>=-1.8 && reslope<=-1.4,"PASS","FLAG")
  # 3 site ordering: higher ESI never below lower at same age (HT and VOL)
  w<-dcast(s,age~site,value.var=c("HT","VOL"))
  inv_ht<-sum((w$HT_20<w$HT_16)|(w$HT_16<w$HT_12),na.rm=TRUE)
  inv_vol<-sum((w$VOL_20<w$VOL_16)|(w$VOL_16<w$VOL_12),na.rm=TRUE)
  siteord<-ifelse(inv_ht==0 & inv_vol==0,"PASS","FLAG")
  # 4 yield-density / plateau: BA plateau in realistic 28-42 range vs runaway
  bamax<-max(st$BAPH); ba160<-st$BAPH[st$age==max(st$age)]; sdlast<-sd(tail(st$BAPH,20))
  plateau<-ifelse(bamax<=42 & sdlast<2.0,"PASS","FLAG")
  # 5 Sukachev: mean size (QMD) rises as density (TPH) falls in mature phase (negative slope)
  suk<-NA_real_; if(nrow(mat)>=5) suk<-coef(lm(QMD~TPH,data=mat))[2]
  sukachev<-ifelse(is.finite(suk) && suk<0,"PASS","FLAG")
  rel[[length(rel)+1]]<-data.table(model=mod, Eichhorn=eich, eich_cv=round(eich_cv,1),
    Reineke=reineke, reineke_slope=round(reslope,2), SiteOrdering=siteord, inv_ht=inv_ht, inv_vol=inv_vol,
    YieldDensity_plateau=plateau, BAmax=round(bamax,1), BA160=round(ba160,1), Sukachev=sukachev)
}
RB<-rbindlist(rel); fwrite(RB,"bakuzis_relations.csv")
cat("\n=== BAKUZIS RELATIONS BY MODEL (FVS) ===\n"); print(RB)
cat("DONE_BAKUZIS\n")
