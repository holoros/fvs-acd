## PREREG50 assembly (plan revision 1, md5 6ea850d4): copies the identifier free step outputs of out/ to
## assembled/gyr142-p50-<name>_DATA_2026-10-28.csv (SERVERONLY files are never copied), checks that no copied file holds a
## stand or site identifier of the run, and writes the verdict text. Refuses to overwrite. No em dashes.
## Usage: Rscript p50_assemble.R <outdir of the chain>
source("/home/aaron/jobs/v142p50/scripts/p50_common.R")
AS <- file.path(J, "assembled"); dir.create(AS, showWarnings = FALSE)
fs <- list.files(OUTD, "^p50-.*\\.csv$"); fs <- fs[!grepl("SERVERONLY", fs)]
L <- fread(file.path(OUTD, "p50-stands_SERVERONLY.csv"), colClasses = list(character = c("STAND", "SITE")))
ids <- unique(c(L$STAND, L$SITE))
for (f in fs) { txt <- readLines(file.path(OUTD, f)); hit <- any(vapply(ids, function(s) any(grepl(s, txt, fixed = TRUE)), TRUE))
  if (hit) stop("identifier found in ", f)
  d <- file.path(AS, sprintf("gyr142-%s_DATA_2026-10-28.csv", sub("\\.csv$", "", f))); if (file.exists(d)) stop("REFUSE overwrite ", d)
  file.copy(file.path(OUTD, f), d); cat("assembled", basename(d), "\n") }
V <- fread(file.path(OUTD, "p50-verdict.csv")); DEC <- fread(file.path(OUTD, "p50-decision.csv"))
g <- DEC[gated == TRUE]; s <- DEC[fold == "B" & pop == "floor 9.1 to 9.7 cm"]
vt <- c(sprintf("Verdict (fold B, all screened stands): %s", V[item == "verdict"]$value),
  sprintf("Labels: %s", V[item == "labels"]$value),
  sprintf("X_E1 %.4f (%.4f to %.4f); X_S2 %.4f (%.4f to %.4f); D_R0 %.0f, D_E1 %.0f, D_S2 %.0f", g$X_E1, g$X_E1_lo, g$X_E1_hi, g$X_S2, g$X_S2_lo, g$X_S2_hi, g$D_R0, g$D_E1, g$D_S2),
  sprintf("Floor 9.1 to 9.7 cm group (153 stands expected): %s", s$rule),
  V[item == "survivor ratio note"]$value, "No outcome changes 14.2.", "P50_ASSEMBLE_DONE")
vf <- file.path(AS, "gyr142-p50-verdict_DATA_2026-10-28.txt"); if (file.exists(vf)) stop("REFUSE overwrite verdict")
writeLines(vt, vf); cat(vt, sep = "\n")
