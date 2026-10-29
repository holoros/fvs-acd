# fig17: component decomposition (survivor growth, mortality, ingrowth), obs vs pred,
# BASE (v12.10.1 frozen) vs 3B candidate (v12.11 levers: IGMULT=2.5, MORTGATE, STANDCON),
# for me_fia_l, baxter, ctrn. Units m3 ha-1. CRSF house style (theme_classic, 300 dpi).
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(ggplot2)})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

d <- fread("fig17_decomp_agg.csv")

# Build long form: one row per SOURCE x SERIES x COMPONENT
series_lab <- function(config, which) {
  if (which=="observed") return("Observed")
  if (config=="BASE") return("Predicted, BASE")
  if (config=="3B") return("Predicted, 3B candidate")
  NA_character_
}
d[, SERIES := mapply(series_lab, CONFIG, WHICH)]

long <- rbindlist(lapply(seq_len(nrow(d)), function(i) {
  r <- d[i]
  data.table(SOURCE=r$SOURCE, SERIES=r$SERIES,
    COMPONENT=c("Survivor growth","Mortality","Ingrowth"),
    VALUE=c(r$sg_V, -r$mo_V, r$ig_V))
}))

src_lab <- c(me_fia_l="Maine FIA (developing)", baxter="Baxter (mature, held-out)", ctrn="CFRU CTRN (managed)")
long[, SOURCE_LAB := factor(src_lab[SOURCE], levels=src_lab[c("me_fia_l","baxter","ctrn")])]
long[, COMPONENT := factor(COMPONENT, levels=c("Survivor growth","Mortality","Ingrowth"))]
long[, SERIES := factor(SERIES, levels=c("Observed","Predicted, BASE","Predicted, 3B candidate"))]

pal <- c("Observed"="#4d4d4d", "Predicted, BASE"="#1b7837", "Predicted, 3B candidate"="#d6604d")

p <- ggplot(long, aes(x=COMPONENT, y=VALUE, fill=SERIES)) +
  geom_col(position=position_dodge(width=0.75), width=0.68, color="black", linewidth=0.25) +
  geom_hline(yintercept=0, color="black", linewidth=0.3) +
  facet_wrap(~SOURCE_LAB, nrow=1) +
  scale_fill_manual(values=pal, name=NULL) +
  labs(x=NULL, y=expression(Volume~component~(m^3~ha^-1)),
       title="Component decomposition of net stand volume change: observed vs predicted, BASE vs 3B candidate") +
  theme_classic(base_size=12) +
  theme(
    strip.background=element_rect(fill="grey90", color="black", linewidth=0.3),
    strip.text=element_text(face="bold", size=10),
    legend.position="bottom",
    axis.text.x=element_text(angle=20, hjust=1),
    plot.title=element_text(face="bold", size=11, hjust=0.5),
    panel.spacing=unit(1, "lines")
  )

ggsave("fig17_decomposition.png", p, width=10.5, height=5.2, dpi=300, bg="white")
cat("saved fig17_decomposition.png\n")
