## PREREG45b fold A fit: obs (measured top height increment) against nb_one cohort increment p0, sum (1, r)(obs - p0 exp(a + b r)) = 0
## by Newton, stand bootstrap B = 1000, seed 20261005. Reads no fold B row. No em dashes.
source("/home/aaron/jobs/v142p45b/scripts/p45b_mth.R")
OUT <- "/home/aaron/jobs/v142p45b/fit/gyr142-p45b-nbrh-fit_DATA_2026-10-05.csv"; if (file.exists(OUT)) stop("REFUSE")
S <- stands_nb(); O <- obs_nb(); P <- pred_nb("/home/aaron/jobs/v142p45b/home", "nb_one")
R1 <- rbindlist(lapply(arm_files("/home/aaron/jobs/v142p45b/home", "nb_one"), function(d) rbindlist(lapply(list.files(d, "^c[0-9]+_results\\.csv$", full.names = TRUE), fread, colClasses = list(character = "STAND")))))
K <- merge(merge(S[fold == "A" & TOTVOL_o > 0], O, by = "STAND"), P, by = "STAND"); K <- K[STAND %in% R1[RUN_OK == 1]$STAND]
K[, `:=`(obs = (MTH2 - MTH1) / iv, r = MTH1 / esi8, p0 = pinc)]; K <- K[is.finite(obs) & is.finite(p0) & is.finite(r)]
cat(sprintf("fold A fit population %d stands; mean obs %.4f, mean p0 %.4f, ratio %.4f\n", nrow(K), mean(K$obs), mean(K$p0), sum(K$obs) / sum(K$p0)))
if (nrow(K) < 30) stop("fewer than 30 fold A stands")
solve_ab <- function(w) { th <- c(log(sum(w * K$obs) / sum(w * K$p0)), 0)
  for (it in 1:100) { m <- K$p0 * exp(th[1] + th[2] * K$r); e <- K$obs - m
    U <- c(sum(w * e), sum(w * K$r * e)); Jm <- -matrix(c(sum(w * m), sum(w * K$r * m), sum(w * K$r * m), sum(w * K$r^2 * m)), 2)
    st <- tryCatch(solve(Jm, U), error = function(e) c(NA, NA)); if (anyNA(st)) return(c(NA, NA, NA)); th <- th - st; if (max(abs(st)) < 1e-12) return(c(th, it)) }
  c(NA, NA, NA) }
set.seed(20261005); B <- 1000L; pt <- solve_ab(rep(1, nrow(K))); if (!all(is.finite(pt))) stop("Newton did not converge")
bt <- t(sapply(1:B, function(k) solve_ab(tabulate(sample.int(nrow(K), nrow(K), TRUE), nrow(K))))); q <- function(v) quantile(v, c(.025, .975), na.rm = TRUE)
mf <- function(r) exp(pt[1] + pt[2] * r)
out <- data.table(param = c("a", "b"), value = pt[1:2], value_rounded = round(pt[1:2], 4), lo = c(q(bt[, 1])[1], q(bt[, 2])[1]), hi = c(q(bt[, 1])[2], q(bt[, 2])[2]),
  stands = nrow(K), newton_iter = pt[3], boot_nonconverged = sum(!is.finite(bt[, 1])), pooled_ratio_obs_p0 = sum(K$obs) / sum(K$p0),
  m_at_r0.4 = mf(.4), m_at_r0.625 = mf(.625), m_at_r0.875 = mf(.875), m_at_r1.125 = mf(1.125), r_q10 = quantile(K$r, .1), r_q90 = quantile(K$r, .9))
print(out); fwrite(out, OUT)
relb <- function(r) cut(r, c(0, 0.75, 1, Inf), right = FALSE, labels = c("below 0.75", "0.75 to 1", "1 and over"))
print(K[, .(stands = .N, obs = mean(obs), p0 = mean(p0), ratio = sum(obs) / sum(p0)), by = .(relb = relb(r))][order(relb)])
cat("P45B_FIT_DONE\n")
