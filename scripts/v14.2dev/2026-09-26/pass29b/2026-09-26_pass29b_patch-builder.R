## Pass 29b: derive the builder from the frozen pass 29 builder by exact line edits (each must match once). No em dashes.
J <- "/home/aaron/jobs/v142p29b"
x <- readLines(file.path(J, "parents/2026-09-26_pass29_frame-builder.R"))
rep1 <- function(x, old, new) { i <- which(x == old); if (length(i) != 1L) stop("pattern matched ", length(i), " times: ", old); append(x[-i], new, after = i - 1L) }
x <- rep1(x, 'TAG_STABLE  <- c(BAXTER = 1L, CTRN = 1L, NS = 1L, NS_LONG = 1L, NSPOOL = 1L, MNAP = 1L)   # pass 29: MNAP carries round 1 TP_ID tags (TreeLink, stem map); untracked rows (Tree 9,000,000 and up) stay out of tag churn [SET ON AUTOPILOT]',
  c('TAG_STABLE  <- c(BAXTER = 1L, CTRN = 1L, NS = 1L, NS_LONG = 1L, NSPOOL = 1L, MNAP = 1L)   # pass 29b: MNAP is now the State owner set only; MNAP_TNC is deliberately NOT tag stable (tag free churn, like NB)',
    '## pass 29b: owner split of MNAP. Owner per plot key from the pass 29 step 1 plot table; plots of any other owner enter neither set.',
    'MNAP_OWN <- fread(Sys.getenv("P29B_OWNERS", "MISSING_P29B_OWNERS"), select = c("PLOTKEY", "Owner"), colClasses = "character")',
    'stopifnot(nrow(MNAP_OWN) > 0, !anyDuplicated(MNAP_OWN$PLOTKEY))',
    'MNAP_SPLIT <- c(MNAP = "State", MNAP_TNC = "TNC")'))
x <- rep1(x, '             MEMAT = "ME_FIA_M", MEDEV = "ME_FIA_M", MNAP = "MNAP", NS = "NS", NS_LONG = "NS",',
             '             MEMAT = "ME_FIA_M", MEDEV = "ME_FIA_M", MNAP = "MNAP", MNAP_TNC = "MNAP", NS = "NS", NS_LONG = "NS",')
x <- rep1(x, '              MEDEV = "fia0_treated_screened_at_source", MNAP = "source0_ecoreserve_PLACEHOLDER",',
             '              MEDEV = "fia0_treated_screened_at_source", MNAP = "source0_ecoreserve_PLACEHOLDER", MNAP_TNC = "source0_ecoreserve_PLACEHOLDER",')
x <- rep1(x, 'VDS <- c(setNames(as.list(ds$Name), ds$Name), list(NSPOOL = c("NS_LONG", "NS")))',
             'VDS <- c(setNames(as.list(ds$Name), ds$Name), list(NSPOOL = c("NS_LONG", "NS"), MNAP_TNC = "MNAP"))   # pass 29b: TNC virtual set over dataset 8')
x <- rep1(x, '  vv <- v[Name %in% mem & n > 0]',
  c('  vv <- v[Name %in% mem & n > 0]',
    '  if (vds %in% names(MNAP_SPLIT)) {   # pass 29b owner split',
    '    keepk <- MNAP_OWN[Owner == MNAP_SPLIT[[vds]], PLOTKEY]',
    '    xadd(vds, "all", "plot_keys_other_owner_excluded", vv[!(PLOTKEY %in% keepk), uniqueN(PLOTKEY)], "plot keys", "pass 29b owner split")',
    '    vv <- vv[PLOTKEY %in% keepk]',
    '  }'))
x <- rep1(x, '  if (vds == "MNAP") lk[, LINK_SRC := "raw"]', '  if (vds %in% c("MNAP", "MNAP_TNC")) lk[, LINK_SRC := "raw"]')
x <- rep1(x, '    } else if (DS == "MNAP") {', '    } else if (DS %in% c("MNAP", "MNAP_TNC")) {')
stopifnot(!any(grepl(intToUtf8(8212L), x, fixed = TRUE)))
writeLines(x, file.path(J, "scripts/2026-09-26_pass29b_frame-builder.R"))
cat("PATCH_DONE\n")
