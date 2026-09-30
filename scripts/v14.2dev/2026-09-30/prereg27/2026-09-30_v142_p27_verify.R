## PREREG27 independent re-derivation of the gate cells: separate code path (base R keys and tapply, no p27_lib.R), same
## frozen inputs. Survivor ratio and recruit ratio by fold x set x interval group (5, 6 to 15, 16 to 60; fl sets 21 to 60)
## under v141LTfi, compared with assembled/ gate cells and the fold A diagnosis. No coordinates. No em dashes.
suppressMessages(library(data.table)); library(digest)
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"; H <- "/home/aaron/jobs/v142p22/home/out/v141LTfi"
out <- list()
for (s in c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl")) {
  r <- as.data.frame(fread(sprintf("/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_%s_results.csv", s), select = c("STAND", "SITE", "interval_years", "SCORE_MINDBH_USED", "RUN_OK")))
  r <- r[r$RUN_OK == 1, ]; r$fold <- ifelse(sapply(as.character(r$SITE), function(z) strtoi(substr(digest(z, "md5", serialize = FALSE), 1, 1), 16L)) %% 2 == 0, "A", "B")
  r$grp <- ifelse(r$interval_years <= 5, "iv05", ifelse(r$interval_years <= 15, "iv06_15", "iv16_60"))
  thr <- setNames(r$SCORE_MINDBH_USED, r$STAND)
  i1 <- as.data.frame(fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)), select = c("STAND", "PLOT", "TREE", "DBH", "EXPF")))
  i2 <- as.data.frame(fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", s)), select = c("STAND", "PLOT", "TREE", "DBH", "EXPF")))
  i1 <- i1[i1$STAND %in% r$STAND, ]; i2 <- i2[i2$STAND %in% r$STAND, ]
  k1 <- paste(i1$STAND, i1$PLOT, i1$TREE); k2 <- paste(i2$STAND, i2$PLOT, i2$TREE); d1 <- i1$DBH[match(k2, k1)]
  live <- i2$DBH >= thr[i2$STAND]; sv <- live & !is.na(d1) & d1 >= thr[i2$STAND]
  so <- tapply(i2$EXPF * sv, i2$STAND, sum); ro <- tapply(i2$EXPF * (live & !sv), i2$STAND, sum)
  fs <- list.files(H, sprintf("^c[0-9]+_pred_t2_tree[.]csv$"), full.names = TRUE, recursive = TRUE); fs <- fs[grepl(paste0("/", s, "/"), fs)]
  p2 <- as.data.frame(rbindlist(lapply(fs, fread, select = c("STAND", "tree", "dbh", "expf", "ing"))))
  p1 <- as.data.frame(rbindlist(lapply(sub("pred_t2_tree", "t1_split_tree", fs), fread, select = c("STAND", "tree", "dbh"))))
  p2 <- p2[p2$STAND %in% r$STAND, ]; pd1 <- p1$dbh[match(paste(p2$STAND, p2$tree), paste(p1$STAND, p1$tree))]
  lp <- p2$dbh >= thr[p2$STAND]; spv <- lp & p2$ing == 0 & !is.na(pd1) & pd1 >= thr[p2$STAND]
  sp <- tapply(p2$expf * spv, p2$STAND, sum); rp <- tapply(p2$expf * (lp & !spv), p2$STAND, sum)
  f0 <- function(v) { x <- v[r$STAND]; x[is.na(x)] <- 0; x }
  r$so <- f0(so); r$ro <- f0(ro); r$sp <- f0(sp); r$rp <- f0(rp)
  if (s %in% c("ns_fl", "ns_long_fl")) r$grp <- ifelse(r$interval_years > 20, "iv21_60", "other")
  a <- aggregate(cbind(so, ro, sp, rp) ~ fold + grp, data = r, FUN = sum); a$set <- s; out[[s]] <- a }
V <- rbindlist(out); V[, `:=`(surv_ratio = sp / so, rec_ratio = rp / ro, d_surv_pct = 100 * (sp - so) / (so + ro), d_rec_pct = 100 * (rp - ro) / (so + ro))]
print(V, digits = 4); fwrite(V, "/home/aaron/jobs/v142p27/verify_20260930/gyr142-p27-verify-cells_DATA_2026-09-30.csv")
GC <- fread("/home/aaron/jobs/v142p27/assembled/gyr142-p27-confirm-gatecells-foldB_DATA_2026-09-30.csv")[tab %in% c("iv3", "iv21_60")]
m <- merge(V[fold == "B"], GC[, .(set, grp = iv3, s_ref = surv_ratio, r_ref = rec_ratio)], by = c("set", "grp"))
cat(sprintf("fold B gate cells matched %d, worst survivor diff %.3g, worst recruit diff %.3g\n", nrow(m), max(abs(m$surv_ratio - m$s_ref)), max(abs(m$rec_ratio - m$r_ref))))
cat("VERIFY_DONE\n")
