# Regenerate F2 (mgmt centerpiece) and F3 (concept + gap closure) with the robust additive re-fit.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(ggplot2); library(patchwork)})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
OUT <- "figs_v1210"; dir.create(OUT, showWarnings=FALSE)
crsf_green<-"#1a3d28"; crsf_gold<-"#c5a55a"
theme_pub <- theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),legend.position="bottom",
  plot.title=element_text(size=14,face="bold"),plot.subtitle=element_text(size=10,colour="grey30"),plot.margin=margin(10,10,10,10))
sv <- function(p,f,w,h) ggsave(file.path(OUT,f),p,width=w,height=h,units="cm",dpi=300,bg="white")
W <- readRDS("Wfull.rds"); setDT(W)
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
dg <- c("BA","SDI","QMD","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
tmean <- function(x) mean(x,trim=0.10,na.rm=TRUE)
# robust additive release, overwrite v1210.* in W
for(cl in c("PLANTED","PCT")){ i<-W$mgmt==cl
  rl <- sapply(dg, function(m) tmean((W[[paste0(m,"_o")]]-W[[paste0(m,"_t1")]])[i]-(W[[paste0("v129x.",m)]]-W[[paste0(m,"_t1")]])[i]))
  for(m in dg) W[[paste0("v1210.",m)]][i] <- W[[paste0("v129x.",m)]][i] + rl[m] }
biaspct <- function(mdl,m,idx) 100*(mean(W[[paste0(mdl,".",m)]][idx],na.rm=TRUE)/mean(W[[paste0(m,"_o")]][idx],na.rm=TRUE)-1)
managed_idx <- which(W$mgmt %in% c("PLANTED","PCT"))
idxof <- function(cls) if(cls=="MANAGED") managed_idx else which(W$mgmt==cls)

## F2 centerpiece
cls_levels<-c("NONE","PLANTED","PCT","MANAGED")
cls_lab<-c(NONE="Unmanaged\n(n=266)",PLANTED="Planted\n(n=51)",PCT="PCT\n(n=95)",MANAGED="All managed\n(n=146)")
f2d<-rbindlist(lapply(cls_levels,function(cls){idx<-idxof(cls)
  data.table(class=cls,model=c("v12.9.x","v12.10.1","OSM"),
    bias=c(biaspct("v129x","TOTVOL",idx),biaspct("v1210","TOTVOL",idx),biaspct("osm","TOTVOL",idx)))}))
f2d[,class:=factor(class,levels=cls_levels,labels=cls_lab[cls_levels])]
f2d[,model:=factor(model,levels=c("v12.9.x","v12.10.1","OSM"))]
f2<-ggplot(f2d,aes(class,bias,fill=model))+geom_col(position=position_dodge(0.72),width=0.66)+
  geom_hline(yintercept=0,colour="grey40")+
  geom_text(aes(label=sprintf("%+.1f",bias)),position=position_dodge(0.72),vjust=ifelse(f2d$bias>=0,-0.4,1.2),size=3)+
  scale_fill_manual(values=c("v12.9.x"="#3f7d57","v12.10.1"="#1a3d28","OSM"="#c5773a"),name=NULL)+
  labs(title="Management modifiers close the managed-stand gap to OSM",
    subtitle="Total-volume level bias by class. v12.10.1 uses a robust additive direct-effect release (planted +3.8, PCT +2.4 m2/ha BA).",
    x=NULL,y="Total-volume level bias (%)")+theme_pub
sv(f2,"F2_mgmt_centerpiece.png",22,14)

## F3 concept (engine multiplier form) + gap closure (robust)
tst<-seq(0,40,0.5)
cd<-rbind(data.table(type="PCT (Type 1, transient)",tst=tst,mult=1+1.0*exp(-0.03*tst)),
          data.table(type="Planted (Type 2, sustained)",tst=tst,mult=2.0))
p3a<-ggplot(cd,aes(tst,mult,colour=type))+geom_line(linewidth=1.2)+
  scale_colour_manual(values=c("PCT (Type 1, transient)"=crsf_gold,"Planted (Type 2, sustained)"=crsf_green),name=NULL)+
  geom_hline(yintercept=1,linetype=2,colour="grey50")+
  labs(title="A) Direct-effect form (Ch 11), robust re-fit",subtitle="Engine diameter-growth effect; amplitude from the additive release, clamp removed.",
    x="Years since treatment",y="Diameter-growth multiplier")+theme_pub
gc<-fread("mgmt_gap_closure_robust.csv")
gc[,class:=factor(class,levels=c("PLANTED","PCT","MANAGED"))]
gcl<-melt(gc[,.(class,`v12.9.x`=mae_v129x,`v12.10.1`=mae_v1210,OSM=mae_osm)],id.vars="class",variable.name="model",value.name="mae")
gcl[,model:=factor(model,levels=c("v12.9.x","v12.10.1","OSM"))]
p3b<-ggplot(gcl,aes(class,mae,fill=model))+geom_col(position=position_dodge(0.72),width=0.66)+
  geom_text(aes(label=sprintf("%.1f",mae)),position=position_dodge(0.72),vjust=-0.3,size=3)+
  scale_fill_manual(values=c("v12.9.x"="#3f7d57","v12.10.1"="#1a3d28","OSM"="#c5773a"),name=NULL)+
  labs(title="B) Mean absolute bias across 9 metrics",subtitle="In-sample; cross-validated out of fold: managed 1.4 (LOIO), 1.5 (LOPO).",x=NULL,y="Mean |level bias| (%)")+theme_pub
f3<-p3a+p3b+plot_layout(widths=c(1,1.1))
sv(f3,"F3_mgmt_concept_gap.png",26,12)
cat("F2/F3 regenerated\n")
