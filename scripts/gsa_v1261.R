# Global sensitivity analysis of AcadianGY 12.6.1. Latin-hypercube sample over the
# operational parameters; project a fixed representative stand 50 yr; decompose the
# variance of BA, volume, value, and stems via standardized regression coefficients
# (SRC) and partial correlation. Base + dplyr.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("~/AcadianGY_12.6.1.r"); source("value_fns.R")
set.seed(11); N <- as.integer(Sys.getenv("NGSA","240"))
# Latin hypercube on [0,1]^k then map to ranges
lhs <- function(N,k){ M<-matrix(0,N,k); for(j in 1:k) M[,j]<-(sample(N)-runif(N))/N; M }
k<-6; U<-lhs(N,k)
P <- data.frame(
  csi      = 8  + U[,1]*(22-8),
  elev     = 100+ U[,2]*(600-100),
  onset    = 0.45+U[,3]*(0.70-0.45),
  beta     = 0.05+U[,4]*(0.30-0.05),
  ing_mult = 0.5+ U[,5]*(2.5-0.5),
  mortcal  = as.integer(U[,6] > 0.5))
topht<-function(ht,dbh,expf){o<-order(dbh,decreasing=TRUE);ht<-ht[o];e<-expf[o];cs<-cumsum(e);k<-which(cs>=100)[1];if(is.na(k))k<-length(e);weighted.mean(ht[1:k],e[1:k],na.rm=TRUE)}
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
mk<-function(){ n<-150;d0<-pmax(2,rnorm(n,4,1));data.frame(year=0,plot=1L,tree=1:n,
  sp=sample(c("BF","RS","RM","YB","SM"),n,TRUE,prob=c(.4,.2,.2,.1,.1)),dbh=d0,ht=1.3+25*(1-exp(-0.04*d0)),
  hcb=NA_real_,cr=NA_real_,expf=rep(2200/n,n),form=NA_character_,risk=NA_character_,
  ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)}
out<-vector("list",N)
for(i in 1:N){ p<-P[i,]
  o<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0)
  o$use.sdimort<-TRUE;o$sdimort.onset<-p$onset;o$sdimort.beta<-p$beta;o$sdimort.max<-1.0
  o$sdimax.site.term<-FALSE;o$use.mortcal<-(p$mortcal==1);o$mortcal.interval<-5;o$mortcal.lambda<-1;o$ingrowth.mult<-p$ing_mult
  ops<<-o; stand<<-make_stand("G",csi=p$csi,elev=p$elev,region="ME"); set.seed(100+i); cur<-mk()
  okk<-TRUE; for(yr in 1:50){ nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL); if(is.null(nx)){okk<-FALSE;break}; cur<-bf(nx) }
  if(!okk){ out[[i]]<-data.frame(p,BA=NA,VOL=NA,VALUE=NA,TPH=NA,QMD=NA); next }
  live<-cur[cur$dbh>=4&is.finite(cur$dbh),]; BAPH<-sum(pi*(live$dbh/200)^2*live$expf);TPH<-sum(live$expf)
  QMD<-sqrt((BAPH/TPH)/(pi/40000)); HT<-topht(live$ht,live$dbh,live$expf); pv<-plot_value(live$sp,live$dbh,live$expf)
  out[[i]]<-data.frame(p,BA=BAPH,VOL=BAPH*HT*0.45,VALUE=pv$value_ac,TPH=TPH,QMD=QMD) }
R<-do.call(rbind,out); write.csv(R,"gsa_v1261_results.csv",row.names=FALSE)
# standardized regression coefficients + partial correlation
preds<-c("csi","elev","onset","beta","ing_mult","mortcal"); resp<-c("BA","VOL","VALUE","TPH","QMD")
src<-list()
for(y in resp){ dd<-R[is.finite(R[[y]]),c(preds,y)]; f<-as.formula(paste0("scale(",y,") ~ ",paste0("scale(",preds,")",collapse="+")))
  m<-lm(f,dd); co<-coef(m)[-1]; names(co)<-preds; r2<-summary(m)$r.squared
  for(pp in preds) src[[length(src)+1]]<-data.frame(response=y,param=pp,SRC=round(co[[pp]],3),model_R2=round(r2,3)) }
S<-do.call(rbind,src); write.csv(S,"gsa_v1261_src.csv",row.names=FALSE)
cat("=== GSA standardized regression coefficients (|SRC| = global sensitivity) ===\n")
for(y in resp){ s<-S[S$response==y,]; s<-s[order(-abs(s$SRC)),]; cat(sprintf("\n%s (emulator R2=%.2f):\n",y,s$model_R2[1])); for(j in 1:nrow(s)) cat(sprintf("   %-9s % .3f\n",s$param[j],s$SRC[j])) }
cat("\nDONE\n")
