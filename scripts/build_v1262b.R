# AcadianGY_12.6.2b_proto.r: ESI-anchored dominant height using the FITTED
# Chapman-Richards anchor (k=0.0039, p=0.726, base age 50) from the ESI v8 work,
# replacing the earlier placeholder curve. ESI (site slot) sets the curve that
# passes through ESI at base age 50; stand dominant height is pulled onto it,
# tree heights rescale. Gated ops$use.esi.domht; age via ops$esi.domht.age0 + year.
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.1.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.2b_proto.r"
lines <- readLines(src, warn=FALSE)
blk <- c(
"",
"  # ---- v12.6.2b: ESI-anchored dominant height (fitted Chapman-Richards) ----",
"  # Htop(age) = A*(1-exp(-k*age))^p with k=0.0039, p=0.726 (ESI v8 anchor); A set",
"  # so the curve passes through ESI at base age 50. age = ops$esi.domht.age0 + year.",
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
if (length(ix)!=1) stop(sprintf("anchor count=%d", length(ix)))
lines <- append(lines, blk, after=ix)
writeLines(lines, dst)
cat("WROTE", dst, "\n"); cat("PARSE_OK:", tryCatch({parse(file=dst);TRUE}, error=function(e){cat(conditionMessage(e),"\n");FALSE}), "\n")
