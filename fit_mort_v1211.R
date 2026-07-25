# v12.11 density/structure-aware mortality correction fit.
# Builds per-stand observed vs predicted NATURAL mortality (BA + NSVB volume) across
# five sources, reusing the exact obs-decomposition machinery from obs_decomp.R /
# obs_decomp_nb.R / obs_decomp_ctrn.R, then computes observed-to-predicted ratios by
# density and management class and fits a multiplicative correction on the MORTCAL
# decrement. Aggregate summaries only are printed; per-stand table stays on node.
# No em dashes.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table)); setwd("/users/PUOM0008/crsfaaron/magplot/verify")
MS<-"multisrc"

## ---------- NSVB machinery (verbatim from obs_decomp.R) ----------
co<-fread("nsvb_emulator_coefs.csv"); sp2g<-fread("spcd_spgrpcd.csv")
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,SW=298,HW=998,OH=998,OS=298,PC=68)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD)
spcd2grp<-setNames(sp2g$SPGRPCD, as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD, function(s){ g<-spcd2grp[as.character(s)]; if(is.na(g)) 998L else as.integer(g) })
ci<-match(agy_grp, co$SPGRPCD); ci[is.na(ci)]<-match(998, co$SPGRPCD); ci[is.na(ci)]<-1
a_<-setNames(co[["VOLCFGRS_a"]][ci],agy_codes); b_<-setNames(co[["VOLCFGRS_b"]][ci],agy_codes); sm_<-setNames(co[["VOLCFGRS_sm"]][ci],agy_codes)
FT3_M3<-0.0283168
volo<-function(agy,dbh_cm,ht_m){ ht<-ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm))
  lX<-log((dbh_cm/2.54)^2*(ht/0.3048)); y<-sm_[agy]*exp(a_[agy]+b_[agy]*lX); y[!is.finite(y)]<-0; unname(y)*FT3_M3 }
bao<-function(d) pi*(d/200)^2
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}

## per-stand observed decomposition -> STAND, mo_BA, mo_V
decps<-function(a,b){
  a<-a[is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0]
  b<-b[is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0]
  m<-merge(a[,.(tag,sp1=sp,d1=dbh,h1=ht,e1=expf)], b[,.(tag,d2=dbh,h2=ht,e2=expf)],by="tag")
  dead<-a[!(tag %in% m$tag)]
  mo_BA<-m[,sum((e1-e2)*bao(d1))] + dead[,sum(bao(dbh)*expf)]
  mo_V <-m[,sum((e1-e2)*volo(sp1,d1,h1))] + dead[,sum(volo(sp,dbh,ht)*expf)]
  data.table(mo_BA=mo_BA, mo_V=mo_V)
}

OBS<-list()

## Reconciling observed decomposition from the scorer's OWN init/t2 tree lists
## (decomp_combined.R approach: matched by (STAND,TREE); reconciles to scorecard 0.00).
decps_bench<-function(src, keep){
  ti<-fread(file.path(MS,paste0("bench_",src,"_tree_init.csv")))
  t2<-fread(file.path(MS,paste0("bench_",src,"_tree_t2.csv")))
  ti<-ti[STAND %in% keep]; t2<-t2[STAND %in% keep]
  ti[,sp:=mapsp(SP)]; t2[,sp:=mapsp(SP)]
  L<-function(d,e) is.finite(d)&d>=4&is.finite(e)&e>0
  ti<-ti[L(DBH,EXPF)]; t2<-t2[L(DBH,EXPF)]
  setkey(ti,STAND); setkey(t2,STAND)
  per<-list()
  for(st in keep){
    a<-ti[.(st)]; b<-t2[.(st)]; if(nrow(a)<3||nrow(b)<3) next
    m<-merge(a[,.(TREE,sp1=sp,d1=DBH,h1=HT,e1=EXPF)], b[,.(TREE,d2=DBH,h2=HT,e2=EXPF)], by="TREE")
    dead<-a[!(TREE %in% m$TREE)]
    per[[st]]<-data.table(STAND=st,
      mo_BA=m[,sum((e1-e2)*bao(d1))]+dead[,sum(bao(DBH)*EXPF)],
      mo_V =m[,sum((e1-e2)*volo(sp1,d1,h1))]+dead[,sum(volo(sp,DBH,HT)*EXPF)])
  }
  rbindlist(per)
}

## ===== BAXTER =====
scb<-fread("score_baxter_results.csv")
OBS[["baxter"]]<-decps_bench("baxter", scb$STAND)

