# Diameter-increment diagnosis figure: regional bias (the mortality-deficit signal),
# size-form bias, and density bias. Base R.
FIG <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/active-projects/fvs-acd-site-update/figures/acadgy_increment_diagnosis.png"
png(FIG, width=2300, height=820, res=200)
par(mfrow=c(1,3), mar=c(4.5,4.4,3.2,1), mgp=c(2.6,0.8,0), font.main=2)
ax <- function(v) ifelse(v>=0,"#C0504D","#4878A8")
## A region
reg <- c(ME=-14.5, NB=7.2, NS=-3.2)
b<-barplot(reg, col=ax(reg), border=NA, ylim=c(-20,12), ylab="dDBH bias % (pred over obs - 1)", main="A. Diameter increment by region")
abline(h=0,col="#888"); text(b, reg+ifelse(reg>=0,1.2,-1.4), sprintf("%+.1f",reg), cex=0.95)
mtext("Maine under-grows; BA still over-predicts -> mortality deficit", side=1, line=2.5, cex=0.7, font=3)
## B DBH class
dc <- c("<10"=14.3,"10-20"=-2.0,"20-30"=-4.5,"30+"=-13.0)
b2<-barplot(dc, col=ax(dc), border=NA, ylim=c(-18,18), ylab="dDBH bias %", main="B. Size-form bias (by DBH cm)")
abline(h=0,col="#888"); text(b2, dc+ifelse(dc>=0,1.4,-1.6), sprintf("%+.1f",dc), cex=0.95)
mtext("over-grows small, under-grows large", side=1, line=2.5, cex=0.7, font=3)
## C RD class
rd <- c("<0.4"=-5.5,"0.4-0.6"=4.7,"0.6-0.8"=9.5,"0.8+"=-19.1)
b3<-barplot(rd, col=ax(rd), border=NA, ylim=c(-22,14), ylab="dDBH bias %", main="C. Density bias (relative density)")
abline(h=0,col="#888"); text(b3, rd+ifelse(rd>=0,1.4,-1.7), sprintf("%+.1f",rd), cex=0.95)
mtext("strong under-prediction at high density", side=1, line=2.5, cex=0.7, font=3)
dev.off(); cat("wrote",FIG,"\n")
