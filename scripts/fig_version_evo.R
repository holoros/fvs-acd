# Version-evolution figure: all-region percent bias by component for 12.5.0, 12.6.0, 12.6.1
# (native configs), replicating the AcdBenchCompare version comparison.
sc <- read.csv("/users/PUOM0008/crsfaaron/silc_cfi/region_value_scorecard.csv", stringsAsFactors=FALSE)
FIG <- "/users/PUOM0008/crsfaaron/silc_cfi/acadgy_version_evolution.png"
g <- function(cfg) sc[sc$config==cfg & sc$region=="ALL",]
v <- rbind("12.5.0"=g("v125"), "12.6.0"=g("v126"), "12.6.1"=g("ev"))
M <- t(as.matrix(v[,c("BA","TPA","value")])); colnames(M)<-c("12.5.0","12.6.0","12.6.1")
png(FIG, width=1700, height=1000, res=200)
par(mar=c(4,4.4,3.2,1), mgp=c(2.6,0.8,0), font.main=2)
cols <- c("#4878A8","#C0504D","#4E9A4E")
bp <- barplot(M, beside=TRUE, col=cols, border=NA, ylim=c(0,9),
  ylab="all-region percent bias (pred over obs - 1)",
  main="AcadianGY version evolution on NB/NS/ME (5-7 yr)", legend.text=c("basal area","stems (TPA)","value $"),
  args.legend=list(x="topright", bty="n", border=NA))
text(bp, M+0.3, sprintf("%.1f", M), cex=0.8)
mtext("12.6.0 self-thinning roughly halves the over-prediction; 12.6.1 holds it", side=1, line=2.4, cex=0.8, font=3)
dev.off(); cat("wrote", FIG, "\n")
