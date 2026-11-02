# Loads the AcadianGY 14.1 stack (FVS-ACD) from this folder into the global environment.
#
# 14.1 is four files sourced in a fixed order: the 13.1 base, the 14.x diameter increment
# overlay (model_b0b1b2.r), the 14.0.4 engine, and the 14.1 overlay. The engine files are byte
# copies of the files the October 16, 2026 cross-version benchmark ran on OSC Cardinal, and this
# loader checks each one by md5 before sourcing it. Nothing in them is edited.
#
# model_b0b1b2.r sources 13.1 from a fixed Cardinal path and reads the refitted b0, b1 and b2
# from environment variables. The loader writes a temporary copy with that one source() line
# pointed at engine/AcadianGY_13.1.r and sets the three values the benchmark launcher used
# (docs/benchmarks/2026-10-16_cross-version/scripts/cardinal/postharv/2026-10-16_mefia_ph_array.sbatch,
# line 54, at tag archive-2026-11-02). With benchmark_ddbh = FALSE the 13.1 values are used instead.
#
# Usage:  source("engine/load_acd141.R"); load_acd141()

load_acd141 <- function(engine_dir = "engine", benchmark_ddbh = TRUE) {
  f <- file.path(engine_dir, c(
    base  = "AcadianGY_13.1.r",
    b012  = "model_b0b1b2.r",
    e1404 = "AcadianGY_14.0.4.r",
    e141  = "AcadianGY_14.1.r",
    mort  = "coef/v14_coef_bundle_2026-09-08.rds",
    opt3  = "coef/v141_option3_offline_coefs_r5_2026-09-23.rds"))
  names(f) <- c("base", "b012", "e1404", "e141", "mort", "opt3")
  want <- c(base  = "5894df6013c701d09e7ba67ba6c2f090",
            b012  = "bb51eeada62796532ce3a7212a5c6451",
            e1404 = "61f95d99f896e8e513930d6e33a7391a",
            e141  = "0bf27dde81240e6bdf59c9a90f0051bd",
            mort  = "4740de88af8231677d828dec8e5b753c",
            opt3  = "c8f02f5841e98b93cb532b6fa9b1fc51")
  got <- unname(tools::md5sum(f))
  bad <- names(f)[is.na(got) | got != want]
  if (length(bad)) stop("md5 mismatch or missing file: ", paste(f[bad], collapse = ", "))

  base <- normalizePath(f[["base"]])
  if (benchmark_ddbh) {
    src <- readLines(f[["b012"]])
    hit <- grep("^source\\(", src)
    if (length(hit) != 1) stop("expected one source() line in model_b0b1b2.r, found ", length(hit))
    src[hit] <- sprintf("source(%s)", deparse(base))
    tmp <- tempfile("model_b0b1b2_", fileext = ".r")
    writeLines(src, tmp)
    Sys.setenv(B0NEW = "-1.88365516930746",
               B1NEW = "0.497878016309701",
               B2NEW = "-0.0293425859449079",
               ACD_V14_BASE = tmp)
  } else {
    Sys.setenv(ACD_V14_BASE = base)
  }
  source(f[["e1404"]], local = globalenv())
  source(f[["e141"]],  local = globalenv())
  invisible(list(linked.coef.file = normalizePath(f[["mort"]]),
                 v141.coef.file   = normalizePath(f[["opt3"]])))
}