## ===== SILC_L =====
scs<-fread("score_silc_l_results.csv")
OBS[["silc_l"]]<-decps_bench("silc_l", scs$STAND)

## ===== ME_FIA_L (FIA PREV_TRE_CN lineage) =====
FIA<-"/users/PUOM0008/crsfaaron/fia_data"; ACRES_PER_HA<-2.4710538147; FT_M<-0.3048
pl<-fread(file.path(FIA,"ME_PLOT.csv"), select=c("CN","PREV_PLT_CN","MEASYEAR"))
pl[,CN:=as.character(CN)][,PREV_PLT_CN:=as.character(PREV_PLT_CN)]
pl[,prev:=PREV_PLT_CN][prev %in% c("","NA")|is.na(prev), prev:=NA_character_]
parent<-pl$prev; parent[!(parent %in% pl$CN)]<-NA_character_; names(parent)<-pl$CN
root<-pl$CN
for(i in 1:50){ p<-parent[root]; mv<-!is.na(p); if(!any(mv))break; root[mv]<-p[mv] }
pl[,root:=root]; setorder(pl,root,MEASYEAR,CN)
chains<-pl[,.(first_cn=CN[1], last_cn=CN[.N]), by=root]
mep<-fread(file.path(MS,"bench_mefia_long_pairs.csv"))
scm<-fread("score_me_fia_l_results.csv"); mep<-mep[STAND %in% scm$STAND]
mep[,first_cn:=sub("^ME_L_","",STAND)]
mep<-merge(mep, chains[,.(first_cn,last_cn)], by="first_cn", all.x=TRUE)
tr<-fread(file.path(FIA,"ME_TREE.csv"),
  select=c("CN","PREV_TRE_CN","PLT_CN","SPCD","DIA","ACTUALHT","TPA_UNADJ","STATUSCD"))
tr[,CN:=as.character(CN)][,PREV_TRE_CN:=as.character(PREV_TRE_CN)][,PLT_CN:=as.character(PLT_CN)]
tr<-tr[STATUSCD==1 & is.finite(DIA) & DIA>0]
tr[,tpa:=fifelse(is.finite(TPA_UNADJ)&TPA_UNADJ>0,TPA_UNADJ, fifelse(DIA<5,74.965,6.018))]
tparent<-tr$PREV_TRE_CN; names(tparent)<-tr$CN
tparent[!(tparent %in% tr$CN)]<-NA_character_
troot<-tr$CN
for(i in 1:50){ p<-tparent[troot]; mv<-!is.na(p); if(!any(mv))break; troot[mv]<-p[mv] }
tr[,troot:=troot]
SPCD_to_AGY<-c("12"="BF","97"="RS","95"="BS","94"="WS","91"="NS","129"="WP","125"="RP","105"="JP",
 "261"="EH","241"="WC","71"="TA","316"="RM","318"="SM","371"="YB","375"="PB","379"="GB",
 "746"="QA","743"="BT","741"="BP","742"="EC","531"="AB","541"="WA","543"="BA","544"="GA",
 "833"="RO","762"="BC","761"="PR","315"="ST","701"="HH","391"="HH","935"="SB","370"="RB","68"="PC")
fia_map<-function(spcd){ a<-SPCD_to_AGY[as.character(spcd)]; a<-ifelse(!is.na(a),a,ifelse(spcd>=300,"OH","OS")); mapsp(a) }
setkey(tr,PLT_CN)
ps<-list()
for(i in seq_len(nrow(mep))){
  st<-mep$STAND[i]; fcn<-mep$first_cn[i]; lcn<-mep$last_cn[i]
  if(is.na(lcn)) next
  a<-tr[.(fcn)]; b<-tr[.(lcn)]; a<-a[!is.na(CN)]; b<-b[!is.na(CN)]
  if(nrow(a)<3||nrow(b)<3) next
  A<-data.table(tag=a$troot, sp=fia_map(a$SPCD), dbh=a$DIA*2.54,
                ht=ifelse(is.finite(a$ACTUALHT)&a$ACTUALHT>0,a$ACTUALHT*FT_M,NA_real_), expf=a$tpa*ACRES_PER_HA)
  B<-data.table(tag=b$troot, sp=fia_map(b$SPCD), dbh=b$DIA*2.54,
                ht=ifelse(is.finite(b$ACTUALHT)&b$ACTUALHT>0,b$ACTUALHT*FT_M,NA_real_), expf=b$tpa*ACRES_PER_HA)
  A<-A[!duplicated(tag)]; B<-B[!duplicated(tag)]
  d<-decps(A,B); d[,STAND:=st]; ps[[st]]<-d
}
OBS[["me_fia_l"]]<-rbindlist(ps)

