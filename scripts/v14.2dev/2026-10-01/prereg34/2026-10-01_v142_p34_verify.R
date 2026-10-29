## PREREG34 [F9] independent re-derivation: no source(), own fold code (openssl md5), own readers and joins. Recomputes
## the bin level ratios by arm (both sets, both folds), the fold B level of every subset in the materiality table, the
## residual check levels by program and class, the fold B Shapley totals and the frame contrast point value, and
## compares them with assembled/ at tolerance 1e-9. Bootstrap limits are not re-derived. No em dashes.
suppressMessages(library(data.table)); options(width = 200)
J <- "/home/aaron/jobs/v142p34"; V <- file.path(J, "verify_20261001"); A <- file.path(J, "assembled"); TOL <- 1e-9
P20 <- "/home/aaron/jobs/v142p20"; P22 <- "/home/aaron/jobs/v142p22"
FRM <- file.path(P20, "home/magplot/verify/gydbreg20260916/frames")
fold2 <- function(site) { h <- vapply(as.character(site), function(z) as.character(openssl::md5(z)), ""); ifelse(strtoi(substring(h, 1, 1), 16L) %% 2L == 0L, "A", "B") }
readpred <- function(home, arm, s) { dirs <- c(file.path(home, "out", arm, s), file.path(home, paste0("out_retry_a", 1:3), arm, s)); out <- data.table()
  for (d in dirs) { f <- list.files(d, pattern = "_pred_t2_tree[.]csv$", full.names = TRUE); f <- f[grepl("^c[0-9]+_", basename(f))]; if (!length(f)) next
    x <- rbindlist(lapply(sort(f), function(z) fread(z, select = c("STAND", "tree", "ht", "ing"), colClasses = list(character = "STAND"))))[ing == 0]
    out <- if (nrow(out)) rbind(out[!(STAND %chin% x$STAND)], x) else x }
  out[, id := paste(STAND, tree, sep = "#")][, .(id, ht)] }
cut3 <- function(d) fifelse(d < 12.7, "below 12.7", fifelse(d < 25, "12.7 to 25", "25 and over"))
ALL <- rbindlist(lapply(c("ns_long_c", "ns_long_fl"), function(s) {
  k <- fread(file.path(P20, "in/key", paste0("p20_htkey_", s, ".csv")), colClasses = list(character = "STAND")); k[, id := paste(STAND, tree, sep = "#")]
  f1 <- readpred(file.path(P20, "home"), "v141LTf", s); f2 <- readpred(file.path(P22, "home"), "v141LTfi", s)
  k[, pf := f1$ht[match(id, f1$id)]]; k[, pfi := f2$ht[match(id, f2$id)]]; stopifnot(!anyNA(k$pf), !anyNA(k$pfi))
  pr <- fread(file.path(FRM, paste0("bench_gyr_", s, "_pairs.csv")), colClasses = list(character = "STAND"))
  rs <- fread(file.path(P20, "results/v141LTf", paste0("gyr_v141LTf_", s, "_results.csv")), select = c("STAND", "esi8"), colClasses = list(character = "STAND"))
  ini <- fread(file.path(FRM, paste0("bench_gyr_", s, "_tree_init.csv")), colClasses = list(character = "STAND"))
  st1 <- ini[, .(hf = sum(is.finite(HT) & HT > 0) / .N, ex = first(EXPF)), keyby = STAND]
  t2 <- fread(file.path(FRM, paste0("bench_gyr_", s, "_tree_t2.csv")), colClasses = list(character = "STAND")); t2[, id2 := paste(STAND, TREE, sep = "@")]
  ix <- match(k$STAND, pr$STAND); stopifnot(!anyNA(ix))
  k[, `:=`(site = pr$SITE[ix], program = ifelse(startsWith(pr$PLOTKEY[ix], "NS_OP"), "NS_OP", ifelse(startsWith(pr$PLOTKEY[ix], "NS_RS"), "NS_RS", "other")),
           y1 = pr$Y1[ix], nl = pr$NLINKS[ix], sibl = grepl("sibling", pr$LINK_SRC[ix], fixed = TRUE), esrc = pr$ESI_SRC[ix], obsmin = pr$PLOT_OBS_MINDBH[ix],
           esi = rs$esi8[match(STAND, rs$STAND)], hf = st1$hf[match(STAND, st1$STAND)], ex = st1$ex[match(STAND, st1$STAND)])]
  j2 <- match(paste(k$STAND, k$TREE, sep = "@"), t2$id2); k[, `:=`(d2 = t2$DBH[j2], h2t = t2$HT[j2])]
  k[, fd := fold2(site)]; stopifnot(all(k$fd == k$fold)); k[, setname := s]; k }))
