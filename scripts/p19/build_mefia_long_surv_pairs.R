# build_mefia_long_surv_pairs.R -- pass 17: TRUE survivor pairs for the ME_FIA_L benchmark.
#
# WHY: bench_mefia_long_tree_init/t2 assign TREE := seq_len(.N) by STAND (build_mefia_long_bench.R
# line 122), independently at each endpoint. TREE therefore carries NO tree identity, and every
# survivor match made on STAND,TREE against these files (p14, p16, first p17 attempt) paired
# arbitrary rows: 59% of matched pairs disagree on species; 3380 "survivors" shrank from a median
# 18.5 cm to a median 5.1 cm. Combined with FIA's two-frame expansion (microplot 185.2432 vs
# subplot 14.8709 ha-1) this manufactured the phantom survivor increment behind the 34% Maine
# exclusion rate and, in all likelihood, the negative site coefficient investigated since pass 14.
#
# This script rebuilds the SAME chains and filters as build_mefia_long_bench.R (steps 1-5 copied
# verbatim so the stand set is identical), then matches trees by real FIA identity: pointer-jumping
# PREV_TRE_CN to a root tree CN, exactly as the plot chains jump PREV_PLT_CN. Output is a NEW file,
# bench_mefia_long_surv_pairs.csv; nothing existing is overwritten. Coordinates never leave the
# server; released columns are stand key, tree root CN, species, DBH, EXPF, years only.
# Validation logged: species agreement across the pair (expect ~99%), diameter sanity, match rates.
# Aaron Weiskittel, CRSF. 18 August 2026, OSC Cardinal.

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5","~/R/x86_64-pc-linux-gnu-library/4.4", .libPaths()))
suppressMessages({ library(data.table) })
FIA <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
ACRES_PER_HA <- 2.4710538147

## ---- 1. plot chains via PREV_PLT_CN (verbatim from build_mefia_long_bench.R) ----
pl <- fread(file.path(FIA,"ME_PLOT.csv"),
  select=c("CN","PREV_PLT_CN","MEASYEAR","LAT","LON","ELEV"))
pl[, CN:=as.character(CN)][, PREV_PLT_CN:=as.character(PREV_PLT_CN)]
pl[, prev := PREV_PLT_CN]
pl[prev %in% c("","NA") | is.na(prev), prev := NA_character_]
parent <- pl$prev
parent[!(parent %in% pl$CN)] <- NA_character_
names(parent) <- pl$CN
root <- pl$CN
for (i in 1:50) {
  p <- parent[root]
  moved <- !is.na(p)
  if (!any(moved)) break
  root[moved] <- p[moved]
}
pl[, root := root]
setorder(pl, root, MEASYEAR, CN)
chains <- pl[, .(first_cn=CN[1], last_cn=CN[.N], y1=MEASYEAR[1], y2=MEASYEAR[.N],
                 nmeas=.N, elev_last=ELEV[.N], lat_last=LAT[.N], lon_last=LON[.N]), by=root]
chains[, interval_years := y2 - y1]

## ---- 2. disturbance/treatment screen (verbatim) ----
co <- fread(file.path(FIA,"ME_COND.csv"),
  select=c("PLT_CN","CONDID","COND_STATUS_CD","DSTRBCD1","DSTRBCD2","DSTRBCD3",
           "TRTCD1","TRTCD2","TRTCD3"))
co[, PLT_CN := as.character(PLT_CN)]
for (cc in c("DSTRBCD1","DSTRBCD2","DSTRBCD3","TRTCD1","TRTCD2","TRTCD3"))
  set(co, which(is.na(co[[cc]])), cc, 0L)
