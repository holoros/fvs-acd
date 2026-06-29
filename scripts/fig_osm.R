# FVS-ACD 12.6.1 vs OSM long-term trajectory on matched Seven Islands stands.
B <- "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/results/osm"
FIG <- "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/figures/acadgy_vs_osm.png"
f <- read.csv(file.path(B,"fvsacd_osm_stands_traj.csv"))
o <- read.csv(file.path(B,"silc_StandListProjections.csv")); o <- o[o$BA>0, c("SurveyID","Age","BA","QMD")]
names(o) <- c("SurveyID","Age","BA_osm","QMD_osm")
m <- merge(f, o, by=c("SurveyID","Age"))
ag <- aggregate(cbind(BA, BA_osm, QMD, QMD_osm)~Age, m, mean)
ag <- ag[order(ag$Age) & ag$Age<=80, ]
png(FIG, width=2000, height=900, res=200)
par(mfrow=c(1,2), mar=c(4.4,4.4,3,1), mgp=c(2.5,0.8,0), font.main=2)
fv<-"#C0504D"; os<-"#4878A8"
plot(ag$Age, ag$BA_osm, type="o", pch=16, col=os, lwd=2, ylim=c(20,42), xlab="projection age (yr)",
  ylab="basal area (m2/ha)", main="A. Basal area: FVS-ACD vs OSM")
lines(ag$Age, ag$BA, type="o", pch=17, col=fv, lwd=2); grid()
legend("topleft", c("OSM v2.26.1","FVS-ACD 12.6.1"), col=c(os,fv), pch=c(16,17), lwd=2, bty="n", cex=0.9)
text(60, 39, "~15 m2/ha divergence\nby age 80", cex=0.78, font=3)
plot(ag$Age, ag$QMD_osm, type="o", pch=16, col=os, lwd=2, ylim=c(9,23), xlab="projection age (yr)",
  ylab="QMD (cm)", main="B. Mean tree size (QMD)")
lines(ag$Age, ag$QMD, type="o", pch=17, col=fv, lwd=2); grid()
legend("topleft", c("OSM","FVS-ACD"), col=c(os,fv), pch=c(16,17), lwd=2, bty="n", cex=0.9)
mtext("matched Seven Islands stands; same starting inventory", side=1, line=-1.2, outer=TRUE, cex=0.75, font=3)
dev.off(); cat("wrote",FIG,"\n")
