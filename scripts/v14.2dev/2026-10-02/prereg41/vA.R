## PREREG41 F9 verifier, Part A: Bakuzis relations, NI table, decision, G1, G2. Written by the verifier from the PREREG41, 31, 26 plans.
## Readings (verifier): five year points ages 0..100. 4 cm columns HT TPH BAPH QMD VOL; 9.1 cm columns TPH_s BAPH_s; QMD_s = sqrt(40000 BAPH_s /
## (pi TPH_s)); SDI_s = TPH_s (QMD_s/25)^1.605 (the 25 cm metric form, which reproduces the stored 4 cm SDI). Margins are signed so that a
## unit flags iff margin > 0 (Reineke and yield density: >= 0, the pass conditions being strict). Site ordering HT, VOL, BA are three relations;
## inversions counted over (age 5..100, ESI pair with lower ESI value > higher ESI value). Eichhorn: per ESI trajectory VOL interpolated
## linearly at 8 equally spaced top heights spanning the common HT range (max of minima to min of maxima, inclusive); CV = sd/mean.
## Reineke points: both end points of every five year step whose QMD advances more than 0.5 cm (reading chosen after a first reading,
## end point only, gave a qc141 worst margin 0.892 against the 1.266 the PREREG41 plan states; see explore_reineke.R and its log).
suppressMessages(library(data.table))
V <- "/home/aaron/jobs/v142p41/verify_20261002"
TH <- fread("/home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv"); th <- setNames(TH$value, TH$quantity)
FA <- th[["frontier_a"]]; FB <- th[["frontier_b"]]; BA999 <- th[["BA_q999"]]; SDI999 <- th[["SDI_q999"]]
rdA <- function(f) fread(f)
Q <- rbind(rbindlist(lapply(c("BF", "SM", "MX"), function(m) rdA(sprintf("/home/aaron/jobs/v142p31/out/traj_qc141_%s.csv", m)))),
           rbindlist(lapply(c("BF", "SM", "MX"), function(m) rdA(sprintf("/home/aaron/jobs/v142p41/out/traj_p38_fit_%s.csv", m)))))
## G1
g1 <- Q[, .(n = .N, ok = all(run_ok == 1), a100 = max(age)), by = .(arm, cell)]
G1n <- g1[(arm == "p38_fit" & n == 101 & ok & a100 == 100) | (arm == "qc141" & n == 101)][, .N]
cat(sprintf("G1: %d of 72 (qc141 cells %d, p38_fit cells %d)\n", G1n, g1[arm == "qc141", .N], g1[arm == "p38_fit", .N]))
## G2
dry <- fread("/home/aaron/jobs/v142p41/dry/dry_qc141_MX_E19.8_N6000.csv"); fz <- Q[arm == "qc141" & cell == "MX_E19.8_N6000"]
nc <- names(dry)[sapply(dry, is.numeric)]
G2 <- nrow(dry) == nrow(fz) && identical(names(dry), names(fz)) && all(sapply(nc, function(k) isTRUE(all.equal(dry[[k]], fz[[k]], tolerance = 0))))
cat(sprintf("G2: identical on %d numeric columns over %d rows: %s\n", length(nc), nrow(dry), G2))
P <- Q[age %% 5 == 0]; setorder(P, arm, mix, esi, n0, age)
P[, QMD_s := fifelse(TPH_s > 0, sqrt(40000 * BAPH_s / (pi * TPH_s)), NA_real_)][, SDI_s := fifelse(TPH_s > 0, TPH_s * (QMD_s / 25)^1.605, 0)]
chk <- P[, max(abs(SDI - TPH * (QMD / 25)^1.605) / pmax(SDI, 1e-12))]; cat(sprintf("SDI form check on 4 cm columns, worst rel diff %.3g\n", chk))
U <- list()
## trajectory relations
tr <- P[, {
  dq <- diff(QMD); k0 <- which(dq > 0.5); k <- sort(unique(c(k0, k0 + 1L)))
  rs <- if (length(k) >= 3) coef(lm(log(TPH[k]) ~ log(QMD[k])))[2] else NA_real_
  rm <- if (is.na(rs)) Inf else max(-2.2 - rs, rs + 1.2)
  fe <- if (any(TPH_s > 0)) max(log10(TPH_s[TPH_s > 0]) - (FA + FB * log10(QMD_s[TPH_s > 0]))) else -Inf
  mg <- max(max(BAPH_s) / BA999, max(SDI_s) / SDI999) - 1
  hf <- max(-diff(HT))
  list(rel = c("Reineke", "Frontier", "Magnitude", "HT monotone"), margin = c(rm, fe, mg, hf),
       flag = c(rm >= 0, fe > 0, mg > 0, hf > 0.01), npts = c(length(k), NA, NA, NA)) }, by = .(arm, mix, esi, n0)]
