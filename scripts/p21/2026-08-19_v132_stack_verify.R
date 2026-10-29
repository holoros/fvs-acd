## Pass 21 pre-flight: verify the v13.2 (site-fsm calc_ddbh patch) + ship18 r2 refit (ddbh patch)
## stack correctly, in the order the p21 harness uses, before any batch array is submitted.
## Result this pass: STACK_VERIFY PASS. Verified by CALLING ddbh() with fixed test inputs at each
## stage rather than inspecting a global marker variable, because model_b0b1b2.r's ddbh() hardcodes
## b0/b1/b2 as literals inside its own body (does not read .B0NEW at call time), so
## environment(ddbh)$.B0NEW only shows whether the LAST-SOURCED script defined that global, not
## which ddbh body is actually active.
suppressMessages(library(dplyr))
setwd("~/magplot/verify")
MODEL_FILE <- "~/magplot/verify/p4e/model_b0b1b2.r"
Sys.setenv(B0NEW="-1.88365516930746", B1NEW="0.497878016309701", B2NEW="-0.0293425859449079")
call_ddbh <- function() ddbh(dbh=20, cr=0.4, bal.sw=5, bal.hw=2, csi=16,
                              ddbh.b0.spp=0.01, ddbh.b2.spp=-0.001, ddbh.b3.spp=0.02,
                              ddbh.b4.spp=-0.01, ht=18)
cat("== step 1: source MODEL_FILE (r2 refit) ==\n")
source(MODEL_FILE)
out1 <- call_ddbh()
calc_ddbh_shipped_ref <- calc_ddbh
cat("ddbh(test) after step1 (patched, expect != shipped):", out1, "\n")
cat("\n== step 2: source v132 overlay defs (re-sources plain AcadianGY_13.1.r internally) ==\n")
source("~/magplot/verify/p20_v132/2026-08-19_v132_sitefsm_overlay_WIP.R")
out2 <- call_ddbh()
cat("ddbh(test) after step2 (expect RESET to shipped, unpatched):", out2, "\n")
cat("\n== step 3: re-source MODEL_FILE to reapply the ddbh patch ==\n")
source(MODEL_FILE)
out3 <- call_ddbh()
cat("ddbh(test) after step3 (expect PATCHED again, == out1):", out3, "\n")
cat("\n== step 4: activate_v132() ==\n")
activate_v132()
cat("identical(calc_ddbh, calc_ddbh_v132):", identical(calc_ddbh, calc_ddbh_v132), "\n")
cat("identical(calc_ddbh, calc_ddbh_shipped_ref):", identical(calc_ddbh, calc_ddbh_shipped_ref), "\n")
cat("\n== step 5: confirm calc_ddbh_v132 (bound to calc_ddbh) calls the PATCHED ddbh at run time ==\n")
out5 <- call_ddbh()
cat("ddbh(test) at time of use (expect == out1/out3, patched):", out5, "\n")
ok <- isTRUE(all.equal(out1, out3)) && !isTRUE(all.equal(out1, out2)) &&
      identical(calc_ddbh, calc_ddbh_v132) && !identical(calc_ddbh, calc_ddbh_shipped_ref) &&
      isTRUE(all.equal(out1, out5))
cat("\n=== STACK_VERIFY", if(ok) "PASS" else "FAIL", "===\n")
