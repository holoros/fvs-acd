# =====================================================================================
# p37 unit probe, part 2: prove the tsurv_hw_mod call-site NA guard is behaviour-neutral.
# 27 August 2026.
#
# The guard is a call-site wrapper. tsurv_hw_mod's body is untouched, so the only question is
# whether every row the surrounding gate ADMITS still reaches tsurv_hw_mod with identical
# arguments and returns an identical value.
#
#   T1  tsurv_hw_mod itself, pre-fix vs post-fix, over a form x dbh x bal x ba.plot x species grid
#       restricted to the gated species. Must be exactly 0.
#   T2  the post-fix call-site expression on a table that MIXES gated hardwoods with softwoods
#       carrying form NA, compared against the pre-fix engine's tsurv_hw_mod evaluated one gated
#       row at a time with 1 for the ungated rows, which is what the ifelse gate intends.
#   T3  the pre-fix call-site expression on that same mixed table, to document the defect.
# =====================================================================================
.libPaths(c("/users/PUOM0008/crsfaaron/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(dplyr); library(tibble); library(purrr)})

H <- "/users/PUOM0008/crsfaaron"
load_engine <- function(p) { e <- new.env(); suppressMessages(sys.source(p, envir = e)); e }
# PREV2 is the state AFTER the calc_ddbh fix and BEFORE the tsurv guard, which is the correct
# pre-fix reference for this second change.
pre131  <- load_engine(file.path(H, "engine_prev_20260827_home/AcadianGY_13.1.r.PREV2_20260827"))
post131 <- load_engine(file.path(H, "AcadianGY_13.1.r"))
pre133  <- load_engine(file.path(H, "engine_prev_20260827_home/AcadianGY_13.3.r.PREV2_20260827"))
post133 <- load_engine(file.path(H, "AcadianGY_13.3.r"))

GATED <- c("RO","YB","RM","PB","QA")
grid <- expand.grid(sp = GATED, form = paste0("F", 1:8),
                    dbh = c(5, 15, 30, 60), bal = c(0, 10, 25, 40), ba.plot = c(5, 20, 45),
                    stringsAsFactors = FALSE)
cat("gated grid rows:", nrow(grid), "\n\n")

bpair <- function(env, sp) {
  tab <- env$tsurv.hw.spp
  i <- match(sp, tab$sp)
  cbind(b0 = tab$b0[i], b1 = tab$b1[i])
}
scalarwise <- function(env, g) {
  bb <- bpair(env, g$sp)
  vapply(seq_len(nrow(g)), function(k)
    tryCatch(as.numeric(env$tsurv_hw_mod(dbh = g$dbh[k], bal = g$bal[k], ba.plot = g$ba.plot[k],
                                         form = g$form[k], b0 = bb[k,1], b1 = bb[k,2])),
             error = function(e) NA_real_), numeric(1))
}

cat("=== T1  tsurv_hw_mod itself, pre-fix vs post-fix ===\n")
for (nm in list(c("pre131","post131","v13.1"), c("pre133","post133","v13.3"))) {
  a <- scalarwise(get(nm[1]), grid); b <- scalarwise(get(nm[2]), grid)
  cat(sprintf("  %s  max abs diff %s   identical() %s   any NA %s\n", nm[3],
              format(max(abs(b - a), na.rm = TRUE), digits = 17), identical(a, b),
              any(is.na(a)) || any(is.na(b))))
}

# ---- mixed table: gated hardwoods plus softwoods with form NA ------------------------
set.seed(20260827)
n <- 400
mix <- data.frame(
  sp   = sample(c(GATED, "SM", "AB", "WA", "BF", "RS", "WS", "BS"), n, replace = TRUE),
  dbh  = round(runif(n,  5, 60), 2),
  bal  = round(runif(n,  0, 40), 2),
  ba.plot = round(runif(n, 5, 45), 2),
  form = NA_character_, stringsAsFactors = FALSE)
hw <- mix$sp %in% c(GATED, "SM", "AB", "WA")
mix$form[hw] <- sample(paste0("F", 1:8), sum(hw), replace = TRUE)   # softwoods keep form NA
cat(sprintf("\nmixed table: %d rows, %d hardwood (form set), %d softwood (form NA)\n",
            n, sum(hw), sum(!hw)))

callsite_post <- function(env, d) {
  tree <- d %>% dplyr::left_join(env$tsurv.hw.spp, by = "sp") %>%
    dplyr::mutate(tsurv.hw.mod = ifelse(!is.na(form) & gsub('[^0-9]', '', form) %in% 1:8 &
                                          sp %in% c('RO','YB','RM','PB','QA') & !is.na(b0),
                                        purrr::pmap_dbl(list(dbh, bal, ba.plot, form, b0, b1),
                                                        env$.tsurvhw_guard), 1))
  tree$tsurv.hw.mod
}
callsite_pre <- function(env, d) {
  tree <- d %>% dplyr::left_join(env$tsurv.hw.spp, by = "sp")
  tryCatch({
    v <- ifelse(!is.na(tree$form) & gsub('[^0-9]', '', tree$form) %in% 1:8 &
                  tree$sp %in% c('RO','YB','RM','PB','QA') & !is.na(tree$b0),
                purrr::pmap_dbl(list(tree$dbh, tree$bal, tree$ba.plot, tree$form, tree$b0, tree$b1),
                                env$tsurv_hw_mod), 1)
    v
  }, error = function(e) paste("ERROR:", conditionMessage(e)))
}
# Intended semantics, computed independently of both call sites: the gate decides, the PRE-fix
# function supplies the value for admitted rows, 1 everywhere else.
intended <- function(env, d) {
  tree <- d %>% dplyr::left_join(env$tsurv.hw.spp, by = "sp")
  ok <- !is.na(tree$form) & gsub('[^0-9]', '', tree$form) %in% 1:8 &
        tree$sp %in% c('RO','YB','RM','PB','QA') & !is.na(tree$b0)
  out <- rep(1, nrow(tree))
  for (k in which(ok))
    out[k] <- as.numeric(env$tsurv_hw_mod(tree$dbh[k], tree$bal[k], tree$ba.plot[k],
                                          tree$form[k], tree$b0[k], tree$b1[k]))
  out
}

cat("\n=== T2  post-fix call site vs intended semantics computed from the PRE-fix function ===\n")
for (nm in list(c("pre131","post131","v13.1"), c("pre133","post133","v13.3"))) {
  want <- intended(get(nm[1]), mix)
  got  <- callsite_post(get(nm[2]), mix)
  cat(sprintf("  %s  max abs diff %s   identical() %s   n gated %d\n", nm[3],
              format(max(abs(got - want)), digits = 17), identical(want, got), sum(want != 1)))
}

cat("\n=== T3  PRE-fix call site on the same mixed table (documents the defect) ===\n")
r1 <- callsite_pre(pre131, mix); r3 <- callsite_pre(pre133, mix)
cat("  v13.1 pre-fix :"); print(if (is.character(r1)) r1[1] else "no error")
cat("  v13.3 pre-fix :"); print(if (is.character(r3)) r3[1] else "no error")

cat("\nPROBE COMPLETE\n")
