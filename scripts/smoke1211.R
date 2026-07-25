.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table)); setwd("/users/PUOM0008/crsfaaron/magplot/verify")

BASE <- "~/_scripts/AcadianGY_12.10.2.r"
NEW  <- "~/_scripts/AcadianGY_12.11.r"

bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
base_ops <- function(){ o <- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
  o$use.sdimort<-TRUE;o$sdimort.onset<-0.30;o$sdimort.break<-0.62;o$sdimort.beta.gentle<-0.02;o$sdimort.beta.steep<-0.80;o$sdimort.max<-1.0;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
  o$use.ingrowth.release<-TRUE;o$ingrowth.rd.center<-0.58;o$ingrowth.rd.k<-12
  o$sdimax.region.mult<-list(c(NB=1.0,QC=1.0,ME=1.0,NS=1.0));o$sdimax.fortype.tight.mult<-0.65
  o$sdimax.fortype.tight.groups<-list(c("SM","BCH","QA","OH","AB"));o$sdimax.fortype.region<-list("OTHER_ECO");o$active_ecobucket<-"OTHER_ECO"; o }

# young mixed stand (recruitment + general)
init_young <- function(){ set.seed(101); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("RS","WS","BF"),length.out=n),dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,
    expf=rep(3000/n,n),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
# mature high-QMD stand (large trees; diameter rein + stand constraint + high-density mortality)
init_mature <- function(){ set.seed(202); n<-60
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("RS","BF","RM","YB"),length.out=n),dbh=runif(n,22,46),ht=NA_real_,hcb=NA_real_,cr=NA_real_,
    expf=rep(900/n,n),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }

project <- function(cur, ops, years){ for(yr in seq_len(years)){ nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops); if(is.null(nx)||nrow(nx)==0) stop("empty"); cur<-bf(nx) }; cur }
snap <- function(x) x[order(x$tree), c("tree","dbh","ht","expf")]

## ================= 1. BYTE-IDENTICAL GATE-OFF (20-yr projection, both stands) =================
YRS <- 20
source(BASE); cat("BASE VersionTag:", AcadianVersionTag, "\n")
ops<<-base_ops(); stand<<-make_stand(stand.id="y",csi=18,elev=200,region="ME")
by_base <- snap(project(init_young(), ops, YRS))
ops<<-base_ops(); stand<<-make_stand(stand.id="m",csi=16,elev=250,region="ME")
bm_base <- snap(project(init_mature(), ops, YRS))

source(NEW); cat("NEW  VersionTag:", AcadianVersionTag, "\n")
ops<<-base_ops(); stand<<-make_stand(stand.id="y",csi=18,elev=200,region="ME")   # all levers OFF (defaults)
by_new <- snap(project(init_young(), ops, YRS))
ops<<-base_ops(); stand<<-make_stand(stand.id="m",csi=16,elev=250,region="ME")
bm_new <- snap(project(init_mature(), ops, YRS))

cmp <- function(a,b){ m<-merge(a,b,by="tree",suffixes=c(".b",".n"))
  c(dbh=max(abs(m$dbh.b-m$dbh.n),na.rm=TRUE), ht=max(abs(m$ht.b-m$ht.n),na.rm=TRUE), expf=max(abs(m$expf.b-m$expf.n),na.rm=TRUE),
    nrow=abs(nrow(a)-nrow(b))) }
gy <- cmp(by_base,by_new); gm <- cmp(bm_base,bm_new)
cat(sprintf("GATE-OFF young  20yr: max|ddbh|=%.3e max|dht|=%.3e max|dexpf|=%.3e nrowdiff=%d\n", gy["dbh"],gy["ht"],gy["expf"],gy["nrow"]))
cat(sprintf("GATE-OFF mature 20yr: max|ddbh|=%.3e max|dht|=%.3e max|dexpf|=%.3e nrowdiff=%d\n", gm["dbh"],gm["ht"],gm["expf"],gm["nrow"]))
gate_ok <- max(gy["dbh"],gy["ht"],gy["expf"],gy["nrow"],gm["dbh"],gm["ht"],gm["expf"],gm["nrow"]) == 0
cat(sprintf("GATE_OFF_BYTE_IDENTICAL: %s\n", gate_ok))

## ================= 2. LEVER TOGGLES (v12.11, single stand, directional) =================
# helper: total BA and summed survivor BA increment proxy
BAf <- function(x){ x<-x[is.finite(x$dbh)&x$dbh>=4&is.finite(x$expf)&x$expf>0,]; sum(pi*(x$dbh/200)^2*x$expf) }
stems5 <- function(x, n_init){ sum(x$expf[x$tree>n_init & is.finite(x$dbh) & x$dbh>=5], na.rm=TRUE) }

