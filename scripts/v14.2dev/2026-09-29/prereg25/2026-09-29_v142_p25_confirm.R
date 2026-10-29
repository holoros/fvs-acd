## PREREG25 confirmation of the step 1 diagnostic finding on held out data. Runs only after the pre-registration md5 is
## recorded (P25_PREREG_MD5 must match the file). Reads the PREREG20 tag matched key for all four NS sets (read only, in
## ~/jobs/v142p20/in/key) and the frozen PREREG20 v141LTf per tree t2 predictions; no engine run. Ratio = mean predicted
## over mean observed annual height increment (PREREG20 H2 definition). Classes at t1: below 7.5, 7.5 to 12.7, 12.7 and
## over. Program: NS_RS against NS_OP by STAND prefix. Site cluster bootstrap within set x fold x program x class,
## B = 1000, seed 20260929. Reproduction checks first (fold A step 1 table; PREREG20 H2 below 12.7 cells), then gates C1 to
## C3, then the decision rule in order. Writes a new assembled/ directory and refuses if it exists. Headless, theme_classic,
## 300 dpi. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) }); options(width = 220); set.seed(20260929)
J <- "/home/aaron/jobs/v142p25"; P20 <- "/home/aaron/jobs/v142p20"; OUT <- file.path(J, "assembled")
PR <- file.path(J, "prereg/2026-09-29_v142_ns-small-tree-height_PREREG25.md")
want <- Sys.getenv("P25_PREREG_MD5", ""); got <- unname(tools::md5sum(PR))
if (!nzchar(want) || want != got) stop("PREREG md5 mismatch or unset: ", got)
if (dir.exists(OUT)) stop("REFUSE ", OUT, " exists"); dir.create(OUT)
f_out <- function(n) file.path(OUT, n)
pred <- function(s) {
  fl <- list.files(file.path(P20, "home/out/v141LTf", s), "_pred_t2_tree\\.csv$", full.names = TRUE); stopifnot(length(fl) > 0)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  for (k in 1:3) { rf <- list.files(file.path(P20, sprintf("home/out_retry_a%d/v141LTf/%s", k, s)), "_pred_t2_tree\\.csv$", full.names = TRUE)
    if (length(rf)) { r <- rbindlist(lapply(rf, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; pt <- rbind(pt[!STAND %in% r$STAND], r) } }
  stopifnot(!anyDuplicated(pt[, .(STAND, tree)])); pt[, .(STAND, tree, Hpf = ht)] }
X <- rbindlist(lapply(c("ns_c", "ns_long_c", "ns_fl", "ns_long_fl"), function(s) {
  x <- merge(fread(file.path(P20, sprintf("in/key/p20_htkey_%s.csv", s))), pred(s), by = c("STAND", "tree"), all.x = TRUE); stopifnot(!anyNA(x$Hpf))
  stopifnot(all(grepl("^NS__NS_(RS|OP)_", x$STAND)))
  x[, .(set = s, STAND, sidx, fold, SP, D1, H1, dho = (H2 - H1) / iv, dhf = (Hpf - H1) / iv, prog = fifelse(grepl("^NS__NS_RS_", STAND), "NS_RS", "NS_OP"))] }))
## ---- reproduction checks ----
X[, c25 := cut(D1, c(0, 2.5, 5, 7.5, 10, 12.7, 15, 20, 25, Inf), right = FALSE)]
DA <- fread(file.path(J, "fit/gyr142-p25-diag-smalltree-foldA_DATA_2026-09-29.csv"))[table == "program by class"]
ra <- X[fold == "A" & set %in% c("ns_c", "ns_long_c"), .(r = mean(dhf) / mean(dho), n = .N), by = .(set, prog, c25 = as.character(c25))]
ck1 <- merge(ra, DA[, .(set, prog, c25, ratio_f, trees)], by = c("set", "prog", "c25"))
e1 <- ck1[, max(abs(r - ratio_f))]; if (nrow(ck1) != nrow(DA) || e1 > 1e-9 || any(ck1$n != ck1$trees)) stop("REPRO FAIL step 1 table ", e1)
H2 <- fread(file.path(P20, "tables/gyr142-p20-h2-sizeclass_DATA_2026-09-28.csv"))[cls == "below 12.7"]
rb <- X[D1 < 12.7, .(r = mean(dhf) / mean(dho), n = .N), by = .(set, fold)]
ck2 <- merge(rb, H2[, .(set, fold, rf, trees)], by = c("set", "fold")); e2 <- ck2[, max(abs(r - rf))]
if (nrow(ck2) != 8 || e2 > 1e-9 || any(ck2$n != ck2$trees)) stop("REPRO FAIL PREREG20 H2 below 12.7 ", e2)
cat(sprintf("Reproduction: step 1 fold A table worst %.3g over %d cells; PREREG20 H2 below 12.7 worst %.3g over %d cells\n", e1, nrow(ck1), e2, nrow(ck2)))
## ---- held out tables ----
X[, cls := cut(D1, c(0, 7.5, 12.7, Inf), right = FALSE, labels = c("below 7.5", "7.5 to 12.7", "12.7 and over"))]
bsr <- function(d) { S <- d[, .(o = sum(dho), f = sum(dhf)), by = sidx]; n <- nrow(S); if (n < 2) return(list(lo = NA_real_, hi = NA_real_))
  r <- replicate(1000, { i <- sample.int(n, n, TRUE); sum(S$f[i]) / sum(S$o[i]) }); list(lo = unname(quantile(r, .025)), hi = unname(quantile(r, .975))) }
R <- X[, .(trees = .N, sites = uniqueN(sidx), obs = mean(dho), pred = mean(dhf), ratio = mean(dhf) / mean(dho)), by = .(set, fold, prog, cls)]
R <- merge(R, X[, bsr(.SD), by = .(set, fold, prog, cls)], by = c("set", "fold", "prog", "cls"))[order(set, fold, prog, cls)]
fwrite(R, f_out("gyr142-p25-confirm-program-class_DATA_2026-09-29.csv"))
SPG <- X[D1 < 12.7 & prog == "NS_RS", .(trees = .N, ratio = mean(dhf) / mean(dho)), by = .(set, fold, SP)][trees >= 30][order(set, fold, -trees)]
BH <- X[D1 < 12.7, .(trees = .N, ratio = mean(dhf) / mean(dho)), by = .(set, fold, prog, h1 = cut(H1, c(0, 1.8, 2.5, 3.5, 5, 8, Inf), right = FALSE))][order(set, fold, prog, h1)]
fwrite(SPG, f_out("gyr142-p25-confirm-rs-species_DATA_2026-09-29.csv")); fwrite(BH, f_out("gyr142-p25-confirm-h1class_DATA_2026-09-29.csv"))
## reported only: the fold A size only candidate S1 applied offline to fold B
c1 <- fread(file.path(J, "fit/gyr142-p25-fit-params_DATA_2026-09-29.csv"))[form == "S1_size", est]; stopifnot(length(c1) == 1)
S1 <- X[fold == "B", .(trees = .N, ratio_v141LTf = mean(dhf) / mean(dho), ratio_S1 = mean(exp(c1 * pmax(0, 7.5 - D1)) * dhf) / mean(dho)), by = .(set, prog, cls)][order(set, prog, cls)]
S1p <- X[fold == "B", .(trees = .N, ratio_v141LTf = mean(dhf) / mean(dho), ratio_S1 = mean(exp(c1 * pmax(0, 7.5 - D1)) * dhf) / mean(dho)), by = .(set, cls)][, prog := "pooled"]
fwrite(rbind(S1, S1p, fill = TRUE), f_out("gyr142-p25-confirm-S1-offline_DATA_2026-09-29.csv"))
## ---- gates on fold B, ns_c and ns_long_c ----
B <- R[fold == "B" & set %in% c("ns_c", "ns_long_c")]
g <- function(s) { b <- B[set == s]; rs <- b[prog == "NS_RS"]; op <- b[prog == "NS_OP"]
  n_op_small <- X[fold == "B" & set == s & prog == "NS_OP" & D1 < 7.5, .N]; n_op_lt <- X[fold == "B" & set == s & prog == "NS_OP" & D1 < 12.7, .N]
  r_op_mid <- op[cls == "7.5 to 12.7", ratio]
  d_rs <- abs(rs[cls == "below 7.5", ratio] - rs[cls == "12.7 and over", ratio])
  data.table(set = s,
    C1 = nrow(rs) == 3 && all(rs$ratio < 0.8) && all(rs$hi < 1), C1_detail = paste(sprintf("%s %.3f (%.3f to %.3f)", rs$cls, rs$ratio, rs$lo, rs$hi), collapse = "; "),
    C2 = n_op_small / n_op_lt < 0.01 && length(r_op_mid) == 1 && r_op_mid >= 0.95, C2_detail = sprintf("NS_OP below 7.5 share %.4f of %d; NS_OP 7.5 to 12.7 ratio %.3f", n_op_small / n_op_lt, n_op_lt, r_op_mid),
    C3 = d_rs < 0.20, C3_detail = sprintf("NS_RS |r(below 7.5) - r(12.7 and over)| = %.3f", d_rs)) }
GT <- rbind(g("ns_c"), g("ns_long_c")); fwrite(GT, f_out("gyr142-p25-gates_DATA_2026-09-29.csv"))
c1p <- all(GT$C1); c2p <- all(GT$C2); c3p <- all(GT$C3)
verdict <- if (c1p && c2p && c3p) "Rule 2: diagnostic finding confirmed; no size multiplier; the deficit belongs to the NS_RS population" else
  if (c1p && c2p && !c3p) "Rule 3: program deficit confirmed but a size gradient within NS_RS remains; a size term is considered only jointly with a program or state term, under a new pre-registration" else
  if (!c1p) "Rule 4: NS_RS deficit not confirmed on held out sites; the fold A pattern is not stable; nothing adopted" else
  "Rule 5: NS_OP small tree condition fails; the size question is reopened on NS_OP data"
writeLines(c(sprintf("PREREG25 md5 %s", got), sprintf("Reproduction step1 %.3g, PREREG20 H2 %.3g", e1, e2), sprintf("C1 %s, C2 %s, C3 %s", c1p, c2p, c3p), verdict), f_out("gyr142-p25-verdict_2026-09-29.txt"))
## ---- figure ----
pd <- R[set %in% c("ns_c", "ns_long_c")]; pd[, fold := paste("fold", fold)]
p <- ggplot(pd, aes(cls, ratio, colour = prog, shape = fold)) + geom_hline(yintercept = 1, linetype = 2, colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5)) + facet_wrap(~set) +
  scale_colour_manual(values = c(NS_OP = "#1b6f8a", NS_RS = "#b5502a"), name = "Program") + labs(x = "Diameter class at t1 (cm)", y = "Predicted over observed annual height increment", shape = NULL) +
  theme_classic(base_size = 11) + theme(legend.position = "bottom", plot.margin = margin(12, 8, 6, 6))
ggsave(f_out("gyr142-p25-program-class_2026-09-29.png"), p, width = 8, height = 4.5, dpi = 300)
print(R[fold == "B"], digits = 3); print(GT); cat(verdict, "\n"); print(rbind(S1, S1p, fill = TRUE), digits = 3)
cat("P25_CONFIRM_DONE\n")
