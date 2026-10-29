## PREREG14 common code: paths, hard stops, the runner's own volume code (verbatim from runner md5 300a0d61),
## the form/risk split id map, the QC harvest screen and a stand cluster bootstrap. Diagnostic only. No em dashes.
suppressMessages(library(data.table)); options(width = 220, datatable.print.nrows = 300)
set.seed(20260926)
J <- Sys.getenv("P14_ROOT", "/home/aaron/jobs/v142p14"); IN <- file.path(J, "in")
OUT <- Sys.getenv("P14_OUT", file.path(J, "tables")); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
SMOKE_N <- as.integer(Sys.getenv("P14_SMOKE_N", "0")); NBOOT <- as.integer(Sys.getenv("P14_NBOOT", "2000"))
DSTAMP <- format(Sys.Date())
cat(sprintf("p14 R %s data.table %s OUT=%s SMOKE_N=%d NBOOT=%d\n", getRversion(), packageVersion("data.table"), OUT, SMOKE_N, NBOOT))
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n")
  cat(m, "\n", file = file.path(OUT, "_hardstop.txt"), append = TRUE); quit(save = "no", status = 3) }
wout <- function(x, nm) { f <- file.path(OUT, sprintf("gyr142-p14-%s_DATA_%s.csv", nm, DSTAMP)); fwrite(x, f); cat(sprintf("wrote %s (%d rows)\n", basename(f), nrow(x))) }
AFAC <- c(NB = 0.579, QC = 0.111)
cls3 <- function(d) cut(d, c(-Inf, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))
eqna <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)

## ---- verbatim from the runner: species codes, himp, NSVB emulator ----------------------------
co <- fread(file.path(IN, "ref/nsvb_emulator_coefs.csv")); sp2g <- fread(file.path(IN, "ref/spcd_spgrpcd.csv"))
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=125,BC=762,PR=761,ST=315,HH=701,SB=372,RB=370,AS=541,SW=299,HW=998,OH=998,OS=299,PC=761)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD)
if (anyDuplicated(sp2g$SPCD)) hs("spcd_spgrpcd.csv has duplicated SPCD keys")
spcd2grp<-setNames(sp2g$SPGRPCD, as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD, function(s){ g<-spcd2grp[as.character(s)]; if(is.na(g)) 998L else as.integer(g) })
ci<-match(agy_grp, co$SPGRPCD); ci[is.na(ci)]<-match(998, co$SPGRPCD); ci[is.na(ci)]<-1
RESP<-c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"); CF<-list()
for(r in RESP) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),
  b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
nsvb<-function(agy,dbh_cm,ht_m,resp){
  ht<-ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm))
  lX<-log((dbh_cm/2.54)^2*(ht/0.3048))
  a<-CF[[resp]]$a[agy]; b<-CF[[resp]]$b[agy]; sm<-CF[[resp]]$sm[agy]
  y<-sm*exp(a+b*lX); y[!is.finite(y)]<-0; unname(y)
}
FT3_M3<-0.0283168
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
## TOTVOL exactly as metrics(): live filter, then sum(nsvb(VOLCFGRS) * expf) * FT3_M3
totvol <- function(sp, dbh, ht, expf, mindbh) { live <- is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0
  if (!any(live)) return(0); sum(nsvb(sp[live], dbh[live], ht[live], "VOLCFGRS") * expf[live]) * FT3_M3 }

## ---- form/risk split id map (hw_formrisk_split.R md5 0b604bab, prune 0.03 as called by the runner) ----
.SPLIT_QUIET <- TRUE; source(file.path(IN, "ref/hw_formrisk_split.R"))
subw <- lapply(setNames(rownames(.pform), rownames(.pform)), function(key) { Jm <- outer(.pform[key, ], .prisk[key, ]); Jm[Jm < 0.03] <- 0
  if (sum(Jm) == 0) Jm <- outer(.pform[key, ], .prisk[key, ]); Jm <- Jm / sum(Jm); idx <- which(Jm > 0, arr.ind = TRUE); Jm[idx] })
