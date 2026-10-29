import re
src = open("bench_parity.R").read()

# 1) Add CNAMES + SF_CODES + compfrac helper right before the pairs/treelist read.
anchor1 = 'prs<-fread("magp_qcnb_pairs.csv"); ti<-fread("magp_qcnb_tree_init.csv"); t2<-fread("magp_qcnb_tree_t2.csv")'
helper = r'''# --- species composition helper (basal-area fraction by species group) ---
# softwood set `sw` and AGY codes are defined above. Spruce-fir = Abies + Picea.
SF_CODES<-c("BF","RS","BS","WS","NS")
CNAMES<-c("BAc","SWF","SFF","OSWF","HWF")
compfrac<-function(sp,dbh,expf){
  live<-is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0
  sp<-sp[live];dbh<-dbh[live];expf<-expf[live]
  if(!length(dbh)) return(c(BAc=0,SWF=NA_real_,SFF=NA_real_,OSWF=NA_real_,HWF=NA_real_))
  ba<-pi*(dbh/200)^2*expf; tot<-sum(ba)
  if(!(tot>0)) return(c(BAc=0,SWF=NA_real_,SFF=NA_real_,OSWF=NA_real_,HWF=NA_real_))
  issw<-sp %in% sw; issf<-sp %in% SF_CODES
  c(BAc=tot, SWF=sum(ba[issw])/tot, SFF=sum(ba[issf])/tot, OSWF=sum(ba[issw & !issf])/tot, HWF=sum(ba[!issw])/tot)
}
'''
assert src.count(anchor1) == 1, "anchor1 count %d" % src.count(anchor1)
src = src.replace(anchor1, helper + anchor1)

# 2) After the m1/m2o/m2p metrics line, add composition computes.
anchor2 = '  m1<-metrics(mapsp(it$SP),it$DBH,it$HT,it$EXPF); m2o<-metrics(mapsp(ot$SP),ot$DBH,ot$HT,ot$EXPF); m2p<-metrics(res$sp,res$dbh,res$ht,res$expf)'
comp_line = '\n  c1<-compfrac(mapsp(it$SP),it$DBH,it$EXPF); c2o<-compfrac(mapsp(ot$SP),ot$DBH,ot$EXPF); c2p<-compfrac(res$sp,res$dbh,res$expf)'
assert src.count(anchor2) == 1, "anchor2 count %d" % src.count(anchor2)
src = src.replace(anchor2, anchor2 + comp_line)

# 3) Extend the out[[k]] data.frame with composition columns.
anchor3 = ',ING_p=ing_rate)'
comp_cols = ',ING_p=ing_rate, t(setNames(c1,paste0(CNAMES,"_t1"))),t(setNames(c2o,paste0(CNAMES,"_o"))),t(setNames(c2p,paste0(CNAMES,"_p"))))'
assert src.count(anchor3) == 1, "anchor3 count %d" % src.count(anchor3)
src = src.replace(anchor3, comp_cols)

open("bench_species_comp_frozen.R", "w").write(src)
print("PATCH OK; wrote bench_species_comp_frozen.R (%d bytes)" % len(src))
