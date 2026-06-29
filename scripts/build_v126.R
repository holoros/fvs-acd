# Build AcadianGY_12.6.0.r from 12.5.0_mortcal.r by applying four gated refinements.
# Every edit is asserted to hit its anchor exactly once; nothing silent.
src <- "/users/PUOM0008/crsfaaron/AcadianGY_12.5.0_mortcal.r"
dst <- "/users/PUOM0008/crsfaaron/AcadianGY_12.6.0.r"
txt <- paste(readLines(src, warn=FALSE), collapse="\n")

sub1 <- function(s, old, new){
  n <- length(gregexpr(old, s, fixed=TRUE)[[1]])
  if (!(length(n)==1 && n==1 && gregexpr(old,s,fixed=TRUE)[[1]][1] != -1))
    stop(sprintf("anchor not unique (n=%d): %s", n, substr(old,1,60)))
  sub(old, new, s, fixed=TRUE)
}

## --- Edit A: calc_sdi_max gains a flag to keep or drop the site (/csi) term ---
txt <- sub1(txt,
  "calc_sdi_max = function(plot.data, tree.data, csi, elev) {",
  "calc_sdi_max = function(plot.data, tree.data, csi, elev, sdimax.csi.term = TRUE) {")

## --- Edit B: the SDImax site term itself, gated ---
txt <- sub1(txt,
  "0.0685 * elev - 2.8537 * sqrt(elev) + 222.7836 / csi",
  "0.0685 * elev - 2.8537 * sqrt(elev) + (if (isTRUE(sdimax.csi.term)) 222.7836 / csi else 15.6)")

## --- Edit C: pass the flag from ops at the single call site ---
txt <- sub1(txt,
  "elev = stand$elev) %>% ",
  "elev = stand$elev,\n                 sdimax.csi.term = isTRUE(ops$sdimax.site.term)) %>% ")

## --- Edit D: make_stand accepts an ESI input that flows into the csi slot ---
txt <- sub1(txt, "region = 'ME'){", "region = 'ME',\n                       esi = NA_real_){")
txt <- sub1(txt, "csi = as.numeric(csi),",
                 "csi = if (is.finite(esi)) as.numeric(esi) else as.numeric(csi),")
txt <- sub1(txt, "region = region)",
                 "region = region,\n                     site.source = if (is.finite(esi)) 'ESI' else 'CSI')")

## --- Edit E: insert the SDImax-ceiling self-thinning step after the output update ---
sdm_block <- paste(
"",
"  # ---- v12.6 SDImax-ceiling self-thinning mortality (opt-in, default ON) ----",
"  # Density-dependent survivor mortality keyed on relative density RD = SDI / SDImax,",
"  # evaluated on the post-growth, post-base-mortality tree list. Below `onset` nothing",
"  # happens, so sub-maximal stands reproduce 12.5.0. Above `onset` an annual extra",
"  # mortality removes stems in proportion to the overshoot (beta), and a hard ceiling",
"  # holds post-step RD at `max`, so a fully stocked stand rides the Reineke",
"  # self-thinning line. ops$use.sdimort = FALSE => identical to 12.5.0.",
"  .sdm_on = tryCatch(if (!is.null(ops$use.sdimort)) isTRUE(ops$use.sdimort) else TRUE, error=function(e) TRUE)",
"  if (.sdm_on) {",
"    .sdm_onset = tryCatch(if (!is.null(ops$sdimort.onset) && !is.na(ops$sdimort.onset)) ops$sdimort.onset else 0.55, error=function(e) 0.55)",
"    .sdm_beta  = tryCatch(if (!is.null(ops$sdimort.beta)  && !is.na(ops$sdimort.beta))  ops$sdimort.beta  else 0.10, error=function(e) 0.10)",
"    .sdm_max   = tryCatch(if (!is.null(ops$sdimort.max)   && !is.na(ops$sdimort.max))   ops$sdimort.max   else 1.00, error=function(e) 1.00)",
"    tree = tree %>%",
"      dplyr::left_join(dplyr::transmute(plot.smry, plot, sdm_sdimax = sdi.max), by = 'plot') %>%",
"      dplyr::group_by(plot) %>%",
"      dplyr::mutate(sdm_sdi   = sum(ifelse(dbh >= 10, (dbh / 25.4)^1.6 * expf, 0), na.rm = TRUE),",
"                    sdm_rd    = ifelse(!is.na(sdm_sdimax) & sdm_sdimax > 0, sdm_sdi / sdm_sdimax, 0),",
"                    sdm_keepi = ifelse(sdm_rd > .sdm_onset, pmax(0, 1 - .sdm_beta * (sdm_rd - .sdm_onset)), 1),",
"                    sdm_keepc = ifelse(sdm_rd * sdm_keepi > .sdm_max & sdm_rd > 0, .sdm_max / (sdm_rd * sdm_keepi), 1),",
"                    sdm_keepi = pmax(0, pmin(1, sdm_keepi)),",
"                    sdm_keepc = pmax(0, pmin(1, sdm_keepc)),",
"                    expf      = expf * sdm_keepi * sdm_keepc,",
"                    expf      = ifelse(expf < 0.00001, 0.00001, expf)) %>%",
"      dplyr::ungroup() %>%",
"      dplyr::select(-sdm_sdimax, -sdm_sdi, -sdm_rd, -sdm_keepi, -sdm_keepc)",
"  }",
"", sep="\n")
anchor <- "                  cr= 1-(hcb/ht)) "
# robust to trailing spaces: match the core then keep rest of line
lines <- strsplit(txt, "\n", fixed=TRUE)[[1]]
ix <- grep("cr= 1-(hcb/ht))", lines, fixed=TRUE)
if (length(ix) != 1) stop(sprintf("self-thin insert anchor count=%d", length(ix)))
lines <- append(lines, strsplit(sdm_block, "\n", fixed=TRUE)[[1]], after=ix)
txt <- paste(lines, collapse="\n")

## --- Edit F: version header note ---
txt <- sub1(txt, "#### major update summary ####",
  paste("#### major update summary ####","",
        "# 12.6.0 (site-driver + self-thinning refinements; gated, default-on)",
        "#   - make_stand() accepts esi=; ESI flows into the csi slot (site.source logged)",
        "#   - calc_sdi_max() site (/csi) term gated by ops$sdimax.site.term (default drop, recentred +15.6)",
        "#   - new SDImax-ceiling self-thinning mortality (ops$use.sdimort, onset/beta/max); only binds near frontier",
        "#   - MORTCAL retained (ops$use.mortcal) but default OFF; SDImort is the principled self-thinning lever",
        "#   - all refinements gated: use.sdimort=FALSE, sdimax.site.term=TRUE, use.mortcal=FALSE, no esi => 12.5.0",
        sep="\n"))

writeLines(txt, dst)
cat("WROTE", dst, "lines:", length(strsplit(txt,"\n")[[1]]), "\n")
# parse check
ok <- tryCatch({ parse(file=dst); TRUE }, error=function(e){ cat("PARSE ERROR:", conditionMessage(e), "\n"); FALSE })
cat("PARSE_OK:", ok, "\n")
