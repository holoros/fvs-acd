## v143p2_prep.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b): launch inputs. Writes (never overwrites):
##   work/tform_coef_C0f.csv           KEY ALL (C0f takes alpha and beta from the frozen r5 file inside the overlay)
##   work/v143p2_taskmap_harness_DATA.csv   e0off and C0f on the 19 Phase D sets and mefia_ph_c, with PREREG1's chunk
##                                          boundaries (~/v143p1/work/v143_taskmap_DATA.csv, rows of col e0off), so that
##                                          every file can be compared byte for byte with the frozen 14.1 chunk files
##   work/h3_stands_SERVERONLY.csv     the ctrn_c stands of the 500 record H3 sample (STAND_KEEP_FILE for arm trH3)
##   work/v143p2_taskmap_trH3_DATA.csv one task, trH3 on ctrn_c, rows 1 to the kept count
## Usage: Rscript v143p2_prep.R <root> <stage: harness|sealed> ; stage sealed writes the sealed set taskmap for A0
## (and later v141 and SEL) in chunks of 60 stands of the admitted population. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; STAGE <- a[2]
H <- "/users/PUOM0008/crsfaaron"; W <- file.path(ROOT, "work")
nw <- function(x, f) { if (file.exists(f)) stop("exists ", f); fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
if (STAGE == "harness") {
  nw(data.table(KEY = "ALL", alpha = NA_real_, beta = NA_real_, gamma = NA_real_, tau = NA_real_, rlo = NA_real_, rhi = NA_real_), file.path(W, "tform_coef_C0f.csv"))
  tm <- fread(file.path(H, "v143p1/work/v143_taskmap_DATA.csv"))[col == "e0off"]
  hm <- rbind(copy(tm)[, col := "e0off"], copy(tm)[, col := "C0f"])
  hm[, task := seq_len(.N)]
  nw(hm[, .(task, col, chunk, set, from, to)], file.path(W, "v143p2_taskmap_harness_DATA.csv"))
  h3 <- fread(file.path(W, "h3_sample_SERVERONLY.csv"))
  st <- data.table(STAND = sort(unique(h3$STAND)))
  nw(st, file.path(W, "h3_stands_SERVERONLY.csv"))
  nw(data.table(task = 1L, col = "trH3", chunk = 1L, set = "ctrn_c", from = 1L, to = nrow(st)), file.path(W, "v143p2_taskmap_trH3_DATA.csv"))
}
if (STAGE == "sealed") {
  ARMS <- if (length(a) > 2) strsplit(a[3], ",")[[1]] else "A0"
  pr <- fread(file.path(ROOT, "sealed_SERVERONLY", "bench_gyr_nhvt_ph_c_pairs.csv"))
  se <- fread(file.path(ROOT, "sealed_SERVERONLY", "bench_gyr_nhvt_ph_c_site_esi.csv"))
  pr <- merge(pr, se, by = "SITE", all.x = TRUE)
  n <- pr[is.finite(esi8) & esi8 > 2, .N]          # the runner's INDOMAIN population (row order is the runner's)
  ch <- data.table(chunk = seq_len(ceiling(n / 60)))[, `:=`(from = (chunk - 1L) * 60L + 1L, to = pmin(chunk * 60L, n))]
  tm <- rbindlist(lapply(ARMS, function(k) copy(ch)[, `:=`(col = k, set = "nhvt_ph_c")]))[, task := seq_len(.N)]
  nw(tm[, .(task, col, chunk, set, from, to)], file.path(W, sprintf("v143p2_taskmap_sealed_%s_DATA.csv", paste(ARMS, collapse = "_"))))
  cat(sprintf("sealed admitted stands %d of %d, chunks %d\n", n, nrow(pr), nrow(ch)))
}
cat("PREP_DONE\n")
