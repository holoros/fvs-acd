## PREREG37 independent F9 verifier, written from the plan. No coordinates read; no identifiers printed. No em dashes.
suppressMessages({ library(data.table); library(digest) })
J <- "/home/aaron/jobs/v142p37"; V <- file.path(J, "verify_20261001"); P19 <- "/home/aaron/jobs/v142p19"
md5 <- function(f) unname(tools::md5sum(f))
cat("plan md5", md5(file.path(J, "plan/2026-10-01_v142_qc-height-structure_PREREG37.md")), "\n")
HK <- "/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R"; cat("helper md5", md5(HK), "\n")
source(HK)
FR_ROW <- FR; FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"
cat("row frames init md5", md5(file.path(FR_ROW, "bench_gyr_qc_c_tree_init.csv")), " t2", md5(file.path(FR_ROW, "bench_gyr_qc_c_tree_t2.csv")), "\n")
cat("field frames init md5", md5(file.path(FR_FIELD, "bench_gyr_qc_c_tree_init.csv")), " t2", md5(file.path(FR_FIELD, "bench_gyr_qc_c_tree_t2.csv")), "\n")
## claim 2: population
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
S0 <- stand_frame(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), "qc_c", CUTF)
cat("RUN_OK stands", nrow(S0), " cut TRUE", sum(S0$cut), "\n")
S0 <- S0[cut == FALSE]
fchk <- S0[, .(f2 = ifelse(strtoi(substr(vapply(as.character(SITE), digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"), fold)]
cat("fold rule recheck mismatches", sum(fchk$f2 != fchk$fold), "\n")
print(S0[, .(stands = .N, sites = uniqueN(SITE)), by = fold][order(fold)])
for (f in c("A", "B")) { L <- fread(file.path(J, sprintf("tables/gyr142-p37-stands_SERVERONLY_fold%s_2026-10-01.csv", f)))
  cat("driver stand list fold", f, "n", nrow(L), "setequal with rebuild", setequal(as.character(L$STAND), S0[fold == f]$STAND), "\n") }
## frame alignment field vs row (records, order)
for (w in c("init", "t2")) { a <- fread(file.path(FR_ROW, sprintf("bench_gyr_qc_c_tree_%s.csv", w)), select = c("STAND","SP","DBH","HT","EXPF"))
  b <- fread(file.path(FR_FIELD, sprintf("bench_gyr_qc_c_tree_%s.csv", w)), select = c("STAND","SP","DBH","HT","EXPF"))
  cat("frame", w, "rows", nrow(a), nrow(b), "identical non TREE cols", isTRUE(all.equal(a, b, check.attributes = FALSE)), "\n") }
## capture tables
SPP <- fread(file.path(J, "tables/gyr142-p37-dhtspp_DATA_2026-10-01.csv")); setnames(SPP, c("sp", "b0s", "b2s"))
b0 <- -2.19445331289132; b1 <- 0.42640409105239; b2 <- -0.0647071404836054; b3 <- 0.394836682501739; b4 <- -0.0114287748735248; b7 <- 0.00029415038133825
CAP <- rbindlist(lapply(c("A", "B"), function(f) fread(file.path(J, sprintf("tables/gyr142-p37-dhtcap_SERVERONLY_fold%s_2026-10-01.csv", f)))[, cfold := f]))
CAP[, STAND := as.character(STAND)]
SPP[, sp := as.character(sp)]
CAP <- merge(CAP, SPP, by = "sp", all.x = TRUE); cat("capture rows with sp not in dht.spp (engine nomatch -> species 99):", sum(is.na(CAP$b0s)), "\n")
CAP[is.na(b0s), `:=`(b0s = SPP[sp == "99"]$b0s, b2s = SPP[sp == "99"]$b2s)]; cat("capture rows", nrow(CAP), " missing spp", sum(is.na(CAP$b0s)), " dht_mult != 1:", sum(CAP$dht_mult != 1), "\n")
CAP[, `:=`(P = b0 + b0s + b1 * log(ht) + (b2 + b2s) * ht, M = b3 * cr + b4 * ccfl / 100, E = b7 * csi^2)]
CAP[, d0 := exp(P + M + E)]; CAP[, rel := abs(d0 / dht_out - 1)]
CAP[, okrec := (d0 + ht <= 50) & is.finite(rel) & rel <= 1e-9]
print(CAP[, .(rows = .N, capped = sum(d0 + ht > 50), fail = sum(!okrec), maxrel = max(rel[d0 + ht <= 50])), by = cfold])
stc <- CAP[, .N, by = .(cfold, STAND)]; cat("capture stands per fold:", paste(stc[, .N, by = cfold][, paste(cfold, N)], collapse = "; "), "\n")
## tag keys
mk <- function(fr, lab) { FR <<- fr; TK <- tag_key("qc_c", S0$STAND); FR <<- FR_ROW
  K <- merge(TK$K, S0[, .(STAND, SITE, fold)], by = "STAND"); K[, tagkey := lab]; K }
KF <- mk(FR_FIELD, "field"); KR <- mk(FR_ROW, "row")
cat("tag key records before capture join: field", paste(KF[, .N, by = fold][order(fold), paste(fold, N)], collapse = " "), "| row", paste(KR[, .N, by = fold][order(fold), paste(fold, N)], collapse = " "), "\n")
## map capture tree -> row0 through the run frame split map
FR <- FR_ROW; Fr <- fread(file.path(FR_ROW, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% S0$STAND]
Fr[, sp := mapsp(SP)]; MAP <- split_map(Fr)
C2 <- merge(CAP, MAP[, .(STAND, tree, row0, msp = sp, mdbh = dbh)], by = c("STAND", "tree"), all.x = TRUE)
cat("capture rows unmapped", sum(is.na(C2$row0)), " dbh mismatch", sum(abs(C2$dbh - C2$mdbh) > 1e-8, na.rm = TRUE), "\n")
PR <- C2[, .(p0 = mean(dht_out), ht0 = mean(ht), allok = all(okrec), iv = iv[1], nparts = .N), by = .(STAND, row0)]
build <- function(K) { X <- merge(K, PR, by = c("STAND", "row0"))
  cat(K$tagkey[1], "joined", nrow(X), " of", nrow(K), " ht != H1:", sum(abs(X$ht0 - X$H1) > 1e-8), " recon fail dropped:", sum(!X$allok), "\n")
  X <- X[allok == TRUE]; X[, obs := (H2 - H1) / iv]
  X[, dcl := fifelse(D1 < 12.7, "lt12.7", fifelse(D1 < 25, "12.7to25", "ge25"))]; X }
XF <- build(KF); XR <- build(KR); X <- rbind(XF, XR, fill = TRUE)
cat("CLAIM3 records: field", paste(XF[, .N, by = fold][order(fold), paste(fold, N)], collapse = " "), "| row", paste(XR[, .N, by = fold][order(fold), paste(fold, N)], collapse = " "), "\n")
## R and bootstrap (site cluster, one draw matrix per fold, seed 20261001)
out <- list()
for (f in c("A", "B")) {
  sites <- sort(unique(S0[fold == f]$SITE)); ns <- length(sites); set.seed(20261001)
  W <- t(replicate(1000, tabulate(sample.int(ns, ns, replace = TRUE), ns)))
  for (k in c("field", "row")) { D <- X[fold == f & tagkey == k]
    grp <- list(all = rep(TRUE, nrow(D)), lt12.7 = D$dcl == "lt12.7", `12.7to25` = D$dcl == "12.7to25", ge25 = D$dcl == "ge25", lt25 = D$D1 < 25)
    Rb <- list()
    for (g in names(grp)) { d <- D[grp[[g]]]; so <- d[, sum(obs), by = SITE]; sp <- d[, sum(p0), by = SITE]
      vo <- numeric(ns); vo[match(so$SITE, sites)] <- so$V1; vp <- numeric(ns); vp[match(sp$SITE, sites)] <- sp$V1
      Rp <- sum(d$obs) / sum(d$p0); bb <- as.vector(W %*% vo) / as.vector(W %*% vp); Rb[[g]] <- bb
      out[[length(out) + 1]] <- data.table(fold = f, tagkey = k, stat = "R", group = g, n = nrow(d), sum_obs = sum(d$obs), sum_p0 = sum(d$p0), est = Rp, lo = quantile(bb, .025, na.rm = TRUE), hi = quantile(bb, .975, na.rm = TRUE)) }
    Sp <- out[[length(out)]]$est / out[[length(out) - 1]]$est; Sb <- Rb$lt25 / Rb$ge25
    out[[length(out) + 1]] <- data.table(fold = f, tagkey = k, stat = "S", group = "lt25/ge25", n = nrow(D), sum_obs = NA, sum_p0 = NA, est = Sp, lo = quantile(Sb, .025, na.rm = TRUE), hi = quantile(Sb, .975, na.rm = TRUE)) } }
RES <- rbindlist(out); options(width = 200); print(RES[, .(fold, tagkey, stat, group, n, est = round(est, 4), lo = round(lo, 3), hi = round(hi, 3))])
## claim 5 seedling
SD <- fread(file.path(J, "tables/gyr142-p37-seedling-afac1_DATA_2026-10-01.csv"))
cat("seedling raw md5", md5(file.path(J, "tables/gyr142-p37-seedling-afac1_DATA_2026-10-01.csv")), " run_ok all", all(SD$run_ok == 1), "\n")
s1 <- SD[age %in% c(25, 50), .(src = "p37_raw", arm, cell, esi, age, HT, HTE = HT / esi)]
p31raw <- rbindlist(lapply(list.files("/home/aaron/jobs/v142p31/out", "^traj_(qc141|p28b_small)_(BF|MX)\\.csv$", full.names = TRUE), fread))[cell %in% SD$cell & age %in% c(25, 50), .(src = "p31_raw", arm, cell, esi, age, HT, HTE = HT / esi)]
p31a <- fread("/home/aaron/jobs/v142p31/assembled/gyr142-p31-traj-annual_DATA_2026-09-30.csv")[cell %in% SD$cell & age %in% c(25, 50) & arm %in% c("qc141", "p28b_small"), .(src = "p31_assembled", arm, cell, esi, age, HT, HTE = HT / esi)]
SEED <- rbind(s1, p31raw, p31a); setorder(SEED, cell, arm, age, src); print(SEED[, .(src, arm, cell, age, HT = round(HT, 3), HTE = round(HTE, 3))])
m <- merge(p31raw, p31a, by = c("arm", "cell", "age")); cat("p31 raw vs assembled max abs HT diff", max(abs(m$HT.x - m$HT.y)), "\n")
DATA <- rbind(RES[, .(section = "ratio", fold, tagkey, stat, group, n, sum_obs, sum_p0, est, lo, hi)],
  SEED[, .(section = "seedling", fold = NA, tagkey = src, stat = paste0("HT_age", age), group = paste(arm, cell), n = NA, sum_obs = HT, sum_p0 = esi, est = HTE, lo = NA, hi = NA)], fill = TRUE)
fwrite(DATA, file.path(V, "p37_verify_DATA_2026-10-01.csv"))

## ---- claim 6: comparison with assembled/ (read only after the numbers above were final) ----
A <- "/home/aaron/jobs/v142p37/assembled"; cmp <- list()
gm <- c(all = "all", lt12.7 = "below 12.7", `12.7to25` = "12.7 to 25", ge25 = "25 and over", lt25 = "below 25")
km <- c(field = "field tag", row = "row index")
for (f in c("A", "B")) { AR <- fread(file.path(A, sprintf("gyr142-p37-ratio-fold%s_DATA_2026-10-01.csv", f))); AS <- fread(file.path(A, sprintf("gyr142-p37-S-fold%s_DATA_2026-10-01.csv", f)))
  AC <- fread(file.path(A, sprintf("gyr142-p37-counts-fold%s_DATA_2026-10-01.csv", f)))
  for (k in names(km)) { r <- RES[fold == f & tagkey == k]
    for (g in names(gm)) { sch <- if (g == "all") "all" else if (g == "lt25") "size2" else if (g == "ge25") c("size2", "cls3") else "cls3"
      a <- AR[tagkey == km[k] & scheme %in% sch & group == gm[g]]
      for (i in seq_len(nrow(a))) cmp[[length(cmp) + 1]] <- data.table(fold = f, tagkey = k, item = paste("R", a$scheme[i], g), mine = r[stat == "R" & group == g]$est, theirs = a$R[i], n_mine = r[stat == "R" & group == g]$n, n_theirs = a$trees[i],
        lo_m = r[stat == "R" & group == g]$lo, lo_t = a$R_lo[i], hi_m = r[stat == "R" & group == g]$hi, hi_t = a$R_hi[i]) }
    a <- AS[tagkey == km[k]]; cmp[[length(cmp) + 1]] <- data.table(fold = f, tagkey = k, item = "S", mine = r[stat == "S"]$est, theirs = a$S, n_mine = r[stat == "S"]$n, n_theirs = AC[tagkey == km[k]]$records,
      lo_m = r[stat == "S"]$lo, lo_t = a$S_lo, hi_m = r[stat == "S"]$hi, hi_t = a$S_hi) } }
CMP <- rbindlist(cmp); CMP[, `:=`(dpt = abs(mine - theirs), dlo = abs(lo_m - lo_t), dhi = abs(hi_m - hi_t), dn = n_mine - n_theirs)]
print(CMP[, .(fold, tagkey, item, mine = signif(mine, 6), dpt = signif(dpt, 2), dn, dlo = signif(dlo, 2), dhi = signif(dhi, 2))])
cat("ratio/S comparisons", nrow(CMP), " max point diff", max(CMP$dpt), " n diffs", sum(CMP$dn != 0), " points > 1e-9:", sum(CMP$dpt > 1e-9), " max interval diff", max(c(CMP$dlo, CMP$dhi)), "\n")
AD <- fread(file.path(A, "gyr142-p37-seedling_DATA_2026-10-01.csv"))[age %in% c(25, 50)]
AD[, arm := fifelse(grepl("PREREG37", arm), "afac1", fifelse(grepl("qc141", arm), "qc141", "p28b_small"))]
sm <- merge(SEED[src != "p31_assembled"], AD[, .(arm, cell, age, HTa = HT, HTEa = HT_over_ESI)], by = c("arm", "cell", "age"))
cat("seedling comparisons", nrow(sm), " max HT diff", max(abs(sm$HT - sm$HTa)), " max HT/ESI diff", max(abs(sm$HTE - sm$HTEa)), "\n")
fwrite(CMP, file.path(V, "p37_verify_compare_DATA_2026-10-01.csv"))
cat("P37_VERIFY_DONE\n")
