## verifier exploration of Reineke point-selection readings on frozen qc141 only (PREREG41 plan states qc141 worst Reineke margin 1.266)
suppressMessages(library(data.table))
Q <- rbindlist(lapply(c("BF","SM","MX"), function(m) fread(sprintf("/home/aaron/jobs/v142p31/out/traj_qc141_%s.csv", m))))
P <- Q[age %% 5 == 0]; setorder(P, mix, esi, n0, age)
f <- function(k, TPH, QMD) if (length(k) >= 3) unname(coef(lm(log(TPH[k]) ~ log(QMD[k])))[2]) else NA_real_
r <- P[, { dq <- diff(QMD); a <- which(dq > 0.5) + 1L; b <- sort(unique(c(a, a - 1L))); c0 <- which(dq > 0.5)
  ## d: annual advance criterion on annual data not available here; e: cumulative points with QMD above start + 0.5
  list(A = f(a, TPH, QMD), B = f(b, TPH, QMD), C = f(c0, TPH, QMD), Dall = f(seq_along(QMD), TPH, QMD), TPHall = f(a, TPH_all, QMD)) }, by = .(mix, esi, n0)]
m <- function(s) max(pmax(-2.2 - s, s + 1.2), na.rm = TRUE)
cat(sprintf("A %.4f B %.4f C %.4f all %.4f TPH_all %.4f\n", m(r$A), m(r$B), m(r$C), m(r$Dall), m(r$TPHall)))
print(summary(r[, .(A, B, C)]))