cn2root <- setNames(pl$root, pl$CN)
co[, root := cn2root[PLT_CN]]
co <- co[!is.na(root)]
forcn <- unique(co[COND_STATUS_CD==1]$PLT_CN)
cof <- co[COND_STATUS_CD==1]
cof[, dstrb := (DSTRBCD1!=0 | DSTRBCD2!=0 | DSTRBCD3!=0)]
cof[, trt   := (TRTCD1!=0 | TRTCD2!=0 | TRTCD3!=0)]
cflag <- cof[, .(any_dstrb=any(dstrb), any_trt=any(trt), nforcond=.N), by=root]
chains <- merge(chains, cflag, by="root", all.x=TRUE)
chains[is.na(nforcond), nforcond := 0L]
chains[is.na(any_dstrb), any_dstrb := FALSE]
chains[is.na(any_trt),   any_trt := FALSE]
chains[, first_forest := first_cn %in% forcn]
chains[, last_forest  := last_cn  %in% forcn]

## ---- 3. filters (verbatim) ----
c2 <- chains[nmeas>=2 & interval_years>=1]
is_forest_ok <- c2$first_forest & c2$last_forest & c2$nforcond>0
cf <- c2[is_forest_ok]
keep <- cf[!any_trt & !any_dstrb]

## ---- 4. live-tree count screen (verbatim logic, needs tr loaded first) ----
tr <- fread(file.path(FIA,"ME_TREE.csv"),
  select=c("CN","PLT_CN","PREV_TRE_CN","SPCD","DIA","TPA_UNADJ","STATUSCD"))
tr[, CN := as.character(CN)][, PLT_CN := as.character(PLT_CN)][, PREV_TRE_CN := as.character(PREV_TRE_CN)]
trlive <- tr[STATUSCD==1 & is.finite(DIA) & DIA>0]
trlive[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ>0, TPA_UNADJ,
                        fifelse(DIA<5, 74.965, 6.018))]
ntr <- trlive[, .N, by=PLT_CN]; nlk <- setNames(ntr$N, ntr$PLT_CN)
keep[, n1 := nlk[first_cn]][, n2 := nlk[last_cn]]
keep <- keep[is.finite(n1) & is.finite(n2) & n1>=1 & n2>=1]
keep[, STAND := paste0("ME_L_", first_cn)]
cat(sprintf("final chains (must equal build_mefia_long_bench's 933): %d\n", nrow(keep)))

## ---- 5. TREE ancestry: pointer-jump PREV_TRE_CN to root tree CN ----
## Restrict to tree records on any plot CN inside the kept chains (all measurements, not just
## endpoints, so ancestry can hop through intermediate panels).
keeproots <- keep$root
chain_cns <- pl[root %in% keeproots, CN]
trc <- tr[PLT_CN %in% chain_cns]
cat(sprintf("tree records on kept chains (all panels, all status): %d\n", nrow(trc)))
tparent <- trc$PREV_TRE_CN
tparent[tparent %in% c("","NA")] <- NA_character_
tparent[!(tparent %in% trc$CN)] <- NA_character_
names(tparent) <- trc$CN
troot <- trc$CN
for (i in 1:50) {
  p <- tparent[troot]
  moved <- !is.na(p)
  if (!any(moved)) break
  troot[moved] <- p[moved]
}
trc[, troot := troot]

## ---- 6. survivor pairs: live at first_cn AND live at last_cn, same troot ----
SPCD_to_AGY <- c(
 "12"="BF","97"="RS","95"="BS","94"="WS","91"="NS","129"="WP","125"="RP","105"="JP",
 "261"="EH","241"="WC","71"="TA","316"="RM","318"="SM","371"="YB","375"="PB","379"="GB",
 "746"="QA","743"="BT","741"="BP","742"="EC","531"="AB","541"="WA","543"="BA","544"="GA",
 "833"="RO","762"="BC","761"="PR","315"="ST","701"="HH","391"="HH","935"="SB","370"="RB","68"="PC")
