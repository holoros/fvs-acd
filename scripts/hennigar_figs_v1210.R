# =============================================================================
# Title: Hennigar Aug 2026 deck figures, v12.10 (journal-quality ggplot2)
# Author: A. Weiskittel
# Date: 2026-07-02
# Description: Five-way scorecard heatmap, management-modifier centerpiece + concept,
#              long-horizon trajectory, Bakuzis pass/flag matrix, forest-type panel.
# Dependencies: Wfull.rds, mgmt_modifier_coefs.rds, bakuzis_traj_allmodels.csv,
#               bakuzis_relations.csv (all in ~/magplot/verify)
# =============================================================================
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(ggplot2); library(patchwork)})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
OUT <- "/users/PUOM0008/crsfaaron/magplot/verify/figs_v1210"; dir.create(OUT, showWarnings=FALSE)

## CRSF palette
crsf_green <- "#1a3d28"; crsf_blue <- "#7db5d5"; crsf_gold <- "#c5a55a"
model_cols <- c("v12.5.0"="#b9c4bd","v12.7.0"="#8bbf9f","v12.9.x"="#3f7d57","v12.10"="#1a3d28","OSM"="#c5773a")
theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_text(size = 12), axis.text = element_text(size = 10),
        legend.position = "bottom", legend.title = element_text(size = 10),
        legend.text = element_text(size = 9), strip.text = element_text(size = 11, face = "bold"),
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, colour = "grey30"),
        plot.margin = margin(10, 10, 10, 10))
sv <- function(p,f,w=20,h=13) ggsave(file.path(OUT,f), p, width=w, height=h, units="cm", dpi=300, bg="white")

W <- readRDS("Wfull.rds"); setDT(W)
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
Mlab <- c(BA="Basal area",SDI="SDI",QMD="QMD",TOPHT="Top height",TOTVOL="Total vol",
          MERCHVOL="Merch vol",SAWVOL="Sawlog vol",BIOMASS="Biomass",VALUE="Value")
models <- c(v125="v12.5.0", v1270="v12.7.0", v129x="v12.9.x", v1210="v12.10", osm="OSM")
biaspct <- function(mdl,m,idx) 100*(mean(W[[paste0(mdl,".",m)]][idx],na.rm=TRUE)/mean(W[[paste0(m,"_o")]][idx],na.rm=TRUE)-1)

## ---- F1: five-way scorecard heatmap (ALL domain, level bias %) ----
allidx <- seq_len(nrow(W))
hm <- rbindlist(lapply(names(models), function(md) data.table(model=models[[md]],
        metric=Mlab[M], bias=sapply(M, function(m) biaspct(md,m,allidx)))))
hm[, model := factor(model, levels=unname(models))]
hm[, metric := factor(metric, levels=unname(Mlab[M]))]
f1 <- ggplot(hm, aes(model, metric, fill=bias)) +
  geom_tile(colour="white", linewidth=0.6) +
  geom_text(aes(label=sprintf("%+.0f", bias)), size=3.4,
            colour=ifelse(abs(hm$bias)>12,"white","grey15")) +
  scale_fill_gradient2(low="#2166AC", mid="white", high="#B2182B", midpoint=0,
                       limits=c(-25,25), oob=scales::squish, name="Level bias (%)") +
  labs(title="Five-way accuracy scorecard, independent MagPlot (n=705)",
       subtitle="Predicted vs observed level bias on FIA NSVB.\nOSM modeling efficiency is positive (0.70 to 0.75); it is accurate and precise.",
       x=NULL, y=NULL) + theme_pub + theme(panel.grid=element_blank())
sv(f1,"F1_scorecard_heatmap.png",22,15)

## ---- F2: management-modifier centerpiece (total-vol bias by class) ----
cls_levels <- c("NONE","PLANTED","PCT","MANAGED")
cls_lab <- c(NONE="Unmanaged\n(n=266)", PLANTED="Planted\n(n=51)", PCT="PCT\n(n=95)", MANAGED="All managed\n(n=146)")
managed_idx <- which(W$mgmt %in% c("PLANTED","PCT"))
idxof <- function(cls) if(cls=="MANAGED") managed_idx else which(W$mgmt==cls)
f2d <- rbindlist(lapply(cls_levels, function(cls){ idx<-idxof(cls)
        data.table(class=cls, model=c("v12.9.x","v12.10","OSM"),
                   bias=c(biaspct("v129x","TOTVOL",idx), biaspct("v1210","TOTVOL",idx), biaspct("osm","TOTVOL",idx)))}))
