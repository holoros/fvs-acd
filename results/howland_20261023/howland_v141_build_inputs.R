suppressMessages(library(data.table))
W <- "/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v141_check"
tmpl <- fread("/users/PUOM0008/crsfaaron/acdx_20261016/long200/work/long200_mefia_l_c_pairs_DATA_2026-10-16.csv", nrows = 1)
td <- fread("/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/trees.tab")
td[, PL := sub("^([A-Z]+_[0-9]+).*", "\\1", Plot)]
td <- td[grepl("^HL", PL) & (is.na(Snag) | Snag == "") & DBH >= 10]
td <- td[, .SD[Year == max(Year)], by = PL]
spp <- c(PIRU="RS",TSCA="EH",ACRU="RM",THOC="WC",ABBA="BF",PIST="WP",BEPA="PB",BEPO="GB",BEAL="YB",POGR="BT",POTR="QA",FAGR="AB",UNK="OH")
td[, SP := unname(spp[Species])][is.na(SP), SP := "OH"]
P <- list(); I <- list(); S <- list()
for (e in c(12, 15, 18)) for (pl in unique(td$PL)) {
  st <- sprintf("HOWLAND__%s__2025_2075_E%d", pl, e); site <- sprintf("HOWLAND__%s_E%d", pl, e)
  x <- copy(tmpl); x[, `:=`(STAND = st, SITE = site, interval_years = 50L, ELEV = 60, MANAGED = 0L, Y1 = 2025L, Y2 = 2075L,
                           PLOTKEY = pl, OLD_STAND = st, ESI_OLD = e, N_T1 = nrow(td[PL == pl]), N_T2 = nrow(td[PL == pl]))]
  P[[length(P)+1]] <- x
  t <- td[PL == pl]
  I[[length(I)+1]] <- data.table(STAND = st, PLOT = 1L, TREE = seq_len(nrow(t)), SP = t$SP, DBH = t$DBH, HT = NA_real_, EXPF = 40, YEAR = 2025L)
  S[[length(S)+1]] <- data.table(SITE = site, esi8 = e)
}
P <- rbindlist(P); I <- rbindlist(I)
fwrite(P, file.path(W, "howland_pairs.csv")); fwrite(I, file.path(W, "howland_tree_init.csv"))
fwrite(copy(I)[, YEAR := 2075L], file.path(W, "howland_tree_t2.csv")); fwrite(rbindlist(S), file.path(W, "howland_site_esi.csv"))
cat("stands", nrow(P), "trees", nrow(I), "\n")
