# Aggregate observed vs predicted (BASE, 3B) decomposition components (m3/ha) for fig17.
# Reads existing per-stand predicted decomp CSVs + observed pooled decomp CSVs.
# Aggregate-only output (no per-stand/tree data), safe to leave the node.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

pred_mean <- function(file, src, config) {
  p <- fread(file)
  data.table(SOURCE=src, CONFIG=config, WHICH="predicted", n=nrow(p),
    V_t1=mean(p$TOTVOL_t1), sg_V=mean(p$V_sg_p), mo_V=mean(p$V_mo_p), ig_V=mean(p$V_ig_p),
    net_V=mean(p$V_sg_p - p$V_mo_p + p$V_ig_p), V_t2_p=mean(p$TOTVOL_p))
}

out <- list()

# ---- BASE predicted (v12.10.1), from existing decomp_*_results.csv ----
out[["base_baxter"]]   <- pred_mean("decomp_baxter_results.csv",   "baxter",   "BASE")
out[["base_me_fia_l"]] <- pred_mean("decomp_me_fia_l_results.csv", "me_fia_l", "BASE")

# CTRN base predicted: use decomp_ctrn_pooled.csv directly (already aggregated with harv term=0)
ctrn_base <- fread("decomp_ctrn_pooled.csv")
cb <- ctrn_base[WHICH=="predicted"]
out[["base_ctrn"]] <- data.table(SOURCE="ctrn", CONFIG="BASE", WHICH="predicted", n=cb$n,
  V_t1=cb$V_t1, sg_V=cb$sg_V, mo_V=cb$mo_V, ig_V=cb$ig_V, net_V=cb$net_V, V_t2_p=cb$V_t2)

# ---- 3B predicted (v12.11 levers), from decomp3b_*_results.csv ----
out[["3b_baxter"]] <- pred_mean("decomp3b_baxter_results.csv", "baxter", "3B")
out[["3b_ctrn"]]   <- pred_mean("decomp3b_ctrn_results.csv",   "ctrn",   "3B")
if (file.exists("decomp3b_me_fia_l_results.csv")) {
  out[["3b_me_fia_l"]] <- pred_mean("decomp3b_me_fia_l_results.csv", "me_fia_l", "3B")
}

# ---- Observed (config-invariant; same t1/t2 tree lists under BASE and 3B) ----
obs_pooled <- fread("obs_decomp_pooled.csv")   # baxter, me_fia_l, silc_l
ctrn_obs <- ctrn_base[WHICH=="observed"]

obs_rows <- list()
for (s in c("baxter","me_fia_l")) {
  r <- obs_pooled[SRC==s]
  obs_rows[[s]] <- data.table(SOURCE=s, CONFIG="OBS", WHICH="observed", n=r$n_stand,
    V_t1=r$V_t1, sg_V=r$sg_V, mo_V=r$mo_V, ig_V=r$ig_V, net_V=r$net_V, V_t2_p=r$V_t2)
}
obs_rows[["ctrn"]] <- data.table(SOURCE="ctrn", CONFIG="OBS", WHICH="observed", n=ctrn_obs$n,
  V_t1=ctrn_obs$V_t1, sg_V=ctrn_obs$sg_V, mo_V=ctrn_obs$mo_V, ig_V=ctrn_obs$ig_V,
  net_V=ctrn_obs$net_V, V_t2_p=ctrn_obs$V_t2)

final <- rbindlist(c(out, obs_rows), fill=TRUE)
fwrite(final, "fig17_decomp_agg.csv")
print(final)
cat("\nDONE\n")
