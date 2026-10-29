## PREREG26 independent re-derivation. Written separately from assemble_p26.R and shares no code with it: reads the raw
## per task trajectory CSVs in out/ (not the assembled tables) and the plan's rules, recomputes every relation statistic,
## flag and margin and every NI gate value, then compares with the assembled relation and gate tables. Base R plus
## data.table for reading only. No coordinates. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p26"; A <- file.path(J, "assembled"); O <- file.path(J, "verify_20260930")
res_file <- file.path(O, "rederive_compare_DATA_2026-09-30.csv"); if (file.exists(res_file)) stop("REFUSE")
thr <- read.csv(file.path(A, "thresholds_p26_DATA_2026-09-30.csv")); tv <- function(q) thr$value[thr$quantity == q]
fa <- tv("frontier_a"); fb <- tv("frontier_b"); ba999 <- tv("BA_q999"); sdi999 <- tv("SDI_q999")
arms <- c("v141LT", "v141LTfi"); raw <- do.call(rbind, lapply(arms, function(a) do.call(rbind, lapply(c("BF","RS","MX"), function(m) read.csv(file.path(J, "out", paste0("traj_", a, "_", m, ".csv")), stringsAsFactors = FALSE)))))
cat("rows", nrow(raw), "\n")
g1 <- aggregate(age ~ arm + cell, raw, length); g1_ok <- sum(g1$age == 101) ; okc <- aggregate(run_ok ~ arm + cell, raw, min)
five <- raw[raw$age %in% seq(0, 100, 5), ]; five <- five[order(five$arm, five$cell, five$age), ]
rows <- list(); add <- function(arm, rel, unit, flag, margin, stat) rows[[length(rows) + 1]] <<- data.frame(arm = arm, relation = rel, unit = unit, flag = flag, margin = margin, stat = stat)
for (a in arms) {
  X <- five[five$arm == a, ]
  for (u in unique(X$cell)) { g <- X[X$cell == u, ]
    ## Reineke: points after a QMD advance above 0.5 cm per 5 yr step, first point always kept
    k <- rep(TRUE, nrow(g)); for (i in 2:nrow(g)) k[i] <- (g$QMD[i] - g$QMD[i - 1]) > 0.5
    gk <- g[k, ]; lost <- (max(g$TPH) - min(g$TPH)) / max(g$TPH)
    if (nrow(gk) >= 3 && sd(log(gk$QMD)) > 1e-3) { x <- log(gk$QMD); y <- log(gk$TPH); b <- sum((x - mean(x)) * (y - mean(y))) / sum((x - mean(x))^2)
      inb <- b > -2.2 && b < -1.2; add(a, "Reineke", u, !inb, if (inb) 0 else if (b >= -1.2) b + 1.2 else -2.2 - b, b)
    } else add(a, "Reineke", u, lost > 0.01, if (lost > 0.01) Inf else 0, NA)
    ## Frontier at 9.1 cm
    h <- g[g$TPH_s > 0, ]; q <- sqrt(h$BAPH_s / h$TPH_s * 40000 / pi); e <- log10(h$TPH_s) - fa - fb * log10(q)
    add(a, "Frontier", u, any(e > 0), max(c(0, e)), if (length(e)) max(e) else -Inf)
    sdi <- ifelse(g$TPH_s > 0, g$TPH_s * (sqrt(g$BAPH_s / pmax(g$TPH_s, 1e-12) * 40000 / pi) / 25)^1.605, 0)
    r <- max(max(g$BAPH_s) / ba999, max(sdi) / sdi999); add(a, "Magnitude", u, r > 1, max(0, r - 1), r)
    fall <- max(c(0, g$HT[-nrow(g)] - g$HT[-1])); add(a, "HT_monotone", u, fall > 0.01, if (fall > 0.01) fall else 0, fall) }
  for (m in c("BF","RS","MX")) for (n in c(1500, 3000, 6000)) { u <- paste0(m, "_N", n); g <- X[X$mix == m & X$n0 == n, ]
    lo <- max(tapply(g$HT, g$esi, min)); hi <- min(tapply(g$HT, g$esi, max))
    if (hi > lo) { hs <- seq(lo, hi, length.out = 8); cvs <- numeric(8)
      for (j in 1:8) { v <- sapply(c(9, 12, 15, 18), function(s) { z <- g[g$esi == s, ]; approx(z$HT, z$VOL, xout = hs[j], rule = 2, ties = mean)$y }); cvs[j] <- sd(v) / mean(v) }
      cv <- mean(cvs); add(a, "Eichhorn", u, cv >= 0.15, max(0, cv - 0.15), cv) } else add(a, "Eichhorn", u, TRUE, Inf, NA)
    for (v in c("HT","VOL","BAPH")) { cnt <- 0; big <- 0
      for (ag in seq(5, 100, 5)) { z <- g[g$age == ag, ]; z <- z[order(z$esi), v]
        bad <- any(diff(z) < 0); if (bad) { cnt <- cnt + 1; run <- z[1]; for (w in z) { run <- max(run, w); big <- max(big, (run - w) / max(z)) } } }
      add(a, paste0("SiteOrder_", v), u, cnt > 0, cnt, big) } }
  for (m in c("BF","RS","MX")) for (s in c(9, 12, 15, 18)) { u <- paste0(m, "_E", s); g <- X[X$mix == m & X$esi == s, ]
    vio <- 0; for (ag in c(50, 100)) { z <- g[g$age == ag, ]; z <- z[order(z$n0), ]; l <- z$n0 - z$TPH_cohort; vio <- vio + sum(l[-1] <= l[-length(l)]) }
    add(a, "Sukachev", u, vio > 0, vio, vio)
    cvv <- function(ag) { w <- g$VOL[g$age == ag]; sd(w) / mean(w) }; c1 <- cvv(100); c0 <- cvv(30); bad <- !(c1 < 0.15 && c1 < c0)
    add(a, "YieldDensity", u, bad, if (bad) max(c1 - 0.15, c1 - c0) else 0, c1) } }
