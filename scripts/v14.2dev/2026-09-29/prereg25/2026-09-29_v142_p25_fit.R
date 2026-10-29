## PREREG25 step 1b: is the NS small tree height increment deficit a size effect? ns_c FOLD A only (fold B and the fl sets
## are never read). Data as 2026-09-29_v142_p25_diag.R: PREREG20 tag matched key joined to frozen v141LTf t2 predictions.
## Multipliers m act on the v141LTf predicted annual increment (least squares of observed on m * predicted, the PREREG11 and
## PREREG20 loss). Forms:
##   S1 size only (the requested candidate): m = exp(c1 (7.5 - D)+), 1 at and above 7.5 cm (so 1 at and above 12.7)
##   S1b two knot: m = exp(c1 (7.5 - D)+ + c2 (12.7 - max(D, 7.5))+)
##   S2 program only: m = exp(a RS), RS = 1 on NS_RS research plots, all sizes
##   S3 program plus size: m = exp(a RS + c1 (7.5 - D)+)
##   S4 program by size: m = exp(a_lt RS (D < 12.7) + a_ge RS (D >= 12.7))
## All bounded (m positive by construction). Site cluster bootstrap B = 1000, seed 20260929. Headless. No coordinates.
## Refuses to overwrite. No em dashes.
suppressMessages(library(data.table)); options(width = 220); set.seed(20260929)
J <- "/home/aaron/jobs/v142p25"; P20 <- "/home/aaron/jobs/v142p20"; O <- file.path(J, "fit")
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
fl <- list.files(file.path(P20, "home/out/v141LTf/ns_c"), "_pred_t2_tree\\.csv$", full.names = TRUE)
pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0][, .(STAND, tree, Hpf = ht)]
A <- fread(file.path(J, "in/key/p20_htkey_ns_c.csv"))[fold == "A"]; A <- merge(A, pt, by = c("STAND", "tree")); stopifnot(all(A$fold == "A"))
A[, `:=`(dho = (H2 - H1) / iv, dhf = (Hpf - H1) / iv, RS = as.integer(grepl("^NS__NS_RS_", STAND)))]
stopifnot(all(grepl("^NS__NS_(RS|OP)_", A$STAND)))
A[, `:=`(zs = pmax(0, 7.5 - D1), z2 = pmax(0, 12.7 - pmax(D1, 7.5)), lt = as.integer(D1 < 12.7))]
S <- A[, .(s11 = sum(dho * dhf), s22 = sum(dhf^2), s00 = sum(dho^2), n = .N), by = .(sidx, D1, RS, zs, z2, lt)]
sse <- function(eta, w) { m <- exp(eta); sum(w * (S$s00 - 2 * m * S$s11 + m^2 * S$s22)) }
forms <- list(
  S0_identity = list(np = 0, eta = function(p) 0 * S$D1),
  S1_size = list(np = 1, eta = function(p) p[1] * S$zs),
  S1b_twoknot = list(np = 2, eta = function(p) p[1] * S$zs + p[2] * S$z2),
  S2_program = list(np = 1, eta = function(p) p[1] * S$RS),
  S3_program_size = list(np = 2, eta = function(p) p[1] * S$RS + p[2] * S$zs),
  S4_program_by_size = list(np = 2, eta = function(p) p[1] * S$RS * S$lt + p[2] * S$RS * (1 - S$lt)))
fitf <- function(f, w) { if (f$np == 0) return(numeric(0))
  if (f$np == 1) return(optimize(function(b) sse(f$eta(b), w), c(-1, 2))$minimum)
  optim(c(0.1, 0.1), function(p) sse(f$eta(p), w), method = "L-BFGS-B", lower = c(-1, -1), upper = c(2, 2))$par }
w0 <- rep(1, nrow(S)); est <- lapply(forms, fitf, w = w0)
sites <- unique(S$sidx); B <- 1000
bs <- rbindlist(lapply(seq_len(B), function(i) { cnt <- tabulate(match(sample(sites, length(sites), TRUE), sites), length(sites)); w <- cnt[match(S$sidx, sites)]
  r <- lapply(forms[-1], fitf, w = w); data.table(draw = i, form = rep(names(r), lengths(r)), par = unlist(lapply(r, seq_along)), value = unlist(r)) }))
fwrite(bs, f_out("gyr142-p25-fit-bootstrap_DATA_2026-09-29.csv"))
P <- rbindlist(lapply(names(forms)[-1], function(n) data.table(form = n, par = seq_along(est[[n]]), est = est[[n]],
  lo = bs[form == n, quantile(value, .025), by = par]$V1, hi = bs[form == n, quantile(value, .975), by = par]$V1)))
P[, m_at_est := exp(est)]
G <- data.table(form = names(forms), npar = sapply(forms, `[[`, "np"), sse = sapply(names(forms), function(n) sse(forms[[n]]$eta(est[[n]]), w0)))
G[, d_sse_vs_S2 := sse - G[form == "S2_program", sse]]
## in sample class ratios under each form (fold A), by program and class
A[, c25 := cut(D1, c(0, 2.5, 5, 7.5, 10, 12.7, 25, Inf), right = FALSE)]
etaA <- function(n, p) switch(n, S0_identity = 0, S1_size = p[1] * A$zs, S1b_twoknot = p[1] * A$zs + p[2] * A$z2, S2_program = p[1] * A$RS,
  S3_program_size = p[1] * A$RS + p[2] * A$zs, S4_program_by_size = p[1] * A$RS * A$lt + p[2] * A$RS * (1 - A$lt))
for (n in names(forms)) A[, (paste0("r_", n)) := exp(etaA(n, est[[n]])) * dhf]
C <- A[, c(list(trees = .N, sites = uniqueN(sidx), obs = mean(dho)), lapply(.SD, function(v) mean(v) / mean(dho))), by = .(prog = fifelse(RS == 1, "NS_RS", "NS_OP"), c25), .SDcols = patterns("^r_")][order(prog, c25)]
C2 <- A[, c(list(trees = .N, obs = mean(dho)), lapply(.SD, function(v) mean(v) / mean(dho))), by = .(c25), .SDcols = patterns("^r_")][order(c25)][, prog := "pooled"]
CC <- rbind(C, C2, fill = TRUE)
fwrite(P, f_out("gyr142-p25-fit-params_DATA_2026-09-29.csv")); fwrite(G, f_out("gyr142-p25-fit-sse_DATA_2026-09-29.csv")); fwrite(CC, f_out("gyr142-p25-fit-insample-foldA_DATA_2026-09-29.csv"))
print(P, digits = 4); print(G, digits = 6); print(CC, digits = 3)
cat(sprintf("fold A ns_c: %d trees, %d sites; NS_RS %d trees on %d sites; D1 below 7.5 cm: %d trees, NS_RS share %.4f; smallest NS_OP D1 %.1f cm\n",
  nrow(A), uniqueN(A$sidx), A[RS == 1, .N], A[RS == 1, uniqueN(sidx)], A[D1 < 7.5, .N], A[D1 < 7.5, mean(RS)], A[RS == 0, min(D1)]))
cat("P25_FIT_DONE\n")