## ===== NB MagPlot =====
prs<-fread("magp_qcnb_pairs.csv")
scn0<-fread("cb_v12101_results.csv"); nb_scored<-scn0[PROV=="NB", unique(STAND)]
prs<-prs[PROV=="NB" & STAND %in% nb_scored]
ti<-fread("magp_qcnb_tree_init.csv"); t2<-fread("magp_qcnb_tree_t2.csv")
ti[,sp:=NULL]; t2[,sp:=NULL] # avoid clash if present
setkey(ti,STAND); setkey(t2,STAND)
ps<-list()
for(i in seq_len(nrow(prs))){
  st<-prs$STAND[i]; a<-ti[.(st)]; b<-t2[.(st)]
  if(nrow(a)<3||nrow(b)<3) next
  A<-data.table(tag=paste(a$PLOT,a$TREE,sep="."), sp=mapsp(a$SP), dbh=as.numeric(a$DBH),
                ht=ifelse(is.finite(a$HT)&a$HT>0,a$HT,NA_real_), expf=as.numeric(a$EXPF))
  B<-data.table(tag=paste(b$PLOT,b$TREE,sep="."), sp=mapsp(b$SP), dbh=as.numeric(b$DBH),
                ht=ifelse(is.finite(b$HT)&b$HT>0,b$HT,NA_real_), expf=as.numeric(b$EXPF))
  A<-A[!duplicated(tag)]; B<-B[!duplicated(tag)]
  d<-decps(A,B); d[,STAND:=st]; ps[[st]]<-d
}
OBS[["nb"]]<-rbindlist(ps)

## ===== CTRN (already per-stand) =====
ctp<-fread("obs_decomp_ctrn_perstand.csv")
OBS[["ctrn"]]<-ctp[,.(STAND, mo_BA, mo_V)]

## ---------- assemble observed ----------
for(nm in names(OBS)) OBS[[nm]][,SRC:=nm]
obs<-rbindlist(OBS, use.names=TRUE)
setnames(obs, c("mo_BA","mo_V"), c("mo_BA_o","mo_V_o"))

## ---------- predicted per-stand + stand state ----------
predfiles<-c(baxter="decomp_baxter_results.csv", silc_l="decomp_silc_l_results.csv",
             me_fia_l="decomp_me_fia_l_results.csv", ctrn="decomp_ctrn_results.csv",
             nb="decomp_qcnb_results.csv")
PR<-list()
for(nm in names(predfiles)){
  p<-fread(predfiles[nm])
  if(nm=="nb") p<-p[PROV=="NB"]
  PR[[nm]]<-p[,.(STAND, SRC=nm, PROV, iv,
     BA_t1, SDI_t1, QMD_t1, TOPHT_t1, TOTVOL_t1,
     mo_BA_p=BA_mo_p, mo_V_p=V_mo_p)]
}
pred<-rbindlist(PR, use.names=TRUE)

## ---------- merge ----------
d<-merge(pred, obs[,.(STAND,SRC,mo_BA_o,mo_V_o)], by=c("STAND","SRC"))
d<-d[is.finite(iv)&iv>0]
# annualized natural mortality (per yr), volume and BA
d[, `:=`(moV_o_ann=mo_V_o/iv, moV_p_ann=mo_V_p/iv, moBA_o_ann=mo_BA_o/iv, moBA_p_ann=mo_BA_p/iv)]
# management / stand-origin indicator: CTRN thinned residual, NB managed, SILC managed CFI;
# Baxter reserve (unmanaged), ME_FIA natural FIA (unmanaged).
d[, managed:=as.integer(SRC %in% c("ctrn","nb","silc_l"))]
d[, natural:=as.integer(SRC %in% c("baxter","me_fia_l"))]
# relative density using a spruce-fir Acadian Reineke maximum SDImax (metric)
SDIMAX<-1200
d[, RD:=SDI_t1/SDIMAX]

cat("=========== PER-SOURCE OBSERVED vs PREDICTED NATURAL MORTALITY ===========\n")
agg<-d[,.(n=.N,
  SDI=round(mean(SDI_t1),0), QMD=round(mean(QMD_t1),1), RD=round(mean(RD),3),
  iv=round(mean(iv),1),
  moV_o=round(mean(mo_V_o),2), moV_p=round(mean(mo_V_p),2),
  ratio_oP=round(mean(mo_V_o)/mean(mo_V_p),3),
  moBA_o=round(mean(mo_BA_o),3), moBA_p=round(mean(mo_BA_p),3),
  ratioBA=round(mean(mo_BA_o)/mean(mo_BA_p),3)), by=SRC]
