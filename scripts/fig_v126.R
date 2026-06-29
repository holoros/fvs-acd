# v12.6 summary figure: the two findings. (A) CFI operational bias by config:
# SDImort inert, MORTCAL trades BA for stems. (B) Bakuzis Reineke slope: SDImort
# steepens self-thinning and retains more stems than MORTCAL. Base R.
RES <- "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/results/seven_islands"
FIG <- "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/figures"
sc <- read.csv(file.path(RES,"v126_stress_scorecard.csv"))
bz <- read.csv(file.path(RES,"bz_v126_reineke.csv"))
g <- function(cfg,col) sc[sc$config==cfg & sc$horizon=="ALL", col][1]

png(file.path(FIG,"acadgy_v126_summary.png"), width=2200, height=950, res=200)
par(mfrow=c(1,2), mar=c(5,4.4,3.2,1.2), mgp=c(2.5,0.8,0), font.main=2)
off<-"#4878A8"; on<-"#C0504D"; gray<-"#888888"

## A: CFI BA and TPA bias by config
cfgs<-c("v125base","v126def","v126mc"); labs<-c("12.5.0\nbase","v12.6\ndefault","v12.6\n+MORTCAL")
BA<-sapply(cfgs,g,col="BA_bias"); TPA<-sapply(cfgs,g,col="TPA_bias")
m<-rbind(BA,TPA)
bp<-barplot(m,beside=TRUE,col=c(off,on),border=NA,ylim=c(-22,18),ylab="bias (%)",
   names.arg=labs,main="A. Seven Islands CFI: operational bias",cex.names=0.85)
abline(h=0,col=gray)
legend("topright",c("BA bias","TPA (stem count) bias"),fill=c(off,on),border=NA,bty="n",cex=0.85)
text(colMeans(bp),16,c("","SDImort\ninert","MORTCAL\ntrades"),cex=0.7,font=3)

## B: Bakuzis Reineke slope by config
bo<-c("legacy","mortcal","v126def","b15","b20"); blab<-c("legacy\n(12.5.0)","MORTCAL","v12.6\n(b.10)","b.15","b.20")
sl<-sapply(bo,function(x) bz$reineke_slope[bz$config==x]); te<-sapply(bo,function(x) bz$tph_end_site14[bz$config==x])
cols<-c(gray,on,"#4E9A4E","#7FbF7F","#bfe0bf")
bp2<-barplot(sl,col=cols,border=NA,ylim=c(-1.8,0),ylab="Reineke self-thinning slope",
   names.arg=blab,main="B. Bakuzis self-thinning (frontier)",cex.names=0.8)
abline(h=-1.605,lty=2,lwd=2,col="#222")
text(0.7,-1.605+0.07,"Reineke law -1.605",cex=0.8,font=3,pos=4)
text(bp2,sl-0.08,sprintf("%.2f",sl),cex=0.8)
text(bp2,-0.12,paste0(te,"\nstems"),cex=0.62,font=3)
dev.off(); cat("FIG done\n")
