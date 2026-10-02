## PREREG42 F9 independent verification. Field tag (pass28qc) and row index (run frames) height increment points for
## p19_a0111, p28_cand, p33_dyn on screened qc_c fold B; PREREG28 and PREREG33 height gates and verdicts; Part B counts.
## Sources the PREREG23 helper (59196106) and swaps FR. Formulas follow the PREREG23 and PREREG28b assemblies. No bootstrap
## (points only). No coordinates. No per stand or per tree output. No em dashes.
H <- "/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R"
stopifnot(unname(tools::md5sum(H)) == "59196106afe20e57ca1bc7b4894495f1"); source(H)
V <- "/home/aaron/jobs/v142p42/verify_20261002"; OUT <- list(); add <- function(item, arm, value) OUT[[length(OUT) + 1L]] <<- data.table(item = item, arm = arm, value = as.character(value))
FR_ROW <- FR; FR_FLD <- "/home/aaron/jobs/v142p14/in/pass28qc"
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"); M_CLS <- 0.03; M_DOM <- 0.02
AR <- data.table(arm = c("p19_a0111", "p28_cand", "p33_dyn"), root = c(P19, "/home/aaron/jobs/v142p28", "/home/aaron/jobs/v142p33")); AR[, home := file.path(root, "home")]
S0 <- stand_frame(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), "qc_c", CUTF)
hk <- function() { TK <- tag_key("qc_c", S0$STAND); K <- merge(TK$K, S0[, .(STAND, SITE, cut, fold)], by = "STAND")
  for (a in AR$arm) { p <- pred_ht(arm_dirs(AR[arm == a]$home, a, "qc_c"), TK$M, S0$STAND)
    if (a == AR$arm[1]) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
    K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", a)) }
  if (K[, anyNA(.SD), .SDcols = paste0("Hp_", AR$arm)]) stop("tag record without prediction")
  K[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
  K[, dho := (H2 - H1) / iv]; for (a in AR$arm) K[, paste0("dp_", a) := (get(paste0("Hp_", a)) - H1) / iv]
  X <- K[fold == "B" & cut == FALSE]
  grp <- list(overall = X, `below 12.7` = X[cls == "below 12.7"], `12.7 to 25` = X[cls == "12.7 to 25"], `25 and over` = X[cls == "25 and over"], dominant = X[dom == TRUE])
  rbindlist(lapply(names(grp), function(g) { Y <- grp[[g]]; rbindlist(lapply(AR$arm, function(a) { d <- Y[[paste0("dp_", a)]]
    data.table(group = g, arm = a, trees = nrow(Y), sites = uniqueN(Y$SITE), ratio = sum(d) / sum(Y$dho), bias_m_yr = (sum(d) - sum(Y$dho)) / nrow(Y), level_t2 = sum(Y[[paste0("Hp_", a)]]) / sum(Y$H2)) })) })) }
FR <- FR_ROW; HR <- hk(); FR <- FR_FLD; HF <- hk()
for (pp in list(list("field tag", HF), list("row index", HR))) { T <- pp[[2]]; pre <- if (pp[[1]] == "field tag") "" else "rowidx "
  for (a in AR$arm) { o <- T[arm == a & group == "overall"]
    add(paste0(pre, "ratio"), a, sprintf("%.15g", o$ratio)); add(paste0(pre, "trees"), a, o$trees); add(paste0(pre, "sites"), a, o$sites)
    add(paste0(pre, "bias overall"), a, sprintf("%.15g", o$bias_m_yr))
    for (g in c("below 12.7", "12.7 to 25", "25 and over")) { r <- T[arm == a & group == g]; add(paste0(pre, "bias ", g), a, sprintf("%.15g", r$bias_m_yr)); add(paste0(pre, "trees ", g), a, r$trees) }
    d <- T[arm == a & group == "dominant"]; add(paste0(pre, "dom level"), a, sprintf("%.15g", d$level_t2)); add(paste0(pre, "trees dominant"), a, d$trees) } }
print(HF); print(HR)
## ---- gates and verdicts under field tags
STS28 <- fread("/home/aaron/jobs/v142p28/assembled/gyr142-p28-stands-summary_DATA_2026-09-30.csv")[set == "qc_c" & pop == "screened B"]
STS33 <- fread("/home/aaron/jobs/v142p33/assembled/bench/gyr142-p33-stands-summary_DATA_2026-10-01.csv")[set == "qc_c" & pop == "screened B"]
k1 <- function(root, a) sum(sapply(c("qc_c", "qc_fl"), function(s) { r <- fread(file.path(root, "results", a, sprintf("gyr_%s_%s_results.csv", a, s))); sum(r$RUN_OK != 1) }))
h0res <- function() max(sapply(c("qc_c", "qc_fl"), function(s) { a <- fread(sprintf("/home/aaron/jobs/v142p28/results/p28_g0/gyr_p28_g0_%s_results.csv", s))[, STAND := as.character(STAND)]
  b <- fread(sprintf("%s/results/p19_a0111/gyr_p19_a0111_%s_results.csv", P19, s))[, STAND := as.character(STAND)]; if (!setequal(a$STAND, b$STAND)) return(Inf); setkey(a, STAND); setkey(b, STAND)
  max(sapply(c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK"), function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; max(d) })) }))
study <- function(nm, CAND, root, STS, T, h0pass) { REF <- "p19_a0111"; hb <- function(a, g) T[arm == a & group == g]; sb <- function(a) STS[arm == a]
  HP <- abs(hb(CAND, "overall")$ratio - 1) < abs(hb(REF, "overall")$ratio - 1)
  HC <- all(sapply(c("below 12.7", "12.7 to 25", "25 and over"), function(g) abs(hb(CAND, g)$bias_m_yr) - abs(hb(REF, g)$bias_m_yr) <= M_CLS))
  s0 <- sb(REF); s1 <- sb(CAND); sT <- sb("p23_a1061"); stopifnot(nrow(s0) == 1, nrow(s1) == 1, nrow(sT) == 1)
  top_worse <- abs(s1$topht_bias_pct) > abs(sT$topht_bias_pct); dom_out <- abs(hb(CAND, "dominant")$level_t2 - 1) > abs(hb(REF, "dominant")$level_t2 - 1) + M_DOM
  TOP <- !top_worse && !dom_out; K1 <- k1(root, CAND) == 0
  V2 <- s0$C1_rmse_pct - s1$C1_rmse_pct >= -0.5; B1 <- 100 * (abs(s1$ba_ratio - 1) - abs(s0$ba_ratio - 1)) <= 1.0; B2 <- 100 * (abs(s1$stems_ratio - 1) - abs(s0$stems_ratio - 1)) <= 2.0
  cat(sprintf("%s: topht cand %.6f vs 1.061 %.6f (worse %s); dom out %s; K1 not_ok %d; V2 %s B1 %s B2 %s\n", nm, s1$topht_bias_pct, sT$topht_bias_pct, top_worse, dom_out, k1(root, CAND), V2, B1, B2))
  rule <- if (nm == "PREREG33") { if (!all(h0pass, K1, HP, HC, TOP, V2, B1, B2)) "Rule 2" else "Rule 3" } else {
    if (!h0pass || !K1) "Rule 1" else if (!HP) "Rule 2" else if (!HC) "Rule 3" else if (!TOP) "Rule 4" else if (!(V2 && B1 && B2)) "Rule 5" else "Rule 6" }
  add("H0", nm, h0pass); add("K1", nm, K1); add("HP", nm, HP); add("HC", nm, HC); add("TOP", nm, TOP); add("TOP topht worse", nm, top_worse); add("TOP dom out", nm, dom_out)
  add("V2", nm, V2); add("B1", nm, B1); add("B2", nm, B2); add("verdict", nm, rule); rule }
w0 <- h0res(); cat(sprintf("PREREG28 H0 results level worst %.3g\n", w0))
for (pp in list(list("", HF), list("rowidx ", HR))) { n0 <- length(OUT)
  study("PREREG28", "p28_cand", "/home/aaron/jobs/v142p28", STS28, pp[[2]], is.finite(w0) && w0 <= 1e-9)
  study("PREREG33", "p33_dyn", "/home/aaron/jobs/v142p33", STS33, pp[[2]], TRUE)
  if (nzchar(pp[[1]])) for (i in (n0 + 1):length(OUT)) OUT[[i]]$item <- paste0(pp[[1]], OUT[[i]]$item) }
## ---- Part B counts, every qc_c stand in the frames
for (pp in list(list("row index", FR_ROW), list("field tag", FR_FLD))) {
  F <- fread(file.path(pp[[2]], "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)]; G <- fread(file.path(pp[[2]], "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)]
  t1 <- F[tagok(TREE), .(STAND, TAG = TREE, SP, H1 = HT)]; t2 <- G[tagok(TREE), .(STAND, TAG = TREE, SP2 = SP, H2 = HT)]
  t1 <- t1[!t1[, .N, by = .(STAND, TAG)][N > 1], on = .(STAND, TAG)]; t2 <- t2[!t2[, .N, by = .(STAND, TAG)][N > 1], on = .(STAND, TAG)]
  m <- merge(t1, t2, by = c("STAND", "TAG")); sub <- m[SP == SP2 & is.finite(H1) & H1 > 0 & is.finite(H2) & H2 > 0]
  cat(sprintf("Part B %s: matched %d subset %d (stands in frames %d)\n", pp[[1]], nrow(m), nrow(sub), uniqueN(F$STAND)))
  add("matched", pp[[1]], nrow(m)); add("subset", pp[[1]], nrow(sub)) }
R <- rbindlist(OUT); fwrite(R, file.path(V, "p42_verify_DATA_2026-10-02.csv")); print(R, nrows = 500)
cat("P42_VERIFY_DONE\n")
