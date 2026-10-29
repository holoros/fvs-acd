## PREREG49 survival step switch, form sf_fr (choice 1a). An overlay sourced after the engine (MODEL_FILE, AcadianGY_14.0.4.r)
## and the 14.1 overlay, before make_ops; it edits no engine file. Pattern of the PREREG45 and PREREG46 multiplier switches:
## an environment switch, default off, refused when malformed, and an optional trace hook.
##   SF_FORM unset: nothing is rebound (off is v141LTfi exactly).
##   SF_FORM=fr: calc_mortality is wrapped. With p_t = 1 - dexpf/expf the engine's annual survival of the record and H_t the
##     record's cumulative engine hazard before year t (sum of -log p_u over the record's earlier years in this projection,
##     carried on the record as column sf_H; 0 at the start of a projection and for ingrowth), the record's annual survival
##     becomes 1 - (1 - p_t)/(1 + SF_THETA H_t), that is dexpf/(1 + SF_THETA H_t). make_ops is wrapped so the engine returns
##     sf_H with each record. SF_THETA must be finite and at or above 0; 0 is the null.
##   SF_TRACE (a SERVERONLY file path, optional): every wrapped call is appended there; unset, nothing is written.
## No coordinates. No em dashes.
SF_FORM <- Sys.getenv("SF_FORM", "")
if (nzchar(SF_FORM)) {
  if (SF_FORM != "fr") stop("PREREG49: SF_FORM must be fr or unset")
  SF_THETA <- suppressWarnings(as.numeric(Sys.getenv("SF_THETA", "")))
  if (length(SF_THETA) != 1L || !is.finite(SF_THETA) || SF_THETA < 0) stop("PREREG49: SF_THETA must be finite and at or above 0")
  if (!exists("calc_mortality") || !exists("make_ops")) stop("PREREG49: overlay sourced before the engine")
  .p49_cm0 <- calc_mortality; .p49_mo0 <- make_ops
  make_ops <- function(...) { o <- .p49_mo0(...); o$rtn.vars[[1]] <- unique(c(o$rtn.vars[[1]], "sf_H")); o }
  .p49_tr <- Sys.getenv("SF_TRACE", ""); .p49_k <- 0L; .p49_st <- ""
  calc_mortality <- function(tree.data, plot.data, ...) {
    out <- .p49_cm0(tree.data, plot.data, ...)
    if (nrow(out) != nrow(tree.data) || !identical(out$tree, tree.data$tree)) stop("PREREG49: calc_mortality changed the record set or order")
    e <- tree.data$expf; d0 <- out$dexpf
    H <- if ("sf_H" %in% names(tree.data)) as.numeric(tree.data[["sf_H"]]) else rep(0, nrow(tree.data)); H[!is.finite(H)] <- 0
    p <- 1 - d0 / e; h <- ifelse(is.finite(p) & is.finite(e) & e > 0, -log(pmin(1, pmax(p, 1e-12))), 0)
    out$dexpf <- d0 / (1 + SF_THETA * H); out$sf_H <- H + h
    if (nzchar(.p49_tr)) { sid <- tryCatch(as.character(stand$stand.id)[1], error = function(e) NA_character_)
      if (!identical(sid, .p49_st)) { .p49_st <<- sid; .p49_k <<- 0L }; .p49_k <<- .p49_k + 1L
      data.table::fwrite(data.table::data.table(STAND = sid, call = .p49_k, tree = tree.data$tree, year = tree.data$year, expf = e, dexpf_eng = d0, H = H, dexpf = out$dexpf),
        .p49_tr, append = file.exists(.p49_tr)) }
    out }
  cat(sprintf("PREREG49 survival switch ON: form fr, theta %.15g, trace %s\n", SF_THETA, if (nzchar(.p49_tr)) "on" else "off"))
} else cat("PREREG49 survival switch OFF (SF_FORM unset): nothing rebound\n")
