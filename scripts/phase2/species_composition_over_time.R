# =====================================================================
# species_composition_over_time.R
# Validation test: does each model reproduce the observed shift in
# percent species composition across the remeasurement interval?
# Frozen August FVS-ACD basis. Aggregates only; runs on Cardinal.
#
# Composition = basal-area fraction by species group per stand:
#   softwood vs hardwood, and a three-way split
#   (spruce-fir = Abies + Picea; other softwood; hardwood).
# Predicted composition:
#   FVS-ACD flagships (v12.5.0, v12.7.0, v12.10.1) from the frozen
#     composition re-run comp_*_frozen_results.csv (bench_species_comp_frozen.R).
#   OSM from its predicted treelist osm_h2h_treelist.csv.
# Stand set: the frozen scorecard POOLED set (n = 705) via frozen_subsidiary_W.rds.
# No em dashes.
# =====================================================================
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(ggplot2); library(patchwork); library(ggtext)})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

CN <- c("BAc","SWF","SFF","OSWF","HWF")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
SF <- c("BF","RS","BS","WS","NS")
AGY <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA",
         "BT","BP","EC","AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
mapsp <- function(s){ s<-toupper(s); ifelse(s %in% AGY, s, ifelse(s %in% sw, "OS","OH")) }

rd <- function(f){ x<-fread(f); x[,STAND:=as.character(STAND)]; x[!duplicated(STAND)] }

# ---- frozen scorecard stand set (n=705) + committed forest type ----
W  <- as.data.table(readRDS("frozen_subsidiary_W.rds"))[,.(STAND=as.character(STAND), PROV, fortype)]
cat(sprintf("frozen W stands: n=%d (SW=%d MW=%d HW=%d Unk=%d)\n", nrow(W),
    sum(W$fortype=="Softwood"), sum(W$fortype=="Mixedwood"),
    sum(W$fortype=="Hardwood"), sum(W$fortype=="Unknown")))

# ---- FVS-ACD flagship composition re-runs (predicted + shared observed) ----
# prefer parallel (_p) outputs if present, else the sequential-job outputs
pick <- function(base){ p<-sub("_results","_p_results",base); if(file.exists(p)) p else base }
v125  <- rd(pick("comp_v125_frozen_results.csv"))
v1270 <- rd(pick("comp_v1270_frozen_results.csv"))
v1210 <- rd(pick("comp_v12101_frozen_results.csv"))

# observed composition (t1 and observed t2) is identical across models; take from v1210
obs <- v1210[, c("STAND", paste0(CN,"_t1"), paste0(CN,"_o")), with=FALSE]

# ---- OSM predicted composition from its treelist ----
tl <- fread("osm_h2h_treelist.csv"); tl[,STAND:=as.character(STAND)]
tl[, SPm := mapsp(SP)]
tl <- tl[is.finite(DBH) & DBH>=4 & is.finite(EXPF) & EXPF>0]
tl[, ba := pi*(DBH/200)^2*EXPF]
tl[, `:=`(issw = SPm %in% sw, issf = SPm %in% SF)]
osm <- tl[, .(BAc_p=sum(ba),
              SWF_p =sum(ba[issw])/sum(ba),
              SFF_p =sum(ba[issf])/sum(ba),
              OSWF_p=sum(ba[issw & !issf])/sum(ba),
              HWF_p =sum(ba[!issw])/sum(ba)), by=STAND]

# ---- stack predicted, attach shared observed + fortype, restrict to W (705) ----
predcols <- c("STAND", paste0(CN,"_p"))
mk <- function(dt,lab){ d<-dt[, predcols, with=FALSE]; d[,model:=lab]; d }
pred <- rbindlist(list(mk(v125,"v12.5.0"), mk(v1270,"v12.7.0"),
                       mk(v1210,"v12.10.1"), mk(osm,"OSM")), use.names=TRUE)
D <- merge(pred, obs, by="STAND")
D <- merge(D, W,   by="STAND")                       # inner join -> frozen 705 unique set
D <- D[is.finite(SWF_t1) & is.finite(SWF_o) & is.finite(SWF_p)]  # composition must be defined
D[, model := factor(model, levels=c("v12.5.0","v12.7.0","v12.10.1","OSM"))]
cat(sprintf("per-model classifiable stands (finite composition), frozen 705 unique set: %s\n",
    paste(sprintf("%s=%d", levels(D$model), as.integer(table(D$model))), collapse=" ")))
