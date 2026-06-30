# AcadianGY_12.7.0.r: integrated operational version. Base 12.6.5 (Kuehne 2022 DG,
# validated ESI via csi slot, expected-value ingrowth, SDImax self-thinning, gated
# mort.cut.scale and size-form hooks) plus the fitted ESI dominant-height anchor from
# 12.6.2b (k=0.0039, p=0.726, base 50; gated ops$use.esi.domht). All refinements gated;
# legacy positions reproduce 12.5.0 / 12.6.1.
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.5.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.7.0.r"
lines <- readLines(src, warn=FALSE)
blk <- c(
"",
"  # ---- v12.7.0: ESI-anchored dominant height (fitted Chapman-Richards, ESI v8) ----",
"  .edh_on = tryCatch(if (!is.null(ops$use.esi.domht)) isTRUE(ops$use.esi.domht) else FALSE, error=function(e) FALSE)",
"  if (.edh_on) {",
"    .k <- 0.0039; .p <- 0.726; .base <- 50",
"    .esi <- tryCatch(as.numeric(stand$csi), error=function(e) NA_real_)",
"    .age0 <- tryCatch(if (!is.null(ops$esi.domht.age0) && !is.na(ops$esi.domht.age0)) ops$esi.domht.age0 else 0, error=function(e) 0)",
"    .gain <- tryCatch(if (!is.null(ops$esi.domht.gain) && !is.na(ops$esi.domht.gain)) ops$esi.domht.gain else 1, error=function(e) 1)",
"    .age <- .age0 + tree$year[1]",
"    if (is.finite(.esi) && .esi > 2 && .age > 0) {",
"      .Aasym <- .esi / ((1 - exp(-.k*.base))^.p)",
"      .target <- .Aasym * (1 - exp(-.k*.age))^.p",
"      .spl <- split(seq_len(nrow(tree)), tree$plot); .cf <- rep(1, nrow(tree))",
"      for (.ix in .spl) {",
"        g <- tree[.ix, ]; o <- order(-g$dbh); e <- g$expf[o]; cw <- cumsum(e)",
"        kk <- which(cw >= 100)[1]; if (is.na(kk)) kk <- length(e)",
"        topht <- weighted.mean(g$ht[o][seq_len(kk)], e[seq_len(kk)], na.rm=TRUE)",
"        cf <- if (is.finite(topht) && topht > 1.5) 1 + .gain*(.target/topht - 1) else 1",
"        .cf[.ix] <- min(1.3, max(0.7, cf))",
"      }",
"      tree$ht <- pmax(1.3, tree$ht * .cf)",
"      tree$cr <- pmax(0, pmin(1, 1 - (tree$hcb / tree$ht)))",
"    }",
"  }",
"")
ix <- grep("cr= 1-(hcb/ht))", lines, fixed=TRUE)
if (length(ix) != 1) stop(sprintf("anchor count=%d", length(ix)))
lines <- append(lines, blk, after=ix)
# version header note
hx <- grep("# 12.6.5 (interim size-form ddbh modifier on the Kuehne 2022 base; gated)", lines, fixed=TRUE)
if (length(hx) == 1) {
  lines <- append(lines, c(
    "# 12.7.0 (integrated operational: + fitted ESI dominant-height anchor, gated ops$use.esi.domht)",
    "#   - Htop(age)=A*(1-exp(-k*age))^p, k=0.0039 p=0.726 base 50; ESI sets A via base-age value.",
    "#   - operational config: Kuehne 2022 DG, ESI site driver + this anchor, ev ingrowth, sdimort;",
    "#     mort.cut.scale and ddbh.sizeform gated off by default."), after = hx - 1)
}
writeLines(lines, dst)
cat("WROTE", dst, "\n")
cat("PARSE_OK:", tryCatch({ parse(file = dst); TRUE }, error = function(e) { cat(conditionMessage(e), "\n"); FALSE }), "\n")
txt <- paste(readLines(dst), collapse = "")
cat("hooks esi.domht/cut.scale/sizeform:", grepl("use.esi.domht", txt, fixed = TRUE),
    grepl("mort.cut.scale", txt, fixed = TRUE), grepl("use.ddbh.sizeform", txt, fixed = TRUE), "\n")
cat("Kuehne coeff present:", grepl("0.37697814748048", txt, fixed = TRUE), "\n")