ALL[, c1 := cut3(D1)]; ALL[, ver := !is.na(h2t) & abs(h2t - H2) < 1e-9]; ALL[, crs := ver & cut3(d2) != c1]
lev <- function(X, p) sum(X[[p]]) / sum(X$H2); armcol <- c(v141LT = "Hp141", v141LTf = "pf", v141LTfi = "pfi")
CMP <- list(); add <- function(what, mine, theirs) CMP[[length(CMP) + 1L]] <<- data.table(check = what, mine = mine, assembled = theirs, absdiff = abs(mine - theirs))
ST <- fread(file.path(A, "gyr142-p34-subsets_DATA_2026-10-01.csv"))
## 1. bin level ratios by arm, both sets, both folds
for (s in c("ns_long_c", "ns_long_fl")) for (f in c("A", "B")) for (a in names(armcol)) {
  X <- ALL[setname == s & fd == f & iv >= 10 & iv < 20]; add(paste("bin", s, f, a), lev(X, armcol[[a]]), ST[set == s & fold == f & stratum == "all programs" & subset == "bin" & arm == a, level]) }
## 2. fold B subsets, all programs and within program, every arm (fl bin)
FL <- ALL[setname == "ns_long_fl" & fd == "B" & iv >= 10 & iv < 20]
et <- quantile(unique(FL[, .(STAND, esi)])$esi, c(1, 2) / 3, na.rm = TRUE)
defs <- list(`NS_OP` = quote(program == "NS_OP"), `NS_RS` = quote(program == "NS_RS"), `plot 400 m2 (EXPF 25)` = quote(abs(ex - 25) < 1e-9),
  `plot not 400 m2` = quote(abs(ex - 25) >= 1e-9), `observed floor 9.1 cm and over` = quote(obsmin >= 9.1), `observed floor below 9.1 cm` = quote(obsmin < 9.1),
  `all t1 heights measured` = quote(hf >= 1), `t1 heights subsampled` = quote(hf < 1), `drop below 12.7` = quote(c1 != "below 12.7"), `drop 12.7 to 25` = quote(c1 != "12.7 to 25"),
  `drop 25 and over` = quote(c1 != "25 and over"), `class below 12.7` = quote(c1 == "below 12.7"), `class 12.7 to 25` = quote(c1 == "12.7 to 25"), `class 25 and over` = quote(c1 == "25 and over"),
  `verified, non crossers` = quote(ver & !crs), `verified, crossers` = quote(ver & crs), `NLINKS 1` = quote(nl == 1), `NLINKS 2 and over` = quote(nl >= 2),
  `no sibling link` = quote(!sibl), `sibling link` = quote(sibl), `ESI cov30m` = quote(esrc == "cov30m"), `ESI old harness` = quote(esrc == "oldharness"),
  `Y1 before 1975` = quote(y1 < 1975), `Y1 1975 to 1984` = quote(y1 >= 1975 & y1 < 1985), `Y1 1985 and later` = quote(y1 >= 1985),
  `ESI lower tertile` = quote(esi < et[1]), `ESI middle tertile` = quote(esi >= et[1] & esi < et[2]), `ESI upper tertile` = quote(esi >= et[2]),
  `interval 10 to 14` = quote(iv < 15), `interval 15 to 19` = quote(iv >= 15))
for (pg in c("all programs", "NS_OP", "NS_RS")) { Z <- if (pg == "all programs") FL else FL[program == pg]
  for (nm in names(defs)) { Y <- Z[which(eval(defs[[nm]], Z, environment()))]; if (!nrow(Y)) next
    for (a in names(armcol)) { th <- ST[fold == "B" & set == "ns_long_fl" & stratum == pg & subset == nm & arm == a]
      if (nrow(th) != 1) { add(paste("missing row", pg, nm, a), NA_real_, NA_real_); next }
      add(paste("subset", pg, nm, a), lev(Y, armcol[[a]]), th$level); add(paste("trees", pg, nm, a), nrow(Y), th$trees) } } }