f2d[, class := factor(class, levels=cls_levels, labels=cls_lab[cls_levels])]
f2d[, model := factor(model, levels=c("v12.9.x","v12.10","OSM"))]
f2 <- ggplot(f2d, aes(class, bias, fill=model)) +
  geom_col(position=position_dodge(0.72), width=0.66) +
  geom_hline(yintercept=0, colour="grey40") +
  geom_text(aes(label=sprintf("%+.1f", bias)), position=position_dodge(0.72), vjust=ifelse(f2d$bias>=0,-0.4,1.2), size=3) +
  scale_fill_manual(values=c("v12.9.x"="#3f7d57","v12.10"="#1a3d28","OSM"="#c5773a"), name=NULL) +
  labs(title="Management modifiers close the managed-stand gap to OSM",
       subtitle="Total-volume level bias by management class. v12.10 adds direct-effect planted (Type 2) and PCT (Type 1) modifiers.",
       x=NULL, y="Total-volume level bias (%)") + theme_pub
sv(f2,"F2_mgmt_centerpiece.png",22,14)

## ---- F3: modifier concept (decay + sustained) + gap closure ----
co <- readRDS("mgmt_modifier_coefs.rds")
tst <- seq(0,40,0.5)
cd <- rbind(data.table(type="PCT (Type 1, transient)", tst=tst, mult=1+co$pct_a*exp(-co$pct_b*tst)),
            data.table(type="Planted (Type 2, sustained)", tst=tst, mult=co$m_planted_BA))
p3a <- ggplot(cd, aes(tst, mult, colour=type)) + geom_line(linewidth=1.2) +
  scale_colour_manual(values=c("PCT (Type 1, transient)"=crsf_gold,"Planted (Type 2, sustained)"=crsf_green), name=NULL) +
  geom_hline(yintercept=1, linetype=2, colour="grey50") +
  labs(title="A) Direct-effect modifier form (Ch 11)", x="Years since treatment", y="Diameter-growth multiplier") +
  theme_pub
gc <- fread("mgmt_gap_closure.csv")
gc[, class := factor(class, levels=c("PLANTED","PCT","MANAGED"))]
gcl <- melt(gc[,.(class, `v12.9.x`=mae_v129x, `v12.10`=mae_v1210, OSM=mae_osm)], id.vars="class", variable.name="model", value.name="mae")
gcl[, model := factor(model, levels=c("v12.9.x","v12.10","OSM"))]
p3b <- ggplot(gcl, aes(class, mae, fill=model)) +
  geom_col(position=position_dodge(0.72), width=0.66) +
  geom_text(aes(label=sprintf("%.1f",mae)), position=position_dodge(0.72), vjust=-0.3, size=3) +
  scale_fill_manual(values=c("v12.9.x"="#3f7d57","v12.10"="#1a3d28","OSM"="#c5773a"), name=NULL) +
  labs(title="B) Mean absolute bias across 9 metrics", x=NULL, y="Mean |level bias| (%)") + theme_pub
f3 <- p3a + p3b + plot_layout(widths=c(1,1.1))
sv(f3,"F3_mgmt_concept_gap.png",26,12)

## ---- F4: long-horizon trajectory (FVS plateaus, OSM does not) ----
tj <- fread("bakuzis_traj_allmodels.csv")
tj <- tj[site==tj[,round(median(unique(site)))] | site==unique(site)[ceiling(length(unique(site))/2)]]
if(nrow(tj)==0) tj <- fread("bakuzis_traj_allmodels.csv")[site==unique(site)[1]]
tj[, mlab := fifelse(model=="v125","v12.5.0", fifelse(model=="v1270","v12.7.0",
              fifelse(model=="v1271","v12.7.1", fifelse(model=="v129x","v12.9.x", model))))]
# OSM annotation: Seven Islands matched stands climb 32 to 42 m2/ha over 60 yr with no self-thinning
osm_ann <- data.table(age=c(1,60), BAPH=c(32,42))
f4 <- ggplot(tj[mlab %in% c("v12.5.0","v12.9.x")], aes(age, BAPH, colour=mlab)) +
  geom_line(linewidth=1.1) +
  geom_line(data=osm_ann, aes(age,BAPH), colour="#c5773a", linewidth=1.1, linetype=1, inherit.aes=FALSE) +
  annotate("text", x=52, y=43.5, label="OSM (no plateau)", colour="#c5773a", size=3.4, hjust=1) +
  annotate("text", x=150, y=30.5, label="v12.9.x plateaus ~36", colour="#1a3d28", size=3.4, hjust=1) +
  annotate("text", x=150, y=63, label="v12.5.0 runs away (no self-thin)", colour="#8a9a8f", size=3.4, hjust=1) +
  scale_colour_manual(values=c("v12.5.0"="#b9c4bd","v12.9.x"="#1a3d28"), name=NULL) +
  labs(title="Long-horizon biological realism: FVS-ACD self-thins, OSM does not",
       subtitle="Seeded 160-yr basal-area trajectory on a mid-productivity site. OSM segment from matched Seven Islands 60-yr run.",
       x="Stand age (years)", y=expression("Basal area ("*m^2~ha^-1*")")) + theme_pub
