B<-"/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update"
t<-read.csv(file.path(B,"results/seven_islands/bz_v1262b_traj.csv"))
png(file.path(B,"figures/acadgy_esi_anchor_site_curves.png"),width=1700,height=1000,res=200)
par(mar=c(4.4,4.4,3,1),mgp=c(2.5,0.8,0),font.main=2)
sites<-sort(unique(t$site)); pal<-hcl.colors(length(sites),"Zissou 1")
plot(NA,xlim=c(0,150),ylim=c(0,38),xlab="stand age (yr)",ylab="dominant height (m)",
  main="ESI-anchored dominant height (fitted Chapman-Richards k=0.0039, p=0.726)")
for(i in seq_along(sites)){g<-t[t$site==sites[i],];g<-g[order(g$age),];lines(g$age,g$HT,col=pal[i],lwd=2.5)}
abline(v=50,lty=3,col="#888"); points(rep(50,length(sites)),sites,pch=18,col=pal,cex=1.3)
legend("topleft",legend=paste("ESI",sites),col=pal,lwd=2.5,bty="n",cex=0.9,title="site (ESI, m)")
text(52,3,"base age 50:\ncurves pass through ESI",cex=0.7,font=3,pos=4)
grid(); dev.off(); cat("wrote fig\n")