## F: frame t1 rows with STAND, row0 (runner tree id before the split), sp (mapped), DBH, EXPF
split_map <- function(F) {
  F <- copy(F); F[, n0 := .N, by = STAND]; F[, is_hw := toupper(sp) %in% .a9$sp]
  a <- F[is_hw == FALSE, .(STAND, tree = row0, row0, sp, dbh = DBH, expf = EXPF, hw = FALSE)]
  h <- F[is_hw == TRUE][, key := fifelse(toupper(sp) %in% HW_SPP, toupper(sp), "OH")]
  h[, k := lengths(subw[key])]; hx <- h[rep(seq_len(.N), k)]; hx[, j := seq_len(.N), by = .(STAND, row0)]
  hx[, w := mapply(function(kk, jj) subw[[kk]][jj], key, j)]; setorder(hx, STAND, row0, j)
  hx[, tree := n0 + seq_len(.N), by = STAND]
  rbind(a, hx[, .(STAND, tree, row0, sp, dbh = DBH, expf = EXPF * w, hw = TRUE)])
}
## a check of split_map against the real split_formrisk on a few stands (the full check is against the runner list)
split_selftest <- function(F, nst = 3) { for (s in head(unique(F$STAND), nst)) { f <- F[STAND == s]
  cur <- data.frame(plot = 1L, tree = f$row0, sp = f$sp, dbh = f$DBH, ht = NA_real_, expf = f$EXPF, stringsAsFactors = FALSE)
  r <- as.data.table(split_formrisk(cur)); m <- split_map(f)
  x <- merge(r[, .(tree, sp, expf)], m[, .(tree, sp2 = sp, expf2 = expf)], by = "tree", all = TRUE)
  if (nrow(x) != nrow(r) || nrow(x) != nrow(m) || any(x$sp != x$sp2) || any(abs(x$expf - x$expf2) > 1e-9)) hs("split_map differs from split_formrisk on stand %s", s) }
  cat(sprintf("split_map self test ok on %d stands\n", nst)) }

## ---- QC harvest screen, rule verbatim from recs/diag3/2026-09-26_v142_qcscreen_nsvol.R ----------
trt <- fread(file.path(IN, "magp/p14_magp_treatment_DATA_2026-09-26.csv"), colClasses = list(character = "magp_site_id"))
cut_stands <- function(p) { p <- copy(p)[, site := substr(as.character(PLOTKEY), 1, 8)]
  trt[p, on = .(magp_site_id = site), allow.cartesian = TRUE, nomatch = 0L][substr(treatment_type, 1, 1) == "C" & treatment_year > Y1 & treatment_year <= Y2, unique(STAND)] }

## ---- stand cluster bootstrap of a ratio of sums ------------------------------------------------
bratio <- function(st, num, den, B = NBOOT) {
  a <- data.table(st = st, num = num, den = den)[, .(n = sum(num), d = sum(den)), by = st]
  est <- sum(a$n) / sum(a$d); k <- nrow(a); if (B < 1 || k < 2) return(c(est, NA_real_, NA_real_))
  idx <- matrix(sample.int(k, k * B, replace = TRUE), nrow = k)
  bs <- colSums(matrix(a$n[idx], nrow = k)) / colSums(matrix(a$d[idx], nrow = k))
  c(est, quantile(bs, c(0.025, 0.975), names = FALSE, na.rm = TRUE)) }
## level or ratio summary of tree rows d with columns STAND, obs, pred
levsum <- function(d, obs, pred) { if (!nrow(d)) return(data.table(trees = 0L, stands = 0L))
  b <- bratio(d$STAND, d[[pred]], d[[obs]])
  data.table(trees = nrow(d), stands = uniqueN(d$STAND), obs_mean = mean(d[[obs]]), pred_mean = mean(d[[pred]]),
             ratio = b[1], lo95 = b[2], hi95 = b[3], mean_pct_diff = mean(100 * (d[[pred]] - d[[obs]]) / d[[obs]]),
             thin = nrow(d) < 30 | uniqueN(d$STAND) < 10) }