tr[, unit := sprintf("%s_E%s_N%d", mix, esi, n0)]
U[[1]] <- tr[, .(arm, rel, unit, margin, flag)]
## site ordering, Eichhorn (mix by N0)
mn <- P[, {
  out <- list(); ages <- seq(5, 100, 5); es <- sort(unique(esi))
  for (v in c("HT", "VOL", "BAPH")) { inv <- 0L; nag <- 0L
    for (ag in ages) { x <- sapply(es, function(e) get(v)[esi == e & age == ag]); a0 <- 0L
      for (i in 1:(length(es) - 1)) for (j in (i + 1):length(es)) if (x[i] > x[j]) a0 <- a0 + 1L
      inv <- inv + a0; nag <- nag + (a0 > 0) }
    out[[v]] <- c(inv, nag) }
  hs <- lapply(es, function(e) HT[esi == e]); vs <- lapply(es, function(e) VOL[esi == e])
  lo <- max(sapply(hs, min)); hi <- min(sapply(hs, max)); hg <- seq(lo, hi, length.out = 8)
  M <- sapply(seq_along(es), function(i) approx(hs[[i]], vs[[i]], xout = hg, ties = mean)$y)
  cv <- mean(apply(M, 1, function(z) sd(z) / mean(z)))
  list(rel = c("Site ordering HT", "Site ordering VOL", "Site ordering BA", "Eichhorn"),
       margin = c(out$HT[1], out$VOL[1], out$BAPH[1], cv - 0.15), ages_inv = c(out$HT[2], out$VOL[2], out$BAPH[2], NA)) }, by = .(arm, mix, n0)]
mn[, flag := margin > 0][, unit := sprintf("%s_N%d", mix, n0)]
U[[2]] <- mn[, .(arm, rel, unit, margin, flag)]
## Sukachev, yield density (mix by ESI)
me <- P[, {
  ns <- sort(unique(n0)); viol <- 0L
  for (ag in c(50, 100)) { L <- sapply(ns, function(n) n - TPH_cohort[n0 == n & age == ag]); for (i in 1:(length(ns) - 1)) if (!(L[i + 1] > L[i])) viol <- viol + 1L }
  v100 <- sapply(ns, function(n) VOL[n0 == n & age == 100]); v30 <- sapply(ns, function(n) VOL[n0 == n & age == 30])
  c100 <- sd(v100) / mean(v100); c30 <- sd(v30) / mean(v30); yd <- max(c100 - 0.15, c100 - c30)
  list(rel = c("Sukachev", "Yield density"), margin = c(viol, yd), flag = c(viol > 0, yd >= 0)) }, by = .(arm, mix, esi)]
me[, unit := sprintf("%s_E%s", mix, esi)]
U[[3]] <- me[, .(arm, rel, unit, margin, flag)]
UU <- rbindlist(U); fwrite(UU, file.path(V, "partA_units_DATA_2026-10-02.csv"))
cat(sprintf("Reineke units with < 3 points: %d; site ordering inverted ages total qc141 %s p38_fit %s\n", tr[rel == "Reineke" & npts < 3, .N],
  mn[arm == "qc141" & rel != "Eichhorn", sum(ages_inv)], mn[arm == "p38_fit" & rel != "Eichhorn", sum(ages_inv)]))
W <- dcast(UU, rel + unit ~ arm, value.var = c("margin", "flag"))
rels <- c("Reineke", "Frontier", "Eichhorn", "Site ordering HT", "Site ordering VOL", "Site ordering BA", "Sukachev", "Yield density", "Magnitude", "HT monotone")
NI <- rbindlist(lapply(rels, function(r) { w <- W[rel == r]
  nf <- w[flag_p38_fit == TRUE & flag_qc141 == FALSE]
  fq <- sum(w$flag_qc141); fp <- sum(w$flag_p38_fit); wq <- max(w$margin_qc141); wp <- max(w$margin_p38_fit)
  okB <- if (fp == 0) TRUE else wp <= wq + 1e-9
  data.table(rel = r, n_units = nrow(w), flags_qc141 = fq, flags_p38_fit = fp, worst_qc141 = wq, worst_p38_fit = wp, new_flags = nrow(nf),
             new_units = paste(nf$unit, collapse = " "), okA = nrow(nf) == 0, okB = okB, ni_ok = nrow(nf) == 0 && okB) }))
print(NI[, !"new_units"], digits = 10)
for (i in which(NI$new_flags > 0)) cat(sprintf("new flags %s: %s\n", NI$rel[i], NI$new_units[i]))
NIpass <- all(NI$ni_ok); harness <- G1n == 72 && G2
dec <- if (!harness) 1L else if (!NIpass) 2L else 3L
cat(sprintf("decisionA: rule %d (harness %s, NI %s)\n", dec, harness, NIpass))
## realism (reported): top height at 50 and 100 by cell, ratio p38_fit / qc141 aggregates
rz <- dcast(P[age %in% c(50, 100)], mix + esi + n0 + age ~ arm, value.var = "HT"); rz[, ratio := p38_fit / qc141]
cat(sprintf("HT ratio p38_fit/qc141 at 50: %.4f to %.4f; at 100: %.4f to %.4f\n", min(rz[age == 50]$ratio), max(rz[age == 50]$ratio), min(rz[age == 100]$ratio), max(rz[age == 100]$ratio)))
L <- list(data.table(item = "G1 complete", arm = "both", value = G1n), data.table(item = "G2 identical", arm = "qc141", value = as.numeric(G2)))
for (i in seq_len(nrow(NI))) { r <- NI$rel[i]
  L[[length(L) + 1]] <- data.table(item = c(paste(r, "flags"), paste(r, "flags"), paste(r, "worst"), paste(r, "worst"), paste(r, "new_flags"), paste(r, "ni_ok")),
    arm = c("qc141", "p38_fit", "qc141", "p38_fit", "p38_fit", "p38_fit"),
    value = c(NI$flags_qc141[i], NI$flags_p38_fit[i], NI$worst_qc141[i], NI$worst_p38_fit[i], NI$new_flags[i], as.numeric(NI$ni_ok[i]))) }
L[[length(L) + 1]] <- data.table(item = "decisionA", arm = "p38_fit", value = dec)
fwrite(rbindlist(L), file.path(V, "partA_DATA_2026-10-02.csv"))
cat("PART_A_DONE\n")
