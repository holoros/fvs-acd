# FVS-ACD modernization capstone: verification of handoff numbers against the
# source CSVs, plus a 4-panel summary figure. Base R graphics (no ggplot dep).
RES <- "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/results/seven_islands"
FIG <- "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/figures"
rd <- function(f) read.csv(file.path(RES, f), stringsAsFactors=FALSE)

mc  <- rd("silc_cfi_mortcal_flag.csv")   # SILC horizon BA, MORTCAL off/on
v125<- rd("silc_cfi_v125_full.csv")      # 12.5.0 site x MORTCAL
fia <- rd("acadgy_fia_remeas_stress.csv")# FIA site x MORTCAL, BA/TPA/QMD

## ---- verification block: assert handoff numbers match the CSVs ----
chk <- function(label, got, want, tol=0.05){
  ok <- is.finite(got) && abs(got-want) <= tol
  cat(sprintf("[%s] %-46s got %7.2f  expect %7.2f\n", ifelse(ok,"OK","XX"), label, got, want))
  ok }
g <- function(df,cfg,hz,col="BA_bias") df[df$config==cfg & df$horizon==hz, col][1]
res <- c(
  chk("SILC MORTCAL off ALL BA",    g(mc,"MORTCAL_off","ALL"),       11.1),
  chk("SILC MORTCAL on  ALL BA",    g(mc,"MORTCAL_on","ALL"),        -1.3),
  chk("SILC MORTCAL off 12-15yr BA",g(mc,"MORTCAL_off","12-15yr"),   15.8),
  chk("SILC MORTCAL on  12-15yr BA",g(mc,"MORTCAL_on","12-15yr"),     0.0),
  chk("v125 csi12 off ALL BA",      g(v125,"csi12_off","ALL"),       11.3),
  chk("v125 csi21 off ALL BA (site)",g(v125,"csi21_off","ALL"),      12.7),
  chk("FIA legacy off BA",          g(fia,"legacy_off","ALL"),        3.1),
  chk("FIA ESI off BA (== legacy)", g(fia,"ESI_off","ALL"),           3.1),
  chk("FIA legacy off TPA",         g(fia,"legacy_off","ALL","TPA_bias"), -8.4),
  chk("FIA legacy on  TPA",         g(fia,"legacy_on","ALL","TPA_bias"), -15.4),
  chk("FIA legacy off QMD",         g(fia,"legacy_off","ALL","QMD_bias"),  6.9))
cat(sprintf("\nVERIFICATION: %d/%d numbers match the source CSVs.\n", sum(res), length(res)))

## ---- Reineke slopes (from the bz_rd run output) ----
rein <- data.frame(config=c("base","MORTCAL","RD modifiers\n(all on)"),
                   slope=c(-0.82,-0.96,-0.82))

## ---- capstone figure ----
png(file.path(FIG,"acadgy_capstone_summary.png"), width=2200, height=1700, res=200)
par(mfrow=c(2,2), mar=c(4.2,4.4,3.2,1.2), mgp=c(2.5,0.8,0), font.main=2, cex.main=1.15)
col_off <- "#4878A8"; col_on <- "#C0504D"; grayln <- "#888888"

## A: site is a weak lever (SILC 12.5.0 off, + FIA off)
siteBA <- c(csi12=g(v125,"csi12_off","ALL"), csi15=g(v125,"csi15_off","ALL"),
            csi21=g(v125,"csi21_off","ALL"),
            FIAlegacy=g(fia,"legacy_off","ALL"), FIAesi=g(fia,"ESI_off","ALL"),
            FIA2030=g(fia,"CSI2030_off","ALL"))
bp <- barplot(siteBA, col=c(rep("#7BA7CE",3),rep("#A8C4A2",3)), border=NA,
        ylim=c(-2,16), ylab="BA bias (%)",
        names.arg=c("CSI12","CSI15","CSI21","legacy","ESI","2030"),
        main="A. Site input is a weak lever on BA")
abline(h=0, col=grayln); text(bp, siteBA+0.6, sprintf("%.1f",siteBA), cex=0.8)
legend("topright", c("Seven Islands CFI (flat CSI)","Maine FIA (site surfaces)"),
       fill=c("#7BA7CE","#A8C4A2"), border=NA, bty="n", cex=0.8)
mtext("spread < 1.5 pp across the full site range", side=3, line=-0.1, cex=0.72, font=3)

## B: MORTCAL removes the long-horizon BA over-prediction (SILC)
hz <- c("5-7yr","8-11yr","12-15yr","ALL")
off <- sapply(hz, function(h) g(mc,"MORTCAL_off",h))
on  <- sapply(hz, function(h) g(mc,"MORTCAL_on",h))
m <- rbind(off,on)
bp2 <- barplot(m, beside=TRUE, col=c(col_off,col_on), border=NA,
        ylim=c(-20,22), ylab="BA bias (%)", names.arg=hz,
        main="B. MORTCAL removes the long-horizon BA bias")
abline(h=0, col=grayln)
legend("topright", c("MORTCAL off","MORTCAL on"), fill=c(col_off,col_on), border=NA, bty="n", cex=0.9)

## C: stem-count gap (FIA): TPA under, QMD over; MORTCAL deepens TPA deficit
stem <- rbind(
  TPA=c(off=g(fia,"legacy_off","ALL","TPA_bias"), on=g(fia,"legacy_on","ALL","TPA_bias")),
  QMD=c(off=g(fia,"legacy_off","ALL","QMD_bias"), on=g(fia,"legacy_on","ALL","QMD_bias")))
bp3 <- barplot(t(stem), beside=TRUE, col=c(col_off,col_on), border=NA,
        ylim=c(-18,12), ylab="bias (%)", names.arg=c("stems/acre (TPA)","mean size (QMD)"),
        main="C. Stem-count gap holds on FIA")
abline(h=0, col=grayln)
legend("topright", c("MORTCAL off","MORTCAL on"), fill=c(col_off,col_on), border=NA, bty="n", cex=0.85)
text(mean(bp3[,1]), -15.5, "MORTCAL buys BA by\nremoving stems", cex=0.75, font=3)

## D: Reineke self-thinning slope vs the law
bp4 <- barplot(rein$slope, col=c("#999999",col_on,"#cccccc"), border=NA,
        ylim=c(-1.8,0), ylab="Reineke self-thinning slope", names.arg=rein$config,
        main="D. Self-thinning still short of the Reineke law")
abline(h=-1.605, col="#222222", lty=2, lwd=2)
text(0.7, -1.605+0.07, "Reineke law -1.605", cex=0.85, font=3, pos=4)
text(bp4, rein$slope-0.08, sprintf("%.2f",rein$slope), cex=0.85)
text(bp4[3], -0.5, "RD modifiers\ninert (= base)", cex=0.72, font=3)
dev.off()
cat("FIGURE: figures/acadgy_capstone_summary.png\n")
