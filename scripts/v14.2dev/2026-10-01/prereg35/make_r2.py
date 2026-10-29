# Builds the r2 scorer from the frozen PREREG16 scorer by insertion only. No em dashes.
import hashlib, sys
src = "/home/aaron/jobs/v142p28/scripts/2026-09-27_v142_volconv_score.R"
dst = "/home/aaron/jobs/v142p35/scripts/2026-10-01_v142_volconv_score_r2.R"
b = open(src, "rb").read()
assert hashlib.md5(b).hexdigest() == "019df23877abd9e1aab83831d13322dc"
t = b.decode()
def ins_after(t, anchor, add):
    assert t.count(anchor) == 1, anchor
    return t.replace(anchor, anchor + add)
def ins_before(t, anchor, add):
    assert t.count(anchor) == 1, anchor
    return t.replace(anchor, add + anchor)
H1 = "## every input. Aggregates only are written; no coordinates are read or written. No em dashes.\n"
t = ins_after(t, H1,
"## r2 (PREREG35, 2026-10-01): additions only. Adds three checks, reported and not used for admission unless VC_R2_ENFORCE=1:\n"
"## (a) defect gate, a V_o = 0 stand whose source t2 frame holds a live stem at or above SCORE_MINDBH_USED with EXPF > 0;\n"
"## (b) exclusion as harvested or lost only on a positive record; (c) an established at t1 stratum (V_o1 > 0) reported beside\n"
"## the all stands row where more than 5 percent of scored stands have V_o1 = 0. Every PREREG16 output is unchanged.\n")
A2 = "ST <- list(); GT <- list(); SH <- list(); STANDS <- list(); C2COV <- list(); ADM <- list(); ALN <- list()\n"
t = ins_after(t, A2,
"## ---- r2 additions: containers, enforcement switch, stratum threshold, stand basal area and stems at the floor\n"
"DEF <- list(); EXC <- list(); STRS <- list(); STR <- list(); R2ENF <- Sys.getenv(\"VC_R2_ENFORCE\", \"\") == \"1\"; R2THR <- 0.05\n"
"livef <- function(dbh, expf, mindbh) is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0\n"
"bastem <- function(dbh, expf, mindbh) { l <- livef(dbh, expf, mindbh); c(BA = sum(pi / 40000 * dbh[l]^2 * expf[l]), N = sum(expf[l])) }\n")
A3 = "  rm(P, O2, VV, Wall); gc(verbose = FALSE)\n"
t = ins_before(t, A3,
"  ## ---- r2 (PREREG35) checks, reported only. They read copies; VV, Wall and every PREREG16 container are left untouched\n"
"  ## (a) defect gate\n"
"  src2 <- merge(O2[, .(STAND, DBH, EXPF)], sm, by = \"STAND\")[livef(DBH, EXPF, SMD), .(n_src_live = .N), by = STAND]\n"
"  z0 <- VV[V_o == 0, STAND]; dstd <- intersect(z0, src2$STAND)\n"
"  DEF[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, scored = nrow(VV), vo_zero = length(z0), vo_zero_with_source_stem = length(dstd), pass = length(dstd) == 0L)\n"
"  if (length(dstd)) { fwrite(data.table(label = lab, arm = arm, STAND = dstd), file.path(OUT, sprintf(\"r2-defect-stands_SERVERONLY_%s_%s.csv\", lab, arm)))\n"
"    cat(sprintf(\"R2 CHECK A FAIL %s %s: %d V_o = 0 stands hold a live source stem at the floor\\n\", lab, arm, length(dstd)))\n"
"    if (R2ENF) hs(\"R2 check a %s %s: %d defect stands\", lab, arm, length(dstd)) }\n"
"  ## (b) positive record exclusion: stands leave the screened population only through cut_stands(), a treatment record\n"
"  csr <- if (any(VV$cut)) cs else character(0); nrec <- sum(VV$cut & VV$STAND %in% csr)\n"
"  EXC[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, in_results = nrow(r), scored = nrow(VV), not_run_runok = r[RUN_OK != 1, .N],\n"
"    not_run_nonfinite = r[RUN_OK == 1 & !(is.finite(TOTVOL_o) & is.finite(TOTVOL_p)), .N], excluded_harvest = sum(VV$cut), excluded_with_record = nrec,\n"
"    excluded_without_record = sum(VV$cut) - nrec, excluded_lost = 0L, vo_zero_retained = VV[V_o == 0 & cut == FALSE, .N], pass = sum(VV$cut) == nrec)\n"
"  if (sum(VV$cut) != nrec && R2ENF) hs(\"R2 check b %s %s: exclusion without a positive record\", lab, arm)\n"
"  ## (c) established at t1 stratum: observed t1 volume from the source t1 frame, same live filter and floor as V_o\n"
"  F1 <- fread(file.path(pl$fr, sprintf(\"bench_gyr_%s_tree_init.csv\", s)), select = c(\"STAND\", \"SP\", \"DBH\", \"HT\", \"EXPF\"))[, STAND := as.character(STAND)][STAND %in% VV$STAND]\n"
"  v1 <- merge(F1, sm, by = \"STAND\")[, .(V_o1 = totvol(mapsp(SP), DBH, HT, EXPF, SMD[1])), by = STAND]\n"
"  X <- merge(VV[, .(STAND, V_o, V_p, V_oh, V_ph, V_o2, V_p2)], v1, by = \"STAND\", all.x = TRUE); no_t1 <- X[is.na(V_o1), .N]; X[is.na(V_o1), V_o1 := 0]\n"
"  bo <- merge(O2[, .(STAND, DBH, EXPF)], sm, by = \"STAND\")[, { z <- bastem(DBH, EXPF, SMD[1]); .(BA_o = z[[\"BA\"]], N_o = z[[\"N\"]]) }, by = STAND]\n"
"  bp <- merge(P[, .(STAND, dbh, expf)], sm, by = \"STAND\")[, { z <- bastem(dbh, expf, SMD[1]); .(BA_p = z[[\"BA\"]], N_p = z[[\"N\"]]) }, by = STAND]\n"
"  X <- merge(merge(X, bo, by = \"STAND\", all.x = TRUE), bp, by = \"STAND\", all.x = TRUE)\n"
"  for (cc in c(\"BA_o\", \"N_o\", \"BA_p\", \"N_p\")) set(X, which(is.na(X[[cc]])), cc, 0)\n"
"  nz1 <- X[V_o1 == 0, .N]; shr <- nz1 / nrow(X); fires <- shr > R2THR\n"
"  STRS[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, scored = nrow(X), t1_zero = nz1, t1_zero_share = shr, threshold = R2THR, fires = fires,\n"
"    stands_no_t1_rows = no_t1, established = nrow(X) - nz1)\n"
"  for (st in if (fires) c(\"all\", \"established_t1\") else character(0)) { v <- if (st == \"all\") X else X[V_o1 > 0]; W <- Wall[v$STAND, , drop = FALSE]\n"
"    vs <- list(\"volume C0\" = c(\"V_o\", \"V_p\"), \"volume C1\" = c(\"V_oh\", \"V_ph\"), \"volume C2\" = c(\"V_o2\", \"V_p2\"), \"basal area\" = c(\"BA_o\", \"BA_p\"), \"stems\" = c(\"N_o\", \"N_p\"))\n"
"    if (pl$c2 != \"TRUE\") vs[[\"volume C2\"]] <- NULL\n"
"    for (vn in names(vs)) { z <- sc(v[[vs[[vn]][1]]], v[[vs[[vn]][2]]], W)\n"
"      STR[[paste(lab, arm, st, vn)]] <- data.table(label = lab, arm = arm, stratum = st, stands = nrow(v), variable = vn, ratio = z$pt[[\"ratio\"]],\n"
"        ratio_lo = z$ci_ratio[1], ratio_hi = z$ci_ratio[2], bias_pct = z$pt[[\"bias_pct\"]], rmse_pct = z$pt[[\"rmse_pct\"]], rmse_lo = z$ci_rmse[1], rmse_hi = z$ci_rmse[2],\n"
"        sum_o = sum(v[[vs[[vn]][1]]]), sum_p = sum(v[[vs[[vn]][2]]])) } }\n"
"  cat(sprintf(\"R2 %s %s: check a %s (%d V_o = 0, %d with source stem); check b %s; t1 zero %d of %d (%.4f), stratum %s\\n\", lab, arm,\n"
"    if (length(dstd)) \"FAIL\" else \"pass\", length(z0), length(dstd), if (sum(VV$cut) == nrec) \"pass\" else \"FAIL\", nz1, nrow(X), shr, if (fires) \"fires\" else \"not met\"))\n"
"  rm(F1, v1, X, bo, bp, src2)\n")
A4 = "cat(\"VC_DONE\\n\")\n"
t = ins_before(t, A4,
"## ---- r2 outputs (new files only)\n"
"if (length(DEF)) wout(rbindlist(DEF), \"r2defect\")\n"
"if (length(EXC)) wout(rbindlist(EXC), \"r2exclusion\")\n"
"if (length(STRS)) wout(rbindlist(STRS), \"r2stratumshare\")\n"
"if (length(STR)) wout(rbindlist(STR, fill = TRUE), \"r2stratum\")\n")
open(dst, "w").write(t)
print("wrote", dst, hashlib.md5(t.encode()).hexdigest())
