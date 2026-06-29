# Build AcadianGY_12.6.1.r from 12.6.0: make expected-value ingrowth the default
# (the statistically correct hurdle-model recruitment), which fixes the documented
# under-recruitment. The expected-value code path already exists (cut.point<=0);
# v12.6.1 makes it the make_ops default and turns ingrowth on by default.
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.0.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.1.r"
txt <- paste(readLines(src, warn=FALSE), collapse="\n")
sub1 <- function(s, old, new){
  n <- length(gregexpr(old, s, fixed=TRUE)[[1]])
  if (!(n==1 && gregexpr(old,s,fixed=TRUE)[[1]][1] != -1)) stop(sprintf("anchor n=%d: %s", n, substr(old,1,50)))
  sub(old, new, s, fixed=TRUE) }

## make_ops defaults: ingrowth on, expected-value recruitment (thrshld 0)
txt <- sub1(txt, "use.ingrowth = FALSE,", "use.ingrowth = TRUE,")
txt <- sub1(txt, "ingrowth.thrshld = 0.95,", "ingrowth.thrshld = 0,")

## version header
txt <- sub1(txt, "# 12.6.0 (site-driver + self-thinning refinements; gated, default-on)",
  paste("# 12.6.1 (ingrowth refinement; volume and value validated across NB/NS/ME)",
        "#   - make_ops() default ingrowth = expected-value recruitment (ingrowth.thrshld = 0,",
        "#     use.ingrowth = TRUE): the statistically correct annualized hurdle-model mean,",
        "#     E[ingrowth] = P(occur) * E[count], replacing the 0.95 occurrence gate that",
        "#     suppressed recruitment on most plot-years and drove the stem-count deficit.",
        "#   - ingrowth.mult retained as a fine calibration knob (default 1.0).",
        "#   - to reproduce 12.6.0/12.5.0 ingrowth: set ingrowth.thrshld = 0.95.",
        "# 12.6.0 (site-driver + self-thinning refinements; gated, default-on)", sep="\n"))

writeLines(txt, dst)
cat("WROTE", dst, "\n")
cat("PARSE_OK:", tryCatch({parse(file=dst);TRUE}, error=function(e){cat(conditionMessage(e),"\n");FALSE}), "\n")
# confirm the two default changes are present
g <- paste(readLines(dst),collapse="\n")
cat("use.ingrowth TRUE default:", grepl("use.ingrowth = TRUE,", g, fixed=TRUE), "\n")
cat("thrshld 0 default:", grepl("ingrowth.thrshld = 0,", g, fixed=TRUE), "\n")