## 3. ns_long_c references by program and class, fold B
CB <- ALL[setname == "ns_long_c" & fd == "B" & iv >= 10 & iv < 20]
for (pg in c("all programs", "NS_OP")) { Z <- if (pg == "all programs") CB else CB[program == pg]
  for (a in names(armcol)) { add(paste("c ref", pg, a), lev(Z, armcol[[a]]), ST[fold == "B" & set == "ns_long_c" & stratum == pg & subset == "bin" & arm == a, level])
    for (cl in c("below 12.7", "12.7 to 25", "25 and over")) add(paste("c ref", pg, cl, a), lev(Z[c1 == cl], armcol[[a]]), ST[fold == "B" & set == "ns_long_c" & stratum == pg & subset == paste("class", cl) & arm == a, level]) } }
## 4. Shapley totals fold B (program, class, NLINKS, Y1 group), v141LTf
SHT <- fread(file.path(A, "gyr142-p34-shapley_DATA_2026-10-01.csv"))
CA <- ALL[setname == "ns_long_c" & fd == "B"]; FL[, y1grp := fifelse(y1 < 1975, 1L, fifelse(y1 < 1985, 2L, 3L))]; CB[, y1grp := fifelse(y1 < 1975, 1L, fifelse(y1 < 1985, 2L, 3L))]; CA[, y1grp := fifelse(y1 < 1975, 1L, fifelse(y1 < 1985, 2L, 3L))]
fmap <- c(prog = "program", cls = "c1", NLINKS = "nl", y1g = "y1grp")
for (fc in names(fmap)) { v <- fmap[[fc]]
  agg <- function(X) X[, .(h = sum(H2), p = sum(pf), n = .N), by = .(g = as.character(get(v)))]
  a <- agg(FL); b <- agg(CB); ca <- agg(CA); gs <- union(a$g, b$g); rbin <- sum(b$p) / sum(b$h)
  hf_ <- a$h[match(gs, a$g)]; hf_[is.na(hf_)] <- 0; pf_ <- a$p[match(gs, a$g)]; pf_[is.na(pf_)] <- 0
  hc_ <- b$h[match(gs, b$g)]; hc_[is.na(hc_)] <- 0; pc_ <- b$p[match(gs, b$g)]; pc_[is.na(pc_)] <- 0; nc_ <- b$n[match(gs, b$g)]; nc_[is.na(nc_)] <- 0
  rall <- ca$p[match(gs, ca$g)] / ca$h[match(gs, ca$g)]
  rc <- ifelse(nc_ >= 200, pc_ / hc_, rall); rc[!is.finite(rc)] <- rbin; rf <- pf_ / hf_; rf[!is.finite(rf)] <- rc[!is.finite(rf)]
  sf <- hf_ / sum(hf_); sc <- hc_ / sum(hc_); comp <- sum((sf - sc) * (rf + rc) / 2); wit <- sum((rf - rc) * (sf + sc) / 2)
  th <- SHT[fold == "B" & factor == fc]; add(paste("shapley composition", fc), comp, th$composition); add(paste("shapley within", fc), wit, th$within) }
## 5. frame contrast point value
FCt <- fread(file.path(A, "gyr142-p34-frame-contrast_DATA_2026-10-01.csv"))
add("frame contrast NS_OP", lev(FL[program == "NS_OP"], "pf") - lev(CB[program == "NS_OP"], "pf"), FCt$value)
CMP <- rbindlist(CMP); CMP[, fail := is.na(absdiff) | absdiff > TOL]
fwrite(CMP, file.path(V, "p34-verify-values_DATA_2026-10-01.csv"))
cat(sprintf("checks %d, failed %d, worst absolute difference %.3g\n", nrow(CMP), sum(CMP$fail), max(CMP$absdiff, na.rm = TRUE)))
if (any(CMP$fail)) print(CMP[fail == TRUE])
cat(sprintf("fold disagreement %d; verified match share fold B fl bin %.4f\n", sum(ALL$fd != ALL$fold), FL[, mean(ver)]))
cat("P34_VERIFY_DONE\n")