cat(sprintf("dropped (no t1 basal area / Unknown fortype): %d of 705\n",
    705L - nrow(D[model=="v12.10.1"])))

# adversarial self-check: fraction bounds + fortype consistency (softwood mean SWF)
stopifnot(all(D$SWF_o>=0 & D$SWF_o<=1, na.rm=TRUE), all(D$SWF_p>=0 & D$SWF_p<=1, na.rm=TRUE))
cat("self-check mean observed t1 softwood fraction by committed fortype:\n")
print(D[model=="v12.10.1", .(mean_SWF_t1=round(100*mean(SWF_t1),1),
        mean_SWF_t2=round(100*mean(SWF_o),1), n=.N), by=fortype][order(-mean_SWF_t1)])
cat(sprintf("OSM predicted mean softwood fraction (plausibility): %.1f%% [range %.1f-%.1f]\n",
    100*mean(osm$SWF_p), 100*min(osm$SWF_p), 100*max(osm$SWF_p)))

# ---- summarise per model x stratum ----
strata_of <- function(dt) rbindlist(list(
  cbind(stratum="Pooled",    dt),
  cbind(stratum="Softwood",  dt[fortype=="Softwood"]),
  cbind(stratum="Mixedwood", dt[fortype=="Mixedwood"]),
  cbind(stratum="Hardwood",  dt[fortype=="Hardwood"])) , use.names=TRUE)

summ <- strata_of(D)[, {
  n <- .N
  o_t1 <- 100*mean(SWF_t1); o_t2 <- 100*mean(SWF_o); p_t2 <- 100*mean(SWF_p)
  o_shift <- 100*mean(SWF_o - SWF_t1); p_shift <- 100*mean(SWF_p - SWF_t1)
  bias <- 100*mean(SWF_p - SWF_o)
  sf_o_t1 <- 100*mean(SFF_t1); sf_o_t2 <- 100*mean(SFF_o); sf_p_t2 <- 100*mean(SFF_p)
  hw_o_t2 <- 100*mean(HWF_o); hw_p_t2 <- 100*mean(HWF_p)
  .(n=n,
    obs_swf_t1_pct=round(o_t1,2), obs_swf_t2_pct=round(o_t2,2), pred_swf_t2_pct=round(p_t2,2),
    obs_shift_pts=round(o_shift,3), pred_shift_pts=round(p_shift,3),
    bias_swf_pts=round(bias,3),
    dir_correct = sign(o_shift)==sign(p_shift),
    shift_ratio = round(ifelse(abs(o_shift)>1e-6, p_shift/o_shift, NA_real_),3),
    obs_sf_t1_pct=round(sf_o_t1,2), obs_sf_t2_pct=round(sf_o_t2,2), pred_sf_t2_pct=round(sf_p_t2,2),
    bias_sf_pts=round(100*mean(SFF_p - SFF_o),3),
    obs_hw_t2_pct=round(hw_o_t2,2), pred_hw_t2_pct=round(hw_p_t2,2),
    bias_hw_pts=round(100*mean(HWF_p - HWF_o),3))
}, by=.(model, stratum)]
summ[, stratum := factor(stratum, levels=c("Pooled","Softwood","Mixedwood","Hardwood"))]
setorder(summ, model, stratum)

fwrite(summ, "species_composition_over_time_frozen.csv")
# per-stand aggregates (softwood BA fraction only) for the figure / Python fallback
fwrite(D[, .(STAND, PROV, fortype, model,
             swf_t1=round(100*SWF_t1,4), swf_o=round(100*SWF_o,4), swf_p=round(100*SWF_p,4))],
       "species_composition_perstand_frozen.csv")
cat("\n===== SUMMARY (softwood BA fraction, percent; bias in percentage points) =====\n")
print(summ[,.(model,stratum,n,obs_swf_t1_pct,obs_swf_t2_pct,pred_swf_t2_pct,
              obs_shift_pts,pred_shift_pts,bias_swf_pts,dir_correct,shift_ratio)], row.names=FALSE)

