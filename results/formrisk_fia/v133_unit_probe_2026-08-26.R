suppressMessages({library(dplyr);library(tibble);library(purrr)})
e131 <- new.env(); e133 <- new.env()
suppressMessages(sys.source("/users/PUOM0008/crsfaaron/AcadianGY_13.1.r", envir=e131))
suppressMessages(sys.source("/users/PUOM0008/crsfaaron/AcadianGY_13.3.r", envir=e133))
cat("13.1 has ddbh_hw_mod_fia:", exists("ddbh_hw_mod_fia", envir=e131, inherits=FALSE), "\n")
cat("13.3 has ddbh_hw_mod_fia:", exists("ddbh_hw_mod_fia", envir=e133, inherits=FALSE), "\n")
cat("ddbh.hw.mod.spp species 13.1:", paste(e131$ddbh.hw.mod.spp$species, collapse=","), "\n")
cat("ddbh.hw.mod.spp species 13.3:", paste(e133$ddbh.hw.mod.spp$species, collapse=","), "\n\n")

grid <- expand.grid(sp=c("AB","WA","RM","SM","YB"), form=c("F1","F2","F5"),
                    risk=c("R1","R2","R3"), dbh=c(15,30), stringsAsFactors=FALSE)
getc <- function(env, sp) {
  i <- match(sp, env$ddbh.hw.mod.spp$species,
             nomatch=match("PB", env$ddbh.hw.mod.spp$species))
  c(env$ddbh.hw.mod.spp$spp.coeff[i], env$ddbh.hw.mod.spp$dbh.interaction[i])
}
res <- do.call(rbind, lapply(seq_len(nrow(grid)), function(k){
  g <- grid[k,]
  c1 <- getc(e131, g$sp); c3 <- getc(e133, g$sp)
  v1 <- tryCatch(e131$ddbh_hw_mod(g$sp, g$dbh, 10, g$form, g$risk, c1[1], c1[2]),
                 error=function(e) NA_real_)
  v3 <- tryCatch(e133$ddbh_hw_mod(g$sp, g$dbh, 10, g$form, g$risk, c3[1], c3[2]),
                 error=function(e) NA_real_)
  data.frame(g, v131=v1, v133=v3, diff=v3-v1)
}))
print(res, row.names=FALSE, digits=7)
cat("\nMAX ABS DIFF overall :", max(abs(res$diff), na.rm=TRUE), "\n")
cat("MAX ABS DIFF AB/WA   :", max(abs(res$diff[res$sp %in% c("AB","WA")]), na.rm=TRUE), "\n")
cat("MAX ABS DIFF RM/SM/YB:", max(abs(res$diff[res$sp %in% c("RM","SM","YB")]), na.rm=TRUE), "\n")

cat("\n--- VECTORIZED call, exactly as the ddbh() mutate call site does it ---\n")
vt <- tryCatch({
  e133$ddbh_hw_mod(sp=c("AB","WA","RM"), dbh=c(25,25,25), bal=c(10,10,10),
                   form=c("F2","F2","F2"), risk=c("R3","R3","R3"),
                   spp.coeff=c(0,0,0), dbh.interaction=c(0,0,0))
}, error=function(e) paste("ERROR:", conditionMessage(e)),
   warning=function(w) paste("WARNING:", conditionMessage(w)))
print(vt)

cat("\n--- VECTORIZED, AB first vs RM first (order sensitivity) ---\n")
v_ab <- tryCatch(e133$ddbh_hw_mod(sp=c("AB","RM"), dbh=c(25,25), bal=c(10,10),
                 form=c("F2","F2"), risk=c("R3","R3"), spp.coeff=c(0,0),
                 dbh.interaction=c(0,0)), error=function(e) paste("ERROR:", conditionMessage(e)))
v_rm <- tryCatch(e133$ddbh_hw_mod(sp=c("RM","AB"), dbh=c(25,25), bal=c(10,10),
                 form=c("F2","F2"), risk=c("R3","R3"), spp.coeff=c(0,0),
                 dbh.interaction=c(0,0)), error=function(e) paste("ERROR:", conditionMessage(e)))
cat("AB-first:"); print(v_ab)
cat("RM-first:"); print(v_rm)

cat("\n--- Does ddbh() mutate path actually reach AB/WA? mimic call site ---\n")
tr <- data.frame(sp=c("AB","WA","RM"), dbh=c(25,25,25), bal=c(10,10,10),
                 form=c("F2","F2","F2"), risk=c("R3","R3","R3"), stringsAsFactors=FALSE)
for (nm in c("e131","e133")) {
  env <- get(nm)
  tab <- env$ddbh.hw.mod.spp
  idx <- match(tr$sp, tab$species, nomatch=match("PB", tab$species))
  out <- tryCatch(
    ifelse(!is.na(tr$form) & !is.na(tr$risk),
           env$ddbh_hw_mod(sp=tr$sp, dbh=tr$dbh, bal=tr$bal, form=tr$form, risk=tr$risk,
                           spp.coeff=tab$spp.coeff[idx], dbh.interaction=tab$dbh.interaction[idx]),
           1),
    error=function(e) paste("ERROR:", conditionMessage(e)))
  cat(nm, ":"); print(out)
}