print(agg)

cat("\n=========== BY DENSITY CLASS (RD = SDI/1200) x MANAGEMENT ===========\n")
d[, RDclass:=cut(RD, c(0,0.35,0.55,0.75,2), labels=c("<0.35","0.35-0.55","0.55-0.75",">0.75"))]
byc<-d[,.(n=.N, SDI=round(mean(SDI_t1),0), QMD=round(mean(QMD_t1),1),
   moV_o=round(mean(mo_V_o),2), moV_p=round(mean(mo_V_p),2),
   ratio=round(mean(mo_V_o)/mean(mo_V_p),3)),
   by=.(managed, RDclass)][order(managed,RDclass)]
print(byc)

cat("\n=========== POOLED RATIO managed vs natural ===========\n")
print(d[,.(n=.N, moV_o=round(mean(mo_V_o),2), moV_p=round(mean(mo_V_p),2),
   ratio=round(mean(mo_V_o)/mean(mo_V_p),3)), by=managed])

## ---------- FIT correction on the MORTCAL decrement ----------
## Target: multiplier f applied to predicted mortality so pred*f ~ obs.
## Structure-aware form gated on management/origin so natural self-thinning is untouched:
##   f = 1                                    if natural (unmanaged) stand
##   f = fmin + (1-fmin)*exp(-k*(RD-RD0)+)     if managed, decreasing with excess rel. density
## Fit fmin, k, RD0 on managed stands (ctrn, nb, silc_l) by matching per-stand ratio.
man<-d[managed==1 & mo_V_p>0]
man[, r:=mo_V_o/mo_V_p]        # per-stand obs/pred (natural mortality)
man[, r:=pmin(r, 3)]           # cap wild small-denominator ratios for stability
# weight by predicted mortality magnitude (m3) so high-removal stands drive the fit
man[, w:=mo_V_p]
# nonlinear LS on f(RD)=fmin+(1-fmin)*exp(-k*pmax(RD-RD0,0))
sse<-function(par){ fmin<-plogis(par[1]); k<-exp(par[2]); RD0<-par[3]
  f<-fmin+(1-fmin)*exp(-k*pmax(man$RD-RD0,0))
  sum(man$w*(man$r-f)^2) }
opt<-optim(c(qlogis(0.3), log(3), 0.30), sse, method="Nelder-Mead")
fmin<-plogis(opt$par[1]); k<-exp(opt$par[2]); RD0<-opt$par[3]
cat(sprintf("\n=========== FITTED MANAGED-STAND CORRECTION f(RD) ===========\n"))
cat(sprintf("f(RD) = fmin + (1-fmin)*exp(-k*max(RD-RD0,0)),  RD=SDI/%d\n", SDIMAX))
cat(sprintf("  fmin = %.4f\n  k    = %.4f\n  RD0  = %.4f\n  (natural/unmanaged stands: f = 1)\n", fmin,k,RD0))

## apply and report post-correction per source
d[, f:=ifelse(managed==1, fmin+(1-fmin)*exp(-k*pmax(RD-RD0,0)), 1)]
d[, moV_p_corr:=mo_V_p*f]
cat("\n=========== POST-CORRECTION per source (volume m3 ha-1, interval totals) ===========\n")
post<-d[,.(n=.N, RD=round(mean(RD),3),
  moV_o=round(mean(mo_V_o),2), moV_p_old=round(mean(mo_V_p),2),
  f_mean=round(mean(f),3), moV_p_new=round(mean(moV_p_corr),2),
  ratio_old=round(mean(mo_V_p)/mean(mo_V_o),2),
  ratio_new=round(mean(moV_p_corr)/mean(mo_V_o),2)), by=SRC]
print(post)

## also a simpler two-parameter alternative: flat managed multiplier by density tercile
cat("\n=========== SIMPLE ALT: managed multiplier by RD band (obs/pred) ===========\n")
alt<-man[,.(n=.N, RD=round(mean(RD),3), mult=round(mean(mo_V_o)/mean(mo_V_p),3)),
  by=.(RDband=cut(RD,c(0,0.4,0.6,2),labels=c("lo","mid","hi")))][order(RDband)]
print(alt)

fwrite(d[,.(STAND,SRC,PROV,iv,SDI_t1,QMD_t1,RD,managed,mo_V_o,mo_V_p,f,moV_p_corr)],
       "fit_mort_v1211_perstand.csv")
cat("\nDONE_FIT\n")
