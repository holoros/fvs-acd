## 2026-10-16_mefia_ph_class_r1.R
## Revision 1 of the mefia_ph_c classification. The builder (2026-10-16_mefia_ph_frame_builder.R) counted a v0 tree
## as cut only when its v1 record had STATUSCD 3, but this ME_TREE extract holds no STATUSCD 3 rows at v1 of these
## plots: harvested trees are STATUSCD 2 with AGENTCD 80 (human). Here a v0 live merchantable tree (DIA >= 5 in) is
## REMOVED when its v1 record (PREV_TRE_CN) is STATUSCD 3, or STATUSCD 2 with AGENTCD 80 or AGENTCD_NERS 80, or
## absent; DIED is STATUSCD 2 with any other agent. PCT_REMOVED = removed v0 VOLCFNET / v0 VOLCFNET (tree linked);
## PCT_REMOVED_NET = 1 - v1/v0 live merch volume is kept alongside. Harvest type (FCCL common practice rule) is
## recomputed from PCT_REMOVED. Writes a new file; the r0 file is left untouched. Identifiers only, no coordinates.
## No em dashes.
suppressMessages(library(data.table))
W <- "/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work"
f0 <- file.path(W, "mefia_ph_class_DATA_2026-10-16.csv"); f1 <- file.path(W, "mefia_ph_class_DATA_2026-10-16_r1.csv")
if (file.exists(f1)) stop("refusing to overwrite ", f1)
cl <- fread(f0, colClasses = list(character = c("CN_V0", "CN_V1", "CN_V2")))
tr <- fread("/users/PUOM0008/crsfaaron/fia_data/ME_TREE.csv",
            select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA", "TPA_UNADJ", "VOLCFNET", "AGENTCD", "AGENTCD_NERS"),
            colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))
tr <- tr[PLT_CN %in% c(cl$CN_V0, cl$CN_V1)]
v0 <- tr[PLT_CN %in% cl$CN_V0 & STATUSCD == 1 & is.finite(DIA) & DIA >= 5]
v0[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, 6.018)]
v0[, vol := fifelse(is.finite(VOLCFNET), VOLCFNET, 0) * tpa]
v1 <- tr[PLT_CN %in% cl$CN_V1 & !is.na(PREV_TRE_CN) & PREV_TRE_CN != "", .(PREV_TRE_CN, st1 = STATUSCD, ag = AGENTCD, agn = AGENTCD_NERS)]
v0[v1, on = .(CN = PREV_TRE_CN), `:=`(st1 = i.st1, ag = i.ag, agn = i.agn)]
v0[, fate := fifelse(is.na(st1), "missing",
             fifelse(st1 == 3L | (st1 == 2L & (ag %in% 80L | agn %in% 80L)), "cut",
             fifelse(st1 == 2L, "died", fifelse(st1 == 1L, "live", "other"))))]
cat("v0 merchantable tree fates at v1 (trees):\n"); print(v0[, .N, by = fate])
r <- v0[, .(VOL_CUT_FT3AC = sum(vol[fate == "cut"]), VOL_MISSING_FT3AC = sum(vol[fate == "missing"]),
            VOL_DIED_FT3AC = sum(vol[fate == "died"]), VOL0_CHK = sum(vol)), by = .(CN_V0 = PLT_CN)]
cl[, c("VOL_CUT_FT3AC", "VOL_MISSING_FT3AC", "VOL_DIED_FT3AC") := NULL]
cl <- merge(cl, r, by = "CN_V0", all.x = TRUE, sort = FALSE)
for (k in c("VOL_CUT_FT3AC", "VOL_MISSING_FT3AC", "VOL_DIED_FT3AC", "VOL0_CHK")) set(cl, which(is.na(cl[[k]])), k, 0)
cat(sprintf("v0 volume check, max |recomputed - builder| = %.2f ft3/ac\n", max(abs(cl$VOL0_CHK - cl$VOL0_FT3AC))))
cl[, PCT_REMOVED := round(fifelse(VOL0_FT3AC > 0, 100 * (VOL_CUT_FT3AC + VOL_MISSING_FT3AC) / VOL0_FT3AC, NA_real_), 2)]
cl[, PCT_REMOVED_CUTONLY := round(fifelse(VOL0_FT3AC > 0, 100 * VOL_CUT_FT3AC / VOL0_FT3AC, NA_real_), 2)]
cl[, HARVEST_TYPE := fifelse(VOL0_FT3AC < 1200, "low_volume",
                     fifelse(PCT_REMOVED < 35, "light", fifelse(PCT_REMOVED > 65, "heavy", "intermediate")))]
cl[, `:=`(VOL_CUT_FT3AC = round(VOL_CUT_FT3AC, 1), VOL_MISSING_FT3AC = round(VOL_MISSING_FT3AC, 1), VOL_DIED_FT3AC = round(VOL_DIED_FT3AC, 1), VOL0_CHK = NULL)]
cl[, REMOVAL_RULE := "tree_linked_v0_merch_STATUSCD3_or_STATUSCD2_AGENT80_or_absent_at_v1"]
setcolorder(cl, c(setdiff(names(cl), c("PCT_REMOVED_CUTONLY", "HARVEST_TYPE", "REMOVAL_RULE")), "PCT_REMOVED_CUTONLY", "HARVEST_TYPE", "REMOVAL_RULE"))
setorder(cl, STAND)
fwrite(cl, f1)
cat("\nharvest type (r1):\n"); print(cl[, .N, by = HARVEST_TYPE][order(HARVEST_TYPE)])
cat(sprintf("tree-linked vs net removal: cor %.3f, mean %.1f vs %.1f percent\n", cor(cl$PCT_REMOVED, cl$PCT_REMOVED_NET, use = "complete"),
            mean(cl$PCT_REMOVED, na.rm = TRUE), mean(cl$PCT_REMOVED_NET, na.rm = TRUE)))
print(cl[, .(n = .N, vol0_ft3ac = round(mean(VOL0_FT3AC)), vol0_m3ha = round(mean(VOL0_M3HA), 1), rem = round(mean(PCT_REMOVED, na.rm = TRUE), 1),
             qmd0_in = round(mean(QMD0_IN, na.rm = TRUE), 2), qmd1_in = round(mean(QMD1_IN, na.rm = TRUE), 2),
             agb0 = round(mean(AGB0_MGHA), 1), agb1 = round(mean(AGB1_MGHA), 1), agb2 = round(mean(AGB2_MGHA), 1)), by = HARVEST_TYPE][order(HARVEST_TYPE)])
cat(sprintf("%s  %s\n", unname(tools::md5sum(f1)), f1))
cat("CLASS_R1_DONE\n")
