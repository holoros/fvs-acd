# v12.6.1 regional volume+value figure. Panel A: bias by region (NS/NB/ME/ALL) for ev.
# Panel B: ingrowth configs (noing/ev/ev_m20) for ALL region (shows ~nil short-horizon effect).
sc <- read.csv("/users/PUOM0008/crsfaaron/silc_cfi/region_value_scorecard.csv", stringsAsFactors=FALSE)
FIG <- "/users/PUOM0008/crsfaaron/silc_cfi/acadgy_v1261_regional_value.png"
png(FIG, width=2200, height=950, res=200)
par(mfrow=c(1,2), mar=c(4.5,4.4,3,1), mgp=c(2.5,0.8,0), font.main=2)
cols <- c(BA="#4878A8", TPA="#C0504D", value="#4E9A4E")
## A: ev by region
ev <- sc[sc$config=="ev",]; ev <- ev[match(c("NS","NB","ME","ALL"), ev$region),]
m <- rbind(BA=ev$BA, TPA=ev$TPA, value=ev$value)
bp <- barplot(m, beside=TRUE, col=cols, border=NA, names.arg=ev$region, ylim=c(-6,15),
   ylab="percent bias (pred over obs - 1)", main="A. v12.6.1 bias by region")
abline(h=0, col="#888"); legend("topleft", c("BA","stems (TPA)","value $"), fill=cols, border=NA, bty="n", cex=0.8)
## B: ingrowth configs, ALL region
al <- sc[sc$region=="ALL",]; al <- al[match(c("noing","ev","ev_m20"), al$config),]
m2 <- rbind(TPA=al$TPA, QMD=al$QMD, value=al$value)
bp2 <- barplot(m2, beside=TRUE, col=c("#C0504D","#7B68A6","#4E9A4E"), border=NA,
   names.arg=c("no ingrowth","expected-value","EV x2.0"), ylim=c(0,6),
   ylab="percent bias", main="B. Ingrowth effect (ALL, 5-7 yr)", cex.names=0.85)
legend("topright", c("stems (TPA)","QMD","value $"), fill=c("#C0504D","#7B68A6","#4E9A4E"), border=NA, bty="n", cex=0.8)
mtext("ingrowth ~invisible at 5-7 yr (recruits below merch size)", side=1, line=3, cex=0.7, font=3)
dev.off(); cat("wrote", FIG, "\n")
