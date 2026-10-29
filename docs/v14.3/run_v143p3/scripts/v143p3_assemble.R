## v143p3_assemble.R
## 14.3 pre-registration 3 (revision 1, md5 20364c4b): assembly. Reads only the identifier free aggregates in out/ (fit3_*,
## frame3_*, conf_*) and the logs, applies the registered decision rule in order, and writes out/assembly_decision_DATA.csv
## and export/ (a copy of every aggregate with a manifest of md5s) for the RESULT. Reads no record level file.
## Usage: Rscript v143p3_assemble.R <root>. Never overwrites. No em dashes.
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]
O <- file.path(ROOT, "out"); L <- file.path(ROOT, "logs"); E <- file.path(ROOT, "export")
fd <- file.path(O, "assembly_decision_DATA.csv"); if (file.exists(fd) || dir.exists(E)) stop("refusing to overwrite")
rd <- function(n) fread(file.path(O, n))
H2B <- rd("fit3_p2repro_h2b_DATA.csv"); FM <- rd("frame3_map_check_DATA.csv"); SUP <- rd("frame3_support_DATA.csv")
SEL <- rd("fit3_selection_DATA.csv"); HV2 <- rd("fit3_hv2_DATA.csv"); POOL <- rd("conf_pooled_DATA.csv")
rec <- readLines(file.path(O, "fit3_selection_record.txt"))
verdict <- sub("^VERDICT: ", "", grep("^VERDICT:", rec, value = TRUE))
selected <- if (grepl("^selected ", verdict)) sub("^selected ([A-Za-z0-9]+) .*$", "\\1", verdict) else NA_character_
r1 <- H2B$pass && FM$unmapped == 0 && FM$d1_vs_engine_d0_maxabs <= 1e-9 && SUP[src == "CTRN", records] == 46521L
r2 <- is.na(selected)
r3 <- if (!r2) isTRUE(HV2$TL_beats_selected) else NA
floors <- POOL[grepl("^sources 1 and 2", pool)]
D <- data.table(rule = c(1, 2, 3, 4, 5),
  test = c("fit-level harness: H2b, FM (CTRN 46,521; mefia_ph_c map), H6, H7", "the fit set selects no form (H0)", "TL beats the selected form by more than one SE",
           "no harm gates N0, N1, N2, R1", "confirmation set meets every registered floor"),
  value = c(sprintf("H2b pass %s (alpha diff %.2e, beta diff %.2e); FM unmapped %d, max |d1 - D0| %.2e; CTRN records %d", H2B$pass, H2B$abs_diff_alpha, H2B$abs_diff_beta,
                    FM$unmapped, FM$d1_vs_engine_d0_maxabs, SUP[src == "CTRN", records]),
            verdict, if (r2) "not reached" else sprintf("TL minus selected %.6g (SE %.6g)", HV2$TL_minus_selected, HV2$se),
            "not evaluated in this registration (engine step deferred)",
            sprintf("heavy %d (floor 30), ESI coverage %.3f (floor 0.80), gated classes %d (floor 3)", floors$heavy_stands, floors$esi_coverage, floors$gated_v1_classes_30)),
  stops_here = c(!r1, r1 & r2, r1 & !r2 & isTRUE(r3), FALSE, r1 & !r2 & !isTRUE(r3) & !isTRUE(floors$all_floors_met)))
outcome <- if (!r1) "no verdict (rule 1)" else if (r2) "H0 (rule 2): 14.3 keeps 14.1's T; C2 stays the documented best form" else
  if (isTRUE(r3)) sprintf("not adopted (rule 3): TL beats %s; HV2 routed to an L or A0 study", selected) else
  if (!isTRUE(floors$all_floors_met)) sprintf("open (rule 5): %s is the documented best form, not adopted; no harm gates not evaluated", selected) else "confirmation step required"
D[, outcome := outcome]
print(D)
fwrite(D, fd); cat(sprintf("%s  %s\n", unname(tools::md5sum(fd)), fd))
dir.create(E); fs <- c(list.files(O, pattern = "(_DATA\\.csv|selection_record\\.txt)$", full.names = TRUE),
  file.path(O, "conf_fb", c("conf_fia_counts_DATA.csv", "conf_fia_survivors_DATA.csv")), file.path(L, c("prereg_md5.txt", "conf_counts_md5.txt", "step2_md5.txt", "selection_md5.txt", "launch_md5s.txt")))
fs <- fs[file.exists(fs)]
for (f in fs) { x <- readLines(f, warn = FALSE); if (any(grepl("NHVT_PH__|MEFIA_PH__|FIA[0-9]{6,}|CTRN_[0-9]", x))) stop("identifier pattern in ", f) }
file.copy(fs, E, copy.date = TRUE)
man <- data.table(file = basename(fs), md5 = unname(tools::md5sum(file.path(E, basename(fs)))))
fwrite(man, file.path(E, "MANIFEST_md5.csv")); print(man)
cat("ASSEMBLE_DONE\n")