map_sp <- function(spcd){
  a <- SPCD_to_AGY[as.character(spcd)]
  ifelse(!is.na(a), a, ifelse(spcd>=300, "OH", "OS"))
}
first2stand <- setNames(keep$STAND, keep$first_cn)
last2stand  <- setNames(keep$STAND, keep$last_cn)
y1_of <- setNames(keep$y1, keep$STAND); y2_of <- setNames(keep$y2, keep$STAND)

t1r <- trc[PLT_CN %in% keep$first_cn & STATUSCD==1 & is.finite(DIA) & DIA>0]
t2r <- trc[PLT_CN %in% keep$last_cn  & STATUSCD==1 & is.finite(DIA) & DIA>0]
t1r[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ>0, TPA_UNADJ, fifelse(DIA<5, 74.965, 6.018))]
t2r[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ>0, TPA_UNADJ, fifelse(DIA<5, 74.965, 6.018))]
cat(sprintf("live trees at t1 endpoints: %d ; at t2 endpoints: %d\n", nrow(t1r), nrow(t2r)))

## a troot must be unique within each endpoint (a tree measured once per panel); enforce and log
d1 <- t1r[, .N, by=troot][N>1]; d2 <- t2r[, .N, by=troot][N>1]
cat(sprintf("ambiguous troot at t1: %d ; at t2: %d (dropped from matching)\n", nrow(d1), nrow(d2)))
t1u <- t1r[!troot %in% d1$troot]
t2u <- t2r[!troot %in% d2$troot]

mm <- merge(
  t1u[, .(troot, STAND = first2stand[PLT_CN], SPCD1=SPCD, D1=DIA*2.54, E1=tpa*ACRES_PER_HA)],
  t2u[, .(troot, STAND2 = last2stand[PLT_CN], SPCD2=SPCD, D2=DIA*2.54, E2=tpa*ACRES_PER_HA)],
  by="troot")
## the pair must belong to the same chain (t1 endpoint stand == t2 endpoint stand)
mm <- mm[STAND == STAND2][, STAND2 := NULL]
mm[, `:=`(SP1 = map_sp(SPCD1), SP2 = map_sp(SPCD2))]
mm[, `:=`(Y1 = y1_of[STAND], Y2 = y2_of[STAND])]

cat(sprintf("\nTRUE survivor pairs: %d (t1 live trees on matched stands: %d -> survivor fraction %.3f)\n",
    nrow(mm), nrow(t1u[PLT_CN %in% keep$first_cn]), nrow(mm)/nrow(t1u)))
cat(sprintf("VALIDATION species agreement (SPCD exact): %.4f ; (AGY code): %.4f\n",
    mm[, mean(SPCD1==SPCD2)], mm[, mean(SP1==SP2)]))
cat(sprintf("VALIDATION shrinking survivors D2<D1: %.4f (measurement noise expected, few %%)\n",
    mm[, mean(D2<D1)]))
cat("D1 quantiles:\n"); print(round(quantile(mm$D1, c(0,.05,.25,.5,.75,.95,1)),1))
cat("annual diameter increment (D2-D1)/interval quantiles (cm/yr):\n")
mm[, dbh_incr_ann := (D2-D1)/(Y2-Y1)]
print(round(quantile(mm$dbh_incr_ann, c(0,.01,.05,.25,.5,.75,.95,.99,1), na.rm=TRUE),3))
cat(sprintf("frame crossers (E1>100, E2<100): %d ; backcross (E1<100, E2>100): %d of %d\n",
    mm[, sum(E1>100 & E2<100)], mm[, sum(E1<100 & E2>100)], nrow(mm)))

out <- mm[, .(STAND, TROOT=troot, SP=SP1, SP2, D1=round(D1,2), D2=round(D2,2),
              E1=round(E1,4), E2=round(E2,4), Y1, Y2)]
fwrite(out, file.path(OUT, "bench_mefia_long_surv_pairs.csv"))
cat(sprintf("\nwrote %s/bench_mefia_long_surv_pairs.csv : %d rows, %d stands\n",
    OUT, nrow(out), uniqueN(out$STAND)))
