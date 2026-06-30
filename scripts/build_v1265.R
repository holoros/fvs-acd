# AcadianGY_12.6.5.r: add a gated interim size-form ddbh modifier on top of the
# robust Kuehne (2022) diameter-increment base. The Kuehne DG is nearly unbiased in
# the mean but shows size-form attenuation (over-predicts small DBH, under-predicts
# large DBH). ops$use.ddbh.sizeform applies a linear correction factor
# cf(dbh) = clamp(a + b*dbh, 0.8, 1.3) that trims small and boosts large increment.
# Default OFF (a=1,b=0 reproduce 12.6.4). This is an interim modifier, NOT a refit;
# the full DG refit needs new data. Built on 12.6.4 (keeps the mort.cut.scale hook).
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.4.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.5.r"
txt <- paste(readLines(src, warn=FALSE), collapse="\n")
sub1 <- function(s, old, new){ n<-length(gregexpr(old,s,fixed=TRUE)[[1]]); if(!(n==1 && gregexpr(old,s,fixed=TRUE)[[1]][1]!=-1)) stop(sprintf("anchor n=%d: %s",n,substr(old,1,60))); sub(old,new,s,fixed=TRUE) }
txt <- sub1(txt,
  "dplyr::mutate(ddbh = ddbh * ddbh.thin.mod * ddbh.sbw.mod * ddbh.form.risk.mod * ddbh.mult)",
  "dplyr::mutate(ddbh = ddbh * ddbh.thin.mod * ddbh.sbw.mod * ddbh.form.risk.mod * ddbh.mult * (if (isTRUE(ops$use.ddbh.sizeform)) pmin(1.3, pmax(0.8, (if (!is.null(ops$ddbh.sf.a)) ops$ddbh.sf.a else 1) + (if (!is.null(ops$ddbh.sf.b)) ops$ddbh.sf.b else 0) * dbh)) else 1))")
txt <- sub1(txt, "# 12.6.4 (regional stand-mortality cut scale; structural fix for the Maine mortality deficit)",
  paste("# 12.6.5 (interim size-form ddbh modifier on the Kuehne 2022 base; gated)",
        "#   - ops$use.ddbh.sizeform applies cf(dbh)=clamp(a+b*dbh,0.8,1.3) to ddbh.",
        "#     Default off (a=1,b=0 reproduce 12.6.4). Addresses Kuehne size-form attenuation.",
        "# 12.6.4 (regional stand-mortality cut scale; structural fix for the Maine mortality deficit)", sep="\n"))
writeLines(txt, dst)
cat("WROTE", dst, "\n"); cat("PARSE_OK:", tryCatch({parse(file=dst);TRUE}, error=function(e){cat(conditionMessage(e),"\n");FALSE}), "\n")
cat("hook:", grepl("use.ddbh.sizeform", paste(readLines(dst),collapse=""), fixed=TRUE), "\n")
