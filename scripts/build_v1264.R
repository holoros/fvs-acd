# AcadianGY_12.6.4.r: gated regional stand-mortality cut scale. The Weiskittel
# (2012) stand mortality only fires where stand.pmort > cut; on Maine stands that
# should self-thin but fall below the cut, mortality is zero (the structural cause
# of the Maine over-prediction). ops$mort.cut.scale scales the cut (default 1 = no
# change; <1 lowers it so more stands receive mortality). Gated; 1.0 reproduces 12.6.1.
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.1.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.4.r"
txt <- paste(readLines(src, warn=FALSE), collapse="\n")
sub1 <- function(s, old, new){ n<-length(gregexpr(old,s,fixed=TRUE)[[1]]); if(!(n==1 && gregexpr(old,s,fixed=TRUE)[[1]][1]!=-1)) stop(sprintf("anchor n=%d: %s",n,substr(old,1,50))); sub(old,new,s,fixed=TRUE) }
txt <- sub1(txt, "stand.mort.ba = ifelse(stand.pmort > stand.prob.parms$cut,",
  "stand.mort.ba = ifelse(stand.pmort > stand.prob.parms$cut * tryCatch(if (!is.null(ops$mort.cut.scale) && !is.na(ops$mort.cut.scale)) ops$mort.cut.scale else 1, error=function(e) 1),")
txt <- sub1(txt, "# 12.6.1 (ingrowth refinement; volume and value validated across NB/NS/ME)",
  paste("# 12.6.4 (regional stand-mortality cut scale; structural fix for the Maine mortality deficit)",
        "#   - ops$mort.cut.scale scales the stand-mortality probability cut (default 1 = 12.6.1;",
        "#     <1 lowers the cut so below-threshold stands receive mortality). Gated, region-set by driver.",
        "# 12.6.1 (ingrowth refinement; volume and value validated across NB/NS/ME)", sep="\n"))
writeLines(txt, dst)
cat("WROTE", dst, "\n"); cat("PARSE_OK:", tryCatch({parse(file=dst);TRUE}, error=function(e){cat(conditionMessage(e),"\n");FALSE}), "\n")
cat("hook present:", grepl("ops$mort.cut.scale", paste(readLines(dst),collapse=""), fixed=TRUE), "\n")
