suppressMessages({library(data.table)})
options(warn=1)
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
BASE1 <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
BASE2 <- "/users/PUOM0008/crsfaaron/magplot/verify/p5m"

# Reuse the exact HW/SW call from AcadianGY_13.1_DRAFT.r's sp.attr table (verbatim species list),
# rather than inventing a new hardwood/softwood classification.
sp.attr <- fread(text = "
species,sp.type
AB,HW
AS,HW
BA,HW
BC,HW
BF,SW
BP,HW
BS,SW
BT,HW
EC,HW
EH,SW
GA,HW
GB,HW
HH,HW
JP,SW
NS,SW
OH,HW
OS,SW
PB,HW
PC,HW
PR,HW
QA,HW
RB,HW
RM,HW
RP,SW
RN,SW
RO,HW
RS,SW
SB,HW
SM,HW
ST,HW
TA,SW
WA,HW
WC,SW
WP,SW
WS,SW
YB,HW
")
cat("sp.attr rows:", nrow(sp.attr), "\n")

sources <- list(
  ctrn = list(base=BASE1, tag="ctrn", juris="ME"),
  pef = list(base=BASE1, tag="pef", juris="ME"),
  baxter = list(base=BASE1, tag="baxter", juris="ME"),
  silc = list(base=BASE1, tag="silc", juris="ME"),
  silc_l = list(base=BASE1, tag="silc_l", juris="ME"),
  silc137 = list(base=BASE1, tag="silc137", juris="ME"),
  ns = list(base=BASE1, tag="ns", juris="NS"),
  ns_long = list(base=BASE1, tag="ns_long", juris="NS"),
  mefia = list(base=BASE1, tag="mefia", juris="ME"),
  mefia_long = list(base=BASE1, tag="mefia_long", juris="ME"),
  mefia_subp = list(base=BASE1, tag="mefia_subp", juris="ME")
)

fortype_list <- list()
for (nm in names(sources)) {
  s <- sources[[nm]]
  f1 <- file.path(s$base, paste0("bench_", s$tag, "_tree_init.csv"))
  if (!file.exists(f1)) next
  t1 <- fread(f1)
  t1 <- t1[is.finite(DBH) & is.finite(EXPF) & EXPF>0]
  t1[, ba := pi/4 * (DBH/100)^2 * EXPF]  # m2/ha per tree record
  t1 <- merge(t1, sp.attr, by.x="SP", by.y="species", all.x=TRUE)
  n_unmatched <- sum(is.na(t1$sp.type))
  if (n_unmatched > 0) cat(nm, ": ", n_unmatched, " rows with unmatched species code (", 
                           paste(unique(t1$SP[is.na(t1$sp.type)]), collapse=","), "), excluded from BA totals\n", sep="")
  agg <- t1[!is.na(sp.type), .(ba_hw = sum(ba[sp.type=="HW"]), ba_sw = sum(ba[sp.type=="SW"])), by=STAND]
  agg[, ba_tot := ba_hw + ba_sw]
  agg[, pct_hw := ba_hw/ba_tot]
  agg[, fortype := fifelse(pct_hw >= 0.67, "HW_dominated", fifelse(pct_hw <= 0.33, "SW_dominated", "Mixedwood"))]
  agg[, source := nm][, juris := s$juris]
  fortype_list[[nm]] <- agg[, .(STAND, source, juris, pct_hw, fortype)]
}
fortype_dt <- rbindlist(fortype_list, fill=TRUE)
cat("=== forest type counts by source ===\n")
print(fortype_dt[, .N, by=.(source, fortype)][order(source, fortype)])

allm <- fread(file.path(OUT, "garcia_stand_pairs_2026-08-26.csv"))
allm[, mort_frac := 1 - N2/N1]
allm2 <- merge(allm, fortype_dt, by=c("STAND","source"), all.x=TRUE)
cat("rows before/after fortype join:", nrow(allm), nrow(allm2), " unmatched fortype:", sum(is.na(allm2$fortype)), "\n")
fwrite(allm2, file.path(OUT, "garcia_stand_pairs_with_fortype_2026-08-26.csv"))

cat("=== pooled n by fortype (mortality-bearing pairs) ===\n")
print(allm2[mort_frac>0.005, .N, by=fortype])
cat("=== pooled n by jurisdiction (mortality-bearing pairs) ===\n")
print(allm2[mort_frac>0.005, .N, by=juris])
cat("DONE_FORTYPE_PREP\n")