# --- Lever 3a diameter rein: mature stand, 1 step, large-tree ddbh should drop ---
ops<<-base_ops(); stand<<-make_stand(stand.id="m",csi=16,elev=250,region="ME")
cur<-init_mature(); r_off<-bf(AcadianGYOneStand(tree=cur,stand=stand,ops=ops))
o<-base_ops(); o$use.ddbh.rein<-TRUE; ops<<-o; r_rein<-bf(AcadianGYOneStand(tree=cur,stand=stand,ops=ops))
mo<-merge(data.frame(tree=cur$tree,d0=cur$dbh), merge(r_off[,c("tree","dbh")], r_rein[,c("tree","dbh")], by="tree", suffixes=c(".off",".rein")), by="tree")
mo$inc.off<-mo$dbh.off-mo$d0; mo$inc.rein<-mo$dbh.rein-mo$d0
big<-mo[mo$d0>=28,]; small<-mo[mo$d0<28,]
cat(sprintf("LEVER3a rein: BIG(dbh>=28) mean ddbh off %.4f -> rein %.4f (should drop); SMALL off %.4f -> rein %.4f (near-equal)\n",
   mean(big$inc.off),mean(big$inc.rein),mean(small$inc.off),mean(small$inc.rein)))

# --- Lever 3b stand constraint: lower thresholds, mature stand ddbh should change ---
o<-base_ops(); o$use.ddbh.standcon<-TRUE; o$ddbh.standcon.lo<-0.30; o$ddbh.standcon.hi<-0.40; ops<<-o
r_sc<-bf(AcadianGYOneStand(tree=cur,stand=stand,ops=ops))
msc<-merge(r_off[,c("tree","dbh")], r_sc[,c("tree","dbh")], by="tree", suffixes=c(".off",".sc"))
cat(sprintf("LEVER3b standcon: BA off %.3f -> lowthr %.3f (constraint binds => <= off); max|ddbh shift|=%.4f\n",
   BAf(r_off), BAf(r_sc), max(abs(msc$dbh.off-msc$dbh.sc))))

# --- Lever 2 mortality mgmt-gating: high-density managed stand, survival (expf) should rise ---
init_dense <- function(){ set.seed(303); n<-80
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("RS","BF"),length.out=n),dbh=runif(n,14,26),ht=NA_real_,hcb=NA_real_,cr=NA_real_,
    expf=rep(2600/n,n),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
ops<<-base_ops(); stand<<-make_stand(stand.id="d",csi=16,elev=250,region="ME")
cd<-init_dense(); d_off<-bf(AcadianGYOneStand(tree=cd,stand=stand,ops=ops))
o<-base_ops(); o$mort.dens.scale<-TRUE; o$stand.managed<-TRUE; ops<<-o; d_man<-bf(AcadianGYOneStand(tree=cd,stand=stand,ops=ops))
o<-base_ops(); o$mort.dens.scale<-TRUE; o$stand.managed<-FALSE; ops<<-o; d_nat<-bf(AcadianGYOneStand(tree=cd,stand=stand,ops=ops))
cat(sprintf("LEVER2 mort-gate: TPH off %.1f | managed-ON %.1f (should be >= off; less removal) | natural-ON %.1f (== off)\n",
   sum(d_off$expf), sum(d_man$expf), sum(d_nat$expf)))

# --- Lever 1 recruitment taper vs flat mult: young stand, ingrowth stems ---
ops<<-base_ops(); stand<<-make_stand(stand.id="y",csi=18,elev=200,region="ME")
cy<-init_young(); n_init<-max(cy$tree)
y_off<-bf(AcadianGYOneStand(tree=cy,stand=stand,ops=ops))
o<-base_ops(); o$ingrowth.mult<-2.5; ops<<-o; y_flat<-bf(AcadianGYOneStand(tree=cy,stand=stand,ops=ops))
o<-base_ops(); o$use.ingrowth.rdtaper<-TRUE; ops<<-o; y_tap<-bf(AcadianGYOneStand(tree=cy,stand=stand,ops=ops))
cat(sprintf("LEVER1 recruit: ingrowth stems>=5 off %.1f | flat2.5 %.1f (>off) | rdtaper %.1f (>off, open stand ~2.8x)\n",
   stems5(y_off,n_init), stems5(y_flat,n_init), stems5(y_tap,n_init)))

cat("SMOKE_1211_DONE\n")
