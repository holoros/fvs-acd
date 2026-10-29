## PREREG44 assembly dry test on synthetic trajectories (no model run): writes fake out files and gate files under dry/fake,
## shaped like the slgrid output, so the assembly can be exercised before the chain. Never read by the real assembly.
suppressMessages(library(data.table)); J <- "/home/aaron/jobs/v142p44"; FD <- file.path(J, "dry/fake"); dir.create(file.path(FD, "out"), recursive = TRUE, showWarnings = FALSE)
SL <- fread(file.path(J, "plan/stands_p44_SERVERONLY.csv"), colClasses = list(character = "STAND")); set.seed(1)
for (ar in c("qc141", "p38_fit")) for (b in 1:3) { s <- SL[sdi_bin == b]
  d <- rbindlist(lapply(seq_len(nrow(s)), function(i) { ag <- 0:100; h <- 8 + s$esi8[i]*0.9*(1 - exp(-0.03*(ag + 10))) * (if (ar == "p38_fit") 1.03 else 1)
    q <- 12 + 0.25*ag; tph <- pmin(s$TPH4[i]*1.5, 10^(5.09 - 1.469*log10(q)) * 0.7)
    data.table(arm = ar, cell = s$cell[i], mix = "OBS", esi = s$esi8[i], n0 = s$TPH4[i], age = ag, HT = h, TPH = tph, BAPH = tph*pi*(q/200)^2, QMD = q, SDI = tph*(q/25)^1.605,
      VOL = tph*pi*(q/200)^2*h*0.45, MERCHVOL = 0, TPH_s = tph*0.9, BAPH_s = tph*0.9*pi*(q/200)^2, VOL_s = 0, TPH_all = c(s$TPH4[i], tph[-1]*1.2), TPH_cohort = tph*0.8,
      TPH_ing = 0, TPH_cohort_ge25 = 0, DHTM_cohort = 1, DHTM_cohort_ge25 = NA, DHTM_ing = 1, nrec = 50, smd = 9.1, STAND = s$STAND[i], esi_bin = s$esi_bin[i], sdi_bin = b, run_ok = 1L) }))
  fwrite(d, file.path(FD, sprintf("out/traj_%s_S%d.csv", ar, b))) }
fwrite(data.table(gate = "G0", pass = TRUE), file.path(FD, "g0_result.csv")); fwrite(data.table(gate = "G0b", pass = TRUE), file.path(FD, "g0b_result.csv")); cat("FAKE_DONE\n")