# ================= FIGURE (advanced-viz grade) =================
pal <- c(Softwood="#1B9E9E", Mixedwood="#B08A3E", Hardwood="#E15554")
theme_p <- theme_minimal(base_size=11, base_family="sans") +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_line(colour="grey92", linewidth=0.3),
        plot.background=element_rect(fill="white", colour=NA),
        panel.background=element_rect(fill="white", colour=NA),
        strip.text=element_text(face="bold", size=11),
        axis.title=element_text(size=11), plot.title=element_text(face="bold", size=13),
        plot.subtitle=element_text(size=10, colour="grey30"),
        legend.position="bottom")

dpt <- copy(D); dpt[, `:=`(obs=100*SWF_o, prd=100*SWF_p, ftype=factor(fortype,
                 levels=c("Softwood","Mixedwood","Hardwood")))]
lab <- summ[stratum=="Pooled", .(model, bias_swf_pts,
             pctdir = NA_real_)]
# per-panel share of stands with correct direction of change
dirshare <- dpt[, .(pctdir=round(100*mean(sign(SWF_o-SWF_t1)==sign(SWF_p-SWF_t1)),0),
                    bias=round(100*mean(SWF_p-SWF_o),1)), by=model]
dirshare[, txt := sprintf("bias %+0.1f pts\ndir OK %d%%", bias, pctdir)]

pA <- ggplot(dpt, aes(obs, prd)) +
  geom_abline(slope=1, intercept=0, colour="grey45", linewidth=0.5, linetype="22") +
  geom_point(aes(colour=ftype), size=1.1, alpha=0.55) +
  geom_text(data=dirshare, aes(x=4, y=96, label=txt), hjust=0, vjust=1,
            size=3.1, colour="grey20", lineheight=0.95) +
  facet_wrap(~model, nrow=1) +
  scale_colour_manual(values=pal, name="Forest type") +
  coord_equal(xlim=c(0,100), ylim=c(0,100)) +
  labs(x="Observed softwood fraction at t2 (%)",
       y="Predicted softwood fraction at t2 (%)",
       title="Predicted versus observed softwood basal-area fraction at remeasurement",
       subtitle="Frozen FVS-ACD benchmark, MagPlot QC and NB remeasured stands (n = 680 classifiable of the frozen 705). Dashed line is 1:1.") +
  theme_p

# Panel B: mean softwood-fraction shift t1 to t2, observed vs each model, by forest type
shiftdt <- summ[stratum!="Pooled", .(model, stratum, pred_shift_pts)]
obsshift <- unique(summ[stratum!="Pooled", .(stratum, obs_shift_pts)])
mpal <- c("v12.5.0"="#4C72B0","v12.7.0"="#55A868","v12.10.1"="#C44E52","OSM"="#8172B3")
pB <- ggplot() +
  geom_hline(yintercept=0, colour="grey55", linewidth=0.4) +
  geom_col(data=obsshift, aes(x=stratum, y=obs_shift_pts), width=0.62,
           fill="grey82", colour="grey55", linewidth=0.3) +
  geom_point(data=shiftdt, aes(x=stratum, y=pred_shift_pts, colour=model),
             position=position_dodge(width=0.6), size=2.6) +
  scale_colour_manual(values=mpal, name="Model prediction") +
  labs(x="Forest type", y="Softwood fraction shift t1 to t2 (pts)",
       title="Observed versus predicted compositional shift",
       subtitle="Grey bar = observed mean shift; points = model-predicted mean shift.") +
  theme_p

fig <- pA / pB + plot_layout(heights=c(1.15,1)) +
  plot_annotation(theme=theme(plot.background=element_rect(fill="white", colour=NA)))

ggsave("fig9_species_composition_over_time.png", fig, width=11, height=8.4, dpi=300, bg="white")
ggsave("fig9_species_composition_over_time_thumb.png", fig, width=7.3, height=5.6, dpi=72, bg="white")
cat("\nWROTE fig9_species_composition_over_time.png + thumb + species_composition_over_time_frozen.csv\nDONE_COMP\n")