R <- do.call(rbind, rows)
## NI
ni <- do.call(rbind, lapply(unique(R$relation), function(rel) { c1 <- R[R$arm == "v141LTfi" & R$relation == rel, ]; r1 <- R[R$arm == "v141LT" & R$relation == rel, ]
  mm <- merge(c1, r1, by = "unit"); newf <- sum(mm$flag.x & !mm$flag.y)
  cw <- if (any(c1$flag)) max(c1$margin[c1$flag]) else 0; rw <- if (any(r1$flag)) max(r1$margin[r1$flag]) else 0
  data.frame(relation = rel, cand_flags = sum(c1$flag), ref_flags = sum(r1$flag), new_flags = newf, cand_worst = cw, ref_worst = rw, ni_ok = newf == 0 && (sum(c1$flag) == 0 || cw <= rw + 1e-9)) }))
print(ni)
## compare with the assembly
AR <- fread(file.path(A, "gyr142-p26-relations_DATA_2026-09-30.csv"))[arm %in% arms]
M <- merge(as.data.table(R), AR, by = c("arm","relation","unit"), suffixes = c("_v", "_a"))
sd_ <- function(x, y) ifelse(is.infinite(x) & is.infinite(y), 0, ifelse(is.na(x) & is.na(y), 0, abs(x - y) / pmax(1, abs(y))))
M[, d_margin := sd_(margin_v, margin_a)][, d_stat := sd_(stat_v, stat_a)][, same_flag := flag_v == flag_a]
cmp <- data.table(item = c("relation rows matched", "flag agreement", "worst margin difference", "worst stat difference", "G1 complete trajectories", "run_ok all 1"),
  value = c(sprintf("%d of %d", nrow(M), nrow(R)), sprintf("%d of %d", sum(M$same_flag), nrow(M)), format(max(M$d_margin, na.rm = TRUE)), format(max(M$d_stat, na.rm = TRUE)), sprintf("%d of 72", g1_ok), as.character(all(okc$run_ok == 1))))
G <- fread(file.path(A, "gyr142-p26-gates_DATA_2026-09-30.csv"))
nig <- G[grepl("^NI ", gate)]; nig[, relation := sub("^NI ", "", gate)]; ch <- merge(nig[, .(relation, pass)], as.data.table(ni)[, .(relation, ni_ok)], by = "relation")
cmp <- rbind(cmp, data.table(item = "NI gate agreement", value = sprintf("%d of %d", sum(ch$pass == ch$ni_ok), nrow(ch))),
             data.table(item = "NI overall (re-derived)", value = as.character(all(ni$ni_ok))))
print(cmp); fwrite(cmp, res_file); fwrite(as.data.table(ni), file.path(O, "rederive_NI_DATA_2026-09-30.csv")); fwrite(as.data.table(R), file.path(O, "rederive_relations_DATA_2026-09-30.csv"))
cat("REDERIVE_DONE\n")
