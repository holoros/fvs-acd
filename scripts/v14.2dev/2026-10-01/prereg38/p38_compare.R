suppressMessages(library(data.table)); A <- "/home/aaron/jobs/v142p38/assembled"
m <- fread("p38_verify_DATA_2026-10-01.csv", colClasses = "character")
mv <- function(i, a) as.numeric(m[item == i & arm == a, value])
h <- fread(file.path(A, "gyr142-p38-hinc_DATA_2026-10-01.csv"))[tagkey == "field tag" & set == "qc_c"]
ga <- fread(file.path(A, "gyr142-p38-gates-all_DATA_2026-10-01.csv"))
ss <- fread(file.path(A, "gyr142-p38-stands-summary_DATA_2026-10-01.csv"))[set == "qc_c" & pop == "screened B"]
h0 <- fread(file.path(A, "gyr142-p38-H0_DATA_2026-10-01.csv")); k1 <- fread(file.path(A, "gyr142-p38-K1_DATA_2026-10-01.csv"))
R <- list(); ad <- function(i, a, mine, theirs, src) R[[length(R) + 1]] <<- data.table(item = i, arm = a, mine = mine, theirs = theirs, source = src)
ad("tag_records_foldA", "fieldtag", mv("tag_records_foldA", "fieldtag"), h[fold == "A" & group == "overall" & arm == "p19_a0111", trees], "hinc trees fold A")
ad("tag_records_foldB", "fieldtag", mv("tag_records_foldB", "fieldtag"), h[fold == "B" & group == "overall" & arm == "p19_a0111", trees], "hinc trees fold B")
ad("tag_sites_foldB", "fieldtag", mv("tag_sites_foldB", "fieldtag"), h[fold == "B" & group == "overall" & arm == "p19_a0111", sites], "hinc sites fold B")
gm <- c(lt12.7 = "below 12.7", `12.7to25` = "12.7 to 25", ge25 = "25 and over")
for (a in c("p38_fit", "p19_a0111", "p28b_small", "p23_a1061")) { hb <- h[fold == "B" & arm == a]
  ad("hinc_n_foldB", a, mv("hinc_n_foldB", a), hb[group == "overall", trees], "hinc")
  ad("hinc_ratio", a, mv("hinc_ratio", a), hb[group == "overall", ratio], "hinc")
  for (cl in names(gm)) ad(paste0("hinc_bias_", cl), a, mv(paste0("hinc_bias_", cl), a), hb[group == gm[cl], bias_m_yr], "hinc")
  ad("dom_level", a, mv("dom_level", a), hb[group == "dominant", level_t2], "hinc")
  ad("dom_n", a, mv("dom_n", a), hb[group == "dominant", trees], "hinc") }
for (a in c("p38_fit", "p19_a0111", "p23_a1061")) { s <- ss[arm == a]; g <- ga[arm == a]
  ad("stand_n_foldB", a, mv("stand_n_foldB", a), s$stands, "stands-summary")
  ad("topht_bias_pct", a, mv("topht_bias_pct", a), s$topht_bias_pct, "stands-summary")
  ad("topht_bias_pct(gates)", a, mv("topht_bias_pct", a), g$topht, "gates-all")
  ad("c1_rmse_pct", a, mv("c1_rmse_pct", a), s$C1_rmse_pct, "stands-summary")
  ad("c1_rmse_pct(gates)", a, mv("c1_rmse_pct", a), g$rmse, "gates-all")
  ad("ba_ratio", a, mv("ba_ratio", a), s$ba_ratio, "stands-summary")
  ad("ba_pts(gates)", a, 100 * abs(mv("ba_ratio", a) - 1), g$ba_pts, "gates-all, 100|r-1|")
  ad("stems_ratio", a, mv("stems_ratio", a), s$stems_ratio, "stands-summary")
  ad("stems_pts(gates)", a, 100 * abs(mv("stems_ratio", a) - 1), g$stems_pts, "gates-all, 100|r-1|") }
ad("K1_runok_not1_qc_c_all", "p38_fit", mv("K1_runok_not1_qc_c_all", "p38_fit"), k1[arm == "p38_fit" & set == "qc_c", not_ok], "K1")
ad("H0_stands", "p38_one", mv("H0_stands", "p38_one"), sum(h0$stands), "H0")
ad("H0_trees", "p38_one", mv("H0_trees", "p38_one"), sum(h0$trees), "H0")
ad("H0_worst_stand_scaled", "p38_one", mv("H0_worst_stand_scaled", "p38_one"), max(h0$worst_results), "H0")
ad("H0_worst_tree_all", "p38_one", max(sapply(c("ht", "dbh", "expf", "ing"), function(k) mv(paste0("H0_worst_tree_", k), "p38_one"))), max(h0$worst_trees), "H0")
gp <- ga[arm == "p38_fit"]
ad("gate_class_worst_excess", "p38_fit", max(sapply(names(gm), function(cl) mv(paste0("gate_class_excess_", cl), "p38_fit"))), gp$worst_class_worse_by, "gates-all")
ad("gate_V2_diff", "p38_fit", mv("gate_V2_diff", "p38_fit"), gp$rmse_ref - gp$rmse, "gates-all rmse_ref-rmse")
ad("gate_B1_excess_pts", "p38_fit", mv("gate_B1_excess_pts", "p38_fit"), gp$ba_pts - gp$ba_ref_pts, "gates-all")
ad("gate_B2_excess_pts", "p38_fit", mv("gate_B2_excess_pts", "p38_fit"), gp$stems_pts - gp$stems_ref_pts, "gates-all")
ad("gate_dom_excess", "p38_fit", mv("gate_dom_excess", "p38_fit"), abs(gp$dom_level - 1) - (abs(gp$dom_ref - 1) + 0.02), "gates-all")
pm <- c(H1 = "p_H1", HC = "p_CLS", TOPHT_level = "p_TOPHT_only", TOPHT_dom = "p_DOM_only", V2 = "p_V2", B1 = "p_B1", B2 = "p_B2")
for (k in names(pm)) ad(paste0("gate_pass_", k), "p38_fit", mv(paste0("gate_pass_", k), "p38_fit"), as.numeric(gp[[pm[k]]]), "gates-all")
O <- rbindlist(R); O[, absdiff := abs(mine - theirs)]; O[, agree := absdiff <= 1e-9]
vt <- readLines(file.path(A, "gyr142-p38-verdict_DATA_2026-10-01.txt")); vt <- sub("^verdict=", "", grep("^verdict=", vt, value = TRUE))
vm <- m[item == "verdict", value]; vagree <- grepl("Rule 4", vt) && grepl("TOPHT", vm) && grepl("not adopted", vt) && grepl("not adopted", vm)
O[, `:=`(mine = sprintf("%.17g", mine), theirs = sprintf("%.17g", theirs), absdiff = sprintf("%.3g", absdiff))]
O <- rbind(O, data.table(item = "verdict", arm = "p38_fit", mine = vm, theirs = vt, source = "verdict txt", absdiff = NA, agree = vagree))
fwrite(O, "p38_verify_compare_DATA_2026-10-01.csv")
cat("items", nrow(O), "agree", sum(O$agree), "\n"); print(O[agree == FALSE]); cat("worst numeric diff", max(as.numeric(O$absdiff), na.rm = TRUE), "\n")
print(O[order(-as.numeric(absdiff))][1:3, .(item, arm, absdiff)])
