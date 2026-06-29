# Derive run_v126.R from the v125 driver: add v12.6 ops flags + ESI passthrough.
src <- "/users/PUOM0008/crsfaaron/silc_cfi/run_acadiangy_long_v16_v125.R"
dst <- "/users/PUOM0008/crsfaaron/silc_cfi/run_v126.R"
t <- paste(readLines(src, warn=FALSE), collapse="\n")
sub1 <- function(s, old, new){ n<-length(gregexpr(old,s,fixed=TRUE)[[1]]); if(n!=1||gregexpr(old,s,fixed=TRUE)[[1]][1]==-1) stop("anchor: "%+%substr(old,1,40)); sub(old,new,s,fixed=TRUE)}
`%+%` <- function(a,b) paste0(a,b)
flags <- paste(
'if (nzchar(.thr)) ops$ingrowth.thrshld <- as.numeric(.thr)  # 0 => expected-value ingrowth',
'ops$use.sdimort      <- toupper(Sys.getenv("USE_SDIMORT","TRUE")) %in% c("TRUE","T","YES","Y","1")',
'ops$sdimort.beta     <- as.numeric(Sys.getenv("SDIMORT_BETA","0.10"))',
'ops$sdimort.onset    <- as.numeric(Sys.getenv("SDIMORT_ONSET","0.55"))',
'ops$sdimort.max      <- as.numeric(Sys.getenv("SDIMORT_MAX","1.00"))',
'ops$sdimax.site.term <- toupper(Sys.getenv("SDIMAX_SITE_TERM","FALSE")) %in% c("TRUE","T","YES","Y","1")',
'ESI_FLAT <- Sys.getenv("ESI_FLAT","")',
'cat(sprintf("v126: use.sdimort=%s beta=%.2f onset=%.2f max=%.2f siteterm=%s esi=%s\\n", ops$use.sdimort, ops$sdimort.beta, ops$sdimort.onset, ops$sdimort.max, ops$sdimax.site.term, ifelse(nzchar(ESI_FLAT),ESI_FLAT,"NA")))',
sep="\n")
t <- sub1(t, 'if (nzchar(.thr)) ops$ingrowth.thrshld <- as.numeric(.thr)  # 0 => expected-value ingrowth', flags)
t <- sub1(t,
  '  stand <- make_stand(stand.id = sprintf("CFI_%04d", pr$PLOT),\n                      csi = CSI_M, elev = ELEV_M, region = REGION)',
  '  stand <- make_stand(stand.id = sprintf("CFI_%04d", pr$PLOT),\n                      csi = CSI_M, elev = ELEV_M, region = REGION,\n                      esi = if (nzchar(ESI_FLAT)) as.numeric(ESI_FLAT) else NA_real_)')
# default model + output names for v126
t <- sub1(t, 'MODEL_FILE  <- Sys.getenv("MODEL_FILE",  "~/AcadianGY_12.5.0.r")',
              'MODEL_FILE  <- Sys.getenv("MODEL_FILE",  "~/AcadianGY_12.6.0.r")')
writeLines(t, dst)
cat("WROTE", dst, "\n"); cat("PARSE_OK:", tryCatch({parse(file=dst);TRUE}, error=function(e){cat(conditionMessage(e),"\n");FALSE}), "\n")