sv(f4,"F4_longhorizon.png",22,13)

## ---- F5: Bakuzis pass/flag matrix ----
br <- fread("bakuzis_relations.csv")
br[, mlab := fifelse(model=="v125","v12.5.0", fifelse(model=="v1270","v12.7.0",
             fifelse(model=="v1271","v12.7.1", fifelse(model=="v129x","v12.9.x", toupper(model)))))]
rel <- c("Eichhorn","Reineke","SiteOrdering","YieldDensity_plateau","Sukachev")
rell <- c(Eichhorn="Eichhorn (V~H)", Reineke="Reineke self-thin", SiteOrdering="Site ordering",
          YieldDensity_plateau="Yield-density plateau", Sukachev="Sukachev")
bl <- melt(br[,c("mlab",rel),with=FALSE], id.vars="mlab", variable.name="relation", value.name="status")
# add OSM row from finalized memo: Reineke flag, plateau flag, rest pass
osm_bk <- data.table(mlab="OSM", relation=rel, status=c("PASS","FLAG","PASS","FLAG","PASS"))
bl <- rbind(bl, osm_bk[, .(mlab, relation, value=status)], use.names=FALSE)
bl[, relation := factor(rell[as.character(relation)], levels=unname(rell))]
bl[, mlab := factor(mlab, levels=c("v12.5.0","v12.7.0","v12.7.1","v12.9.x","OSM"))]
bl <- bl[!is.na(mlab)]
f5 <- ggplot(bl, aes(mlab, relation, fill=status)) +
  geom_tile(colour="white", linewidth=0.8) +
  geom_text(aes(label=status), size=3.3, colour="white", fontface="bold") +
  scale_fill_manual(values=c("PASS"="#3f7d57","FLAG"="#c5773a"), name=NULL) +
  labs(title="Bakuzis biological-realism relations by model",
       subtitle="Seeded 160-yr projections across an ESI gradient.\nSelf-thinning versions pass; OSM flags plateau and Reineke.",
       x=NULL, y=NULL) + theme_pub + theme(panel.grid=element_blank())
sv(f5,"F5_bakuzis_matrix.png",20,12)

## ---- F6: performance by forest type (finalized enhanced-scorecard numbers) ----
ft <- data.table(
  fortype=rep(c("Softwood (n=321)","Mixedwood (n=186)","Hardwood (n=178)"), each=5),
  model=rep(c("v12.5.0","v12.7.0","v12.7.1","v12.9.x","OSM"),3),
  bias=c(8,0,-7,-7,-1,  16,11,5,3,-4,  42,36,30,25,15))
ft[, fortype := factor(fortype, levels=c("Softwood (n=321)","Mixedwood (n=186)","Hardwood (n=178)"))]
ft[, model := factor(model, levels=c("v12.5.0","v12.7.0","v12.7.1","v12.9.x","OSM"))]
f6 <- ggplot(ft, aes(model, bias, fill=model)) +
  geom_col(width=0.7) + geom_hline(yintercept=0, colour="grey40") +
  geom_hline(yintercept=c(-10,10), linetype=3, colour="grey60") +
  geom_text(aes(label=sprintf("%+d",bias)), vjust=ifelse(ft$bias>=0,-0.3,1.2), size=3) +
  facet_wrap(~fortype) +
  scale_fill_manual(values=model_cols, guide="none") +
  labs(title="Total-volume bias by forest type: hardwood is the shared frontier",
       subtitle="Dotted lines mark the plus or minus 10 pct equivalence region. Softwood is equivalent for every model; hardwood over-predicts for all, even OSM.",
       x=NULL, y="Total-volume level bias (%)") + theme_pub +
  theme(axis.text.x=element_text(angle=35, hjust=1))
sv(f6,"F6_forest_type.png",26,12)

cat("FIGURES DONE in", OUT, "\n"); print(list.files(OUT))
