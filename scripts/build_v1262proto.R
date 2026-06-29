# Prototype AcadianGY_12.6.2_proto.r from 12.6.1: add a GATED ESI-anchored
# dominant-height constraint. Each step, the plot top height is pulled toward a
# dominant-height curve whose asymptote IS the ESI (site index, m), and tree
# heights are rescaled to match. OFF by default; this is an exploration.
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.1.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.2_proto.r"
txt <- paste(readLines(src, warn=FALSE), collapse="\n")
lines <- strsplit(txt,"\n",fixed=TRUE)[[1]]

blk <- c(
"",
"  # ---- v12.6.2 PROTOTYPE: ESI-anchored dominant-height constraint (opt-in) ----",
"  # Pull plot top height toward a dominant H-D curve whose asymptote is the ESI",
"  # (site index, m, carried in the csi slot), then rescale tree heights to match.",
"  # Forces ordered, well-separated site curves. ops$use.esi.domht=FALSE => 12.6.1.",
"  .edh_on = tryCatch(if (!is.null(ops$use.esi.domht)) isTRUE(ops$use.esi.domht) else FALSE, error=function(e) FALSE)",
"  if (.edh_on) {",
"    .A = tryCatch(as.numeric(stand$csi), error=function(e) NA_real_)",
"    .gain = tryCatch(if (!is.null(ops$esi.domht.gain) && !is.na(ops$esi.domht.gain)) ops$esi.domht.gain else 1, error=function(e) 1)",
"    if (is.finite(.A) && .A > 2) {",
"      .spl = split(seq_len(nrow(tree)), tree$plot)",
"      .cf  = rep(1, nrow(tree))",
"      for (.ix in .spl) {",
"        g = tree[.ix, ]; o = order(-g$dbh); e = g$expf[o]; cw = cumsum(e)",
"        k = which(cw >= 100)[1]; if (is.na(k)) k = length(e)",
"        topht = weighted.mean(g$ht[o][seq_len(k)], e[seq_len(k)], na.rm=TRUE)",
"        dtop  = weighted.mean(g$dbh[o][seq_len(k)], e[seq_len(k)], na.rm=TRUE)",
"        target = 1.3 + (.A - 1.3) * (1 - exp(-0.04 * dtop))^1.2",
"        cf = if (is.finite(topht) && topht > 1.5) 1 + .gain*(target/topht - 1) else 1",
"        cf = min(1.3, max(0.7, cf)); .cf[.ix] = cf",
"      }",
"      tree$ht = pmax(1.3, tree$ht * .cf)",
"      tree$cr = 1 - (tree$hcb / tree$ht)",
"    }",
"  }",
"")
ix <- grep("cr= 1-(hcb/ht))", lines, fixed=TRUE)
if (length(ix)!=1) stop(sprintf("anchor count=%d", length(ix)))
lines <- append(lines, blk, after=ix)
txt <- paste(lines, collapse="\n")
# version header
txt <- sub("# 12.6.1 (ingrowth refinement; volume and value validated across NB/NS/ME)",
  paste("# 12.6.2-proto (EXPLORATION: ESI-anchored dominant-height constraint, ops$use.esi.domht)",
        "#   - pulls plot top height onto a dominant H-D curve with asymptote = ESI, rescales heights;",
        "#   - addresses the Bakuzis finding that CSI-nudged H-D barely separates site curves. Gated, default OFF.",
        "# 12.6.1 (ingrowth refinement; volume and value validated across NB/NS/ME)", sep="\n"),
  txt, fixed=TRUE)
writeLines(txt, dst)
cat("WROTE", dst, "\n")
cat("PARSE_OK:", tryCatch({parse(file=dst);TRUE}, error=function(e){cat(conditionMessage(e),"\n");FALSE}), "\n")
