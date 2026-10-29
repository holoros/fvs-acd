## PREREG36 Parts A1 and A2 (firebreather): QC row index frames against field tag frames. Frames only, no engine
## output, no coordinate column. Whole frames, every stand. No em dashes.
suppressMessages(library(data.table)); library(ggplot2)
J <- "/home/aaron/jobs/v142p36"; RI <- "/home/aaron/jobs/v142p14/in/frames"; FT <- "/home/aaron/jobs/v142p14/in/pass28qc"
key <- c("STAND", "PLOT", "SP", "DBH", "HT", "EXPF", "YEAR")
rd <- function(d, s, tt) { x <- fread(file.path(d, sprintf("bench_gyr_%s_tree_%s.csv", s, tt)), colClasses = list(character = "STAND"))
  x[, rid := paste(do.call(paste, c(.SD, sep = "|")), rowid(do.call(paste, c(.SD, sep = "|"))), sep = "#"), .SDcols = key][] }
A1 <- list(); A2 <- list(); GR <- list(); PR <- list()
for (s in c("qc_c", "qc_fl")) {
  F <- list(); for (sys in c("R", "M")) for (tt in c("init", "t2")) F[[paste(sys, tt)]] <- rd(if (sys == "R") RI else FT, s, tt)
  for (tt in c("init", "t2")) { a <- F[[paste("R", tt)]]; b <- F[[paste("M", tt)]]
    A1[[paste(s, tt)]] <- data.table(set = s, frame = tt, records_R = nrow(a), records_M = nrow(b),
      same_multiset = identical(sort(a$rid), sort(b$rid)), same_order = identical(a$rid, b$rid)) }
  pairs <- function(sys) { a <- F[[paste(sys, "init")]]; b <- F[[paste(sys, "t2")]]
    a <- a[is.finite(TREE) & TREE < 9e6]; b <- b[is.finite(TREE) & TREE < 9e6]
    a <- a[a[, .N, by = .(STAND, TREE)][N == 1L], on = .(STAND, TREE), nomatch = 0L]
    b <- b[b[, .N, by = .(STAND, TREE)][N == 1L], on = .(STAND, TREE), nomatch = 0L]
    m <- merge(a[, .(STAND, TREE, SP1 = SP, DBH1 = DBH, HT1 = HT, r1 = rid)], b[, .(STAND, TREE, SP2 = SP, DBH2 = DBH, HT2 = HT, r2 = rid)], by = c("STAND", "TREE"))
    list(t1 = nrow(F[[paste(sys, "init")]][is.finite(TREE) & TREE < 9e6]), t2 = nrow(F[[paste(sys, "t2")]][is.finite(TREE) & TREE < 9e6]),
         matched = nrow(m), S = m[SP1 == SP2 & is.finite(HT2) & HT2 > 0][, pid := paste(r1, r2, sep = ">")]) }
  pR <- pairs("R"); pM <- pairs("M")
  both <- intersect(pR$S$pid, pM$S$pid); a <- length(both) / nrow(pR$S)
  A2[[s]] <- data.table(set = s, t1_tags = pR$t1, t2_tags = pR$t2, matched_R = pR$matched, matched_M = pM$matched, S_R = nrow(pR$S), S_M = nrow(pM$S),
    S_both = length(both), agreement = a, rule_A = if (a >= 0.99) "convention" else "tag defect")
  g <- rbind(pR$S[!pid %in% both][, grp := "row index only"], pR$S[pid %in% both][, grp := "both"], pM$S[!pid %in% both][, grp := "field tag only"])
  GR[[s]] <- g[, .(n = .N, dbh_shrink_share = mean(DBH2 < DBH1 - 1.0), n_both_ht = sum(is.finite(HT1) & HT1 > 0 & is.finite(HT2) & HT2 > 0),
    ht_shrink_share = mean((HT2 < HT1 - 1.5)[is.finite(HT1) & HT1 > 0 & is.finite(HT2) & HT2 > 0]), dbh_change_median = median(DBH2 - DBH1)), by = grp][, set := s]
  PR[[s]] <- g[, .(set = s, grp, dd = DBH2 - DBH1)]
  rm(F); gc(verbose = FALSE) }
A1 <- rbindlist(A1); A2 <- rbindlist(A2); GR <- rbindlist(GR); setcolorder(GR, "set")
print(A1); print(A2); print(GR)
fwrite(A1, file.path(J, "tables/gyr142-p36-a1-records_DATA_2026-10-01.csv"))
fwrite(A2, file.path(J, "tables/gyr142-p36-a2-agreement_DATA_2026-10-01.csv"))
fwrite(GR, file.path(J, "tables/gyr142-p36-a2-groups_DATA_2026-10-01.csv"))
D <- rbindlist(PR)[set == "qc_c"]; D[, grp := factor(grp, c("row index only", "both", "field tag only"))]
fwrite(D[, .N, by = .(grp, dd = round(dd, 1))][order(grp, dd)], file.path(J, "figs/gyr142-p36-dbhchange_DATA_2026-10-01.csv"))
lab <- GR[set == "qc_c", setNames(sprintf("%s (n = %d)", grp, n), grp)]
p <- ggplot(D[dd >= -15 & dd <= 15], aes(dd)) + geom_histogram(binwidth = 0.5, boundary = 0, fill = "grey35", colour = NA) +
  geom_vline(xintercept = c(-1, 0), linetype = c("dashed", "solid"), linewidth = 0.3) +
  facet_wrap(~ grp, ncol = 1, scales = "free_y", labeller = as_labeller(lab)) +
  labs(x = "DBH at t2 minus DBH at t1 (cm)", y = "Pairs") + theme_classic(base_size = 9) + theme(strip.background = element_blank(), strip.text = element_text(hjust = 0))
ggsave(file.path(J, "figs/gyr142-p36-qc-c2-pairs-dbhchange_2026-10-01.png"), p, width = 180, height = 150, units = "mm", dpi = 300)
cat("P36_A12_DONE\n")
