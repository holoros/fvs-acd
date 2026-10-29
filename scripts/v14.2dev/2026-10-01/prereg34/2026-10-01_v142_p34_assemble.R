## PREREG34 assembly: why ns_long_fl under predicts end of interval height in the 10 to 19 year bin. Reads only frozen
## inputs (PREREG20 key, frames, v141LTf and v141LTfi per tree outputs, siteidx draws). v141LT is Hp141 in the key, as in
## PREREG30. Fold B confirmatory, fold A exploratory. No coordinates are read. No em dashes.
## Run: Rscript 2026-10-01_v142_p34_assemble.R <PREREG34 md5>
suppressMessages({ library(data.table); library(digest); library(ggplot2); library(patchwork) }); options(width = 220)
J <- "/home/aaron/jobs/v142p34"; O <- file.path(J, "assembled")
args <- commandArgs(TRUE); PM <- unname(tools::md5sum(file.path(J, "plan/2026-10-01_v142_ns-long-fl-mid-interval_PREREG34.md")))
if (!length(args) || args[1] != PM) stop("PREREG34 md5 not passed or differs: ", PM)
if (length(list.files(O))) stop("REFUSE ", O, " is not empty")
hs <- function(...) stop(sprintf(...), call. = FALSE)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) hs("REFUSE %s", f); fwrite(x, f); f }
PROV <- list(); md5chk <- function(f, m) { x <- unname(tools::md5sum(f)); if (is.na(x) || substr(x, 1, nchar(m)) != m) hs("md5 %s is %s, expected %s", f, x, m)
  PROV[[length(PROV) + 1L]] <<- data.table(file = f, md5 = x); f }
P20 <- "/home/aaron/jobs/v142p20"; P22 <- "/home/aaron/jobs/v142p22"; P30 <- "/home/aaron/jobs/v142p30"; SETS <- c("ns_long_c", "ns_long_fl")
KEY <- c(ns_long_c = md5chk(file.path(P20, "in/key/p20_htkey_ns_long_c.csv"), "fd8ab6d5"), ns_long_fl = md5chk(file.path(P20, "in/key/p20_htkey_ns_long_fl.csv"), "dce39692"))
RESF <- c(ns_long_c = md5chk(file.path(P20, "results/v141LTf/gyr_v141LTf_ns_long_c_results.csv"), "e475736f"), ns_long_fl = md5chk(file.path(P20, "results/v141LTf/gyr_v141LTf_ns_long_fl_results.csv"), "f9b72f15"))
SIDX <- c(ns_long_c = md5chk(file.path(P20, "in/siteidx_ns_long_c.rds"), "f1cb3043"), ns_long_fl = md5chk(file.path(P20, "in/siteidx_ns_long_fl.rds"), "7def79ab"))
P30HT <- md5chk(file.path(P30, "assembled/gyr142-p30-height_DATA_2026-09-30.csv"), "")
FR <- file.path(P20, "home/magplot/verify/gydbreg20260916/frames")
for (s in SETS) for (k in c("pairs", "tree_init", "tree_t2")) md5chk(file.path(FR, sprintf("bench_gyr_%s_%s.csv", s, k)), "")
HOME_OF <- c(v141LTf = file.path(P20, "home"), v141LTfi = file.path(P22, "home")); ARMS <- c("v141LT", "v141LTf", "v141LTfi"); B <- 1000L
fold_of <- function(x) { u <- unique(as.character(x)); f <- ifelse(strtoi(substr(vapply(u, digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"); f[match(as.character(x), u)] }
arm_dirs <- function(a, s) c(file.path(HOME_OF[[a]], "out", a, s), file.path(HOME_OF[[a]], sprintf("out_retry_a%d", 1:3), a, s))
pred_of <- function(a, s) { acc <- NULL
  for (d in arm_dirs(a, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread, select = c("STAND", "tree", "ht", "ing")))[, STAND := as.character(STAND)][ing == 0]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }
  if (anyDuplicated(acc[, .(STAND, tree)])) hs("dup %s %s", a, s); acc[, .(STAND, tree, ht)] }
CLS <- function(d) as.character(cut(d, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over")))

TR <- list(); WS <- list(); SITES <- list()
for (s in SETS) {
  RF <- fread(RESF[[s]])[, STAND := as.character(STAND)]; sites <- unique(as.character(RF$SITE)); SITES[[s]] <- sites
  IDX <- readRDS(SIDX[[s]]); if (nrow(IDX) != length(sites)) hs("siteidx rows %s", s); WS[[s]] <- apply(IDX[, seq_len(B)], 2, tabulate, nbins = length(sites)); rm(IDX)
  P <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)))[, STAND := as.character(STAND)]
  P <- merge(P, RF[, .(STAND, esi8)], by = "STAND", all.x = TRUE)
  P[, `:=`(prog = substr(PLOTKEY, 1, 5), sib = grepl("sibling", LINK_SRC), bar = BA_T2 / BA_T1)]
  I <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)))[, STAND := as.character(STAND)][, tree := seq_len(.N), by = STAND]
  SI <- I[, .(hfrac = mean(!is.na(HT) & HT > 0), expf1 = EXPF[1]), by = STAND]
  T2 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", s)), select = c("STAND", "TREE", "DBH", "HT"))[, STAND := as.character(STAND)]
  if (anyDuplicated(T2[, .(STAND, TREE)])) hs("dup t2 TREE %s", s)
  K <- fread(KEY[[s]])[, STAND := as.character(STAND)]; K[, Hp_v141LT := Hp141]
  for (a in c("v141LTf", "v141LTfi")) { p <- pred_of(a, s); setnames(p, "ht", paste0("Hp_", a)); K <- merge(K, p, by = c("STAND", "tree"), all.x = TRUE) }
  if (K[, anyNA(Hp_v141LTf) | anyNA(Hp_v141LTfi)]) hs("missing prediction %s", s)
  K <- merge(K, P[, .(STAND, SITE = as.character(SITE), prog, Y1, NLINKS, sib, ESI_SRC, esi8, bar, PLOT_OBS_MINDBH)], by = "STAND")
  K <- merge(K, SI, by = "STAND"); K[, fold_site := fold_of(SITE)]; if (K[, any(fold != fold_site)]) hs("fold differs %s", s)
  K <- merge(K, T2[, .(STAND, TREE, D2f = DBH, H2f = HT)], by = c("STAND", "TREE"), all.x = TRUE)
  K[, verified := is.finite(H2f) & abs(H2f - H2) < 1e-9]; K[, cls := CLS(D1)]; K[, cross := ifelse(verified, CLS(D2f) != cls, NA)]
  K[, set := s]; TR[[s]] <- K }
TT <- rbindlist(TR, fill = TRUE); rm(TR); gc(verbose = FALSE)
TT[, bin := iv >= 10 & iv < 20]
TT[, y1g := fifelse(Y1 < 1975, "Y1 before 1975", fifelse(Y1 < 1985, "Y1 1975 to 1984", "Y1 1985 and later"))]
TT[, ivg := fifelse(iv < 15, "interval 10 to 14", "interval 15 to 19")]

## level ratio by arm with site cluster interval; Y is one set
stat <- function(Y, s, lab, fd, stratum) { if (!nrow(Y)) return(NULL)
  SS <- Y[, c(list(n = .N, h2 = sum(H2), dho = sum((H2 - H1) / iv)), setNames(lapply(ARMS, function(a) sum(get(paste0("Hp_", a)))), ARMS)), by = SITE]
  w <- WS[[s]][match(SS$SITE, SITES[[s]]), , drop = FALSE]; ch2 <- colSums(w * SS$h2); cn <- colSums(w * SS$n)
  rbindlist(lapply(ARMS, function(a) { lb <- colSums(w * SS[[a]]) / ch2; bb <- (colSums(w * SS[[a]]) - ch2) / cn
    data.table(set = s, fold = fd, stratum = stratum, subset = lab, arm = a, trees = sum(SS$n), stands = uniqueN(Y$STAND), sites = nrow(SS),
      obs_h2_m = sum(SS$h2) / sum(SS$n), obs_inc_m_yr = sum(SS$dho) / sum(SS$n), level = sum(SS[[a]]) / sum(SS$h2),
      level_lo = quantile(lb, .025, na.rm = TRUE), level_hi = quantile(lb, .975, na.rm = TRUE),
      bias_m = (sum(SS[[a]]) - sum(SS$h2)) / sum(SS$n), bias_lo = quantile(bb, .025, na.rm = TRUE), bias_hi = quantile(bb, .975, na.rm = TRUE)) })) }
draws <- function(Y, s, a) { SS <- Y[, .(h2 = sum(H2), p = sum(get(paste0("Hp_", a)))), by = SITE]; w <- WS[[s]][match(SS$SITE, SITES[[s]]), , drop = FALSE]
  colSums(w * SS$p) / colSums(w * SS$h2) }

ST <- list()
for (fd in c("A", "B")) {
  Xc <- TT[set == "ns_long_c" & fold == fd & bin == TRUE]; Xf <- TT[set == "ns_long_fl" & fold == fd & bin == TRUE]
  et <- quantile(unique(Xf[, .(STAND, esi8)])$esi8, c(1, 2) / 3, na.rm = TRUE)
  Xf[, esig := fifelse(esi8 < et[1], "ESI lower tertile", fifelse(esi8 < et[2], "ESI middle tertile", "ESI upper tertile"))]
  SUB <- list(
    c("all", "bin", "TRUE"), c("a", "NS_OP", "prog == 'NS_OP'"), c("a", "NS_RS", "prog == 'NS_RS'"),
    c("a", "plot 400 m2 (EXPF 25)", "abs(expf1 - 25) < 1e-9"), c("a", "plot not 400 m2", "abs(expf1 - 25) >= 1e-9"),
    c("a", "observed floor 9.1 cm and over", "PLOT_OBS_MINDBH >= 9.1"), c("a", "observed floor below 9.1 cm", "PLOT_OBS_MINDBH < 9.1"),
    c("a", "all t1 heights measured", "hfrac >= 1"), c("a", "t1 heights subsampled", "hfrac < 1"),
    c("b", "drop below 12.7", "cls != 'below 12.7'"), c("b", "drop 12.7 to 25", "cls != '12.7 to 25'"), c("b", "drop 25 and over", "cls != '25 and over'"),
    c("b", "class below 12.7", "cls == 'below 12.7'"), c("b", "class 12.7 to 25", "cls == '12.7 to 25'"), c("b", "class 25 and over", "cls == '25 and over'"),
    c("b", "verified, non crossers", "verified & cross == FALSE"), c("b", "verified, crossers", "verified & cross == TRUE"), c("b", "verified match", "verified == TRUE"),
    c("c", "NLINKS 1", "NLINKS == 1"), c("c", "NLINKS 2 and over", "NLINKS >= 2"), c("c", "no sibling link", "!sib"), c("c", "sibling link", "sib == TRUE"),
    c("c", "ESI cov30m", "ESI_SRC == 'cov30m'"), c("c", "ESI old harness", "ESI_SRC == 'oldharness'"),
    c("c (reported)", "BA ratio below 1", "bar < 1"), c("c (reported)", "BA ratio 1 and over", "bar >= 1"),
    c("d", "Y1 before 1975", "y1g == 'Y1 before 1975'"), c("d", "Y1 1975 to 1984", "y1g == 'Y1 1975 to 1984'"), c("d", "Y1 1985 and later", "y1g == 'Y1 1985 and later'"),
    c("d", "ESI lower tertile", "esig == 'ESI lower tertile'"), c("d", "ESI middle tertile", "esig == 'ESI middle tertile'"), c("d", "ESI upper tertile", "esig == 'ESI upper tertile'"),
    c("d", "interval 10 to 14", "ivg == 'interval 10 to 14'"), c("d", "interval 15 to 19", "ivg == 'interval 15 to 19'"))
  for (stv in c("all programs", "NS_OP", "NS_RS")) { Z <- if (stv == "all programs") Xf else Xf[prog == stv]
    for (u in SUB) { r <- stat(Z[which(rep_len(Z[, eval(parse(text = u[3]))], nrow(Z)) %in% TRUE)], "ns_long_fl", u[2], fd, stv); if (!is.null(r)) ST[[length(ST) + 1L]] <- r[, expl := u[1]] } }
  ## ns_long_c references
  for (stv in c("all programs", "NS_OP", "NS_RS")) { Z <- if (stv == "all programs") Xc else Xc[prog == stv]
    r <- stat(Z, "ns_long_c", "bin", fd, stv); if (!is.null(r)) ST[[length(ST) + 1L]] <- r[, expl := "ref"]
    for (cl in c("below 12.7", "12.7 to 25", "25 and over")) { r <- stat(Z[cls == cl], "ns_long_c", paste("class", cl), fd, stv); if (!is.null(r)) ST[[length(ST) + 1L]] <- r[, expl := "ref"] } } }
ST <- rbindlist(ST, fill = TRUE)

## ---- reproduction of PREREG30 bin rows (rule 1)
R30 <- fread(P30HT)[group == "interval 10 to 19"]
rp <- merge(ST[subset == "bin" & stratum == "all programs", .(set, fold, arm, level, trees)], R30[, .(set, fold, arm, level30 = level, trees30 = trees)], by = c("set", "fold", "arm"))
rp[, diff := abs(level - level30)]; print(rp); if (nrow(rp) != 12 || any(rp$diff > 1e-9) || any(rp$trees != rp$trees30)) hs("Rule 1: PREREG30 bin rows do not reproduce")

## ---- decision quantities, fold B
REF <- ST[fold == "B" & set == "ns_long_c" & subset == "bin" & stratum == "all programs" & arm == "v141LTf", level]
FB <- ST[fold == "B" & set == "ns_long_fl" & stratum == "all programs" & arm == "v141LTf"]
FB[, material := trees >= 500 & (abs(level - REF) <= 0.03 | abs(level - 1) <= 0.03)]
Xc <- TT[set == "ns_long_c" & fold == "B" & bin == TRUE]; Xf <- TT[set == "ns_long_fl" & fold == "B" & bin == TRUE]; Xcall <- TT[set == "ns_long_c" & fold == "B"]
cov_b <- Xf[, mean(verified)]
shap <- function(fac, fd = "B") { Xc <- TT[set == "ns_long_c" & fold == fd & bin == TRUE]; Xf <- TT[set == "ns_long_fl" & fold == fd & bin == TRUE]; Xa <- TT[set == "ns_long_c" & fold == fd]
  g <- function(X) X[, .(h2 = sum(H2), p = sum(Hp_v141LTf), n = .N), by = .(g = get(fac))]
  a <- g(Xf); b <- g(Xc); ba <- g(Xa); m <- merge(a, b, by = "g", all = TRUE, suffixes = c("_f", "_c")); for (v in c("h2_f", "p_f", "n_f", "h2_c", "p_c", "n_c")) set(m, which(is.na(m[[v]])), v, 0)
  m <- merge(m, ba[, .(g, r_all = p / h2)], by = "g", all.x = TRUE)
  m[, `:=`(s_f = h2_f / sum(h2_f), s_c = h2_c / sum(h2_c), r_f = p_f / h2_f, r_c = fifelse(n_c >= 200, p_c / h2_c, r_all), rc_fallback = n_c < 200)]
  rbin <- sum(b$p) / sum(b$h2); m[!is.finite(r_c), `:=`(r_c = rbin, rc_fallback = TRUE)]; m[!is.finite(r_f), r_f := r_c]
  m[, `:=`(comp = (s_f - s_c) * (r_f + r_c) / 2, within = (r_f - r_c) * (s_f + s_c) / 2)]
  gap <- sum(m$comp) + sum(m$within)
  list(groups = m[, factor := fac][, fold := fd][], tot = data.table(fold = fd, factor = fac, gap = gap, composition = sum(m$comp), within = sum(m$within),
       comp_share = sum(m$comp) / gap, level_fl = sum(m$p_f) / sum(m$h2_f), level_c_bin = sum(m$p_c) / sum(m$h2_c))) }
SH <- lapply(c("A", "B"), function(fd) lapply(c("prog", "cls", "NLINKS", "y1g"), shap, fd = fd))
SHG <- rbindlist(lapply(unlist(SH, recursive = FALSE), `[[`, "groups"), fill = TRUE); SHT <- rbindlist(lapply(unlist(SH, recursive = FALSE), `[[`, "tot"))
print(SHT, digits = 4)
cs <- function(f) SHT[fold == "B" & factor == f, comp_share]
## frame contrast at fixed program: NS_OP fl bin minus NS_OP c bin, v141LTf
dfr <- draws(Xf[prog == "NS_OP"], "ns_long_fl", "v141LTf") - draws(Xc[prog == "NS_OP"], "ns_long_c", "v141LTf")
pt <- ST[fold == "B" & set == "ns_long_fl" & stratum == "all programs" & subset == "NS_OP" & arm == "v141LTf", level] -
      ST[fold == "B" & set == "ns_long_c" & stratum == "NS_OP" & subset == "bin" & arm == "v141LTf", level]
FC <- data.table(contrast = "NS_OP ns_long_fl bin minus NS_OP ns_long_c bin, v141LTf level", value = pt, lo = quantile(dfr, .025), hi = quantile(dfr, .975))
FC[, supported := (lo > 0 | hi < 0) & abs(value) >= 0.03]; print(FC)
## support by explanation
mat <- function(subs) FB[subset %in% subs & material == TRUE, subset]
sa <- mat(c("NS_OP", "plot 400 m2 (EXPF 25)", "observed floor 9.1 cm and over", "all t1 heights measured"))
sa_ok <- length(sa) > 0 && ("NS_OP" %in% sa && cs("prog") >= 0.5 || any(sa != "NS_OP"))
sb <- mat(c("drop below 12.7", "drop 12.7 to 25", "drop 25 and over", if (cov_b >= 0.5) "verified, non crossers")); sb_ok <- length(sb) > 0 && cs("cls") >= 0.5
sc <- mat(c("NLINKS 1", "no sibling link", "ESI cov30m")); sc_ok <- (length(sc) > 0 && ("NLINKS 1" %in% sc && cs("NLINKS") >= 0.5 || any(sc != "NLINKS 1"))) || FC$supported
sd <- mat(c("Y1 before 1975", "Y1 1975 to 1984", "Y1 1985 and later", "ESI lower tertile", "ESI middle tertile", "ESI upper tertile", "interval 10 to 14", "interval 15 to 19"))
sd_ok <- length(sd) > 0 && (any(!grepl("^Y1", sd)) || cs("y1g") >= 0.5)
## residual check on the explaining subset
resid <- function(stv, subset_lab) { x <- ST[fold == "B" & set == "ns_long_fl" & stratum == stv & subset == subset_lab]
  lt <- x[arm == "v141LT", level]; lf <- x[arm == "v141LTf", level]; ok1 <- abs(lf - 1) <= abs(lt - 1) + 0.02
  cl <- ST[fold == "B" & set == "ns_long_fl" & stratum == stv & subset %in% c("class below 12.7", "class 12.7 to 25", "class 25 and over") & trees >= 200]
  cl <- dcast(cl, subset + trees ~ arm, value.var = "level"); cl[, pass := abs(v141LTf - 1) <= abs(v141LT - 1) + 0.03]
  data.table(stratum = stv, subset = subset_lab, level_LT = lt, level_LTf = lf, pooled_pass = ok1, classes = nrow(cl), classes_pass = sum(cl$pass), pass = ok1 && all(cl$pass)) }
sc1 <- if (length(sc)) sc[1] else NA_character_
RS <- rbind(resid("NS_OP", "bin"), resid("NS_RS", "bin"), if (!is.na(sc1)) resid("all programs", sc1)); print(RS)
SUP <- data.table(explanation = c("a", "b", "c", "d"), supported = c(sa_ok, sb_ok, sc_ok, sd_ok),
  material_subsets = c(paste(sa, collapse = "; "), paste(sb, collapse = "; "), paste(sc, collapse = "; "), paste(sd, collapse = "; ")),
  comp_share = c(cs("prog"), cs("cls"), cs("NLINKS"), cs("y1g")), note = c("", sprintf("verified match coverage in fold B bin %.3f", cov_b), sprintf("frame contrast supported %s", FC$supported), ""))
print(SUP)
resA <- sa_ok && RS[stratum == "NS_OP" & subset == "bin", pass]
resC <- sc_ok && (if (!is.na(sc1)) RS[stratum == "all programs" & subset == sc1, pass] else RS[stratum == "NS_OP" & subset == "bin", pass])
verdict <- if (resA || resC) sprintf("Rule 2: (%s) supported and the residual check passes on the explaining subset; the form is safe on the population it was fit for, and the ns_long_fl 10 to 19 year bin is named a %s effect",
    paste(c("a", "c")[c(resA, resC)], collapse = ") and ("), paste(c("program", "frame")[c(resA, resC)], collapse = " and ")) else
  if (sa_ok || sc_ok || sb_ok || sd_ok) sprintf("Rule 3: supported (%s), residual check failed or explanation is (b) or (d); the form is not called safe on long intervals", paste(SUP[supported == TRUE, explanation], collapse = ", ")) else
  "Rule 4: nothing supported; unexplained; the form is not called safe on long intervals"
cat(verdict, "\n")
w_out(ST, "gyr142-p34-subsets_DATA_2026-10-01.csv"); w_out(FB, "gyr142-p34-materiality-foldB_DATA_2026-10-01.csv"); w_out(SHG, "gyr142-p34-shapley-groups_DATA_2026-10-01.csv")
w_out(SHT, "gyr142-p34-shapley_DATA_2026-10-01.csv"); w_out(FC, "gyr142-p34-frame-contrast_DATA_2026-10-01.csv"); w_out(RS, "gyr142-p34-residual_DATA_2026-10-01.csv")
w_out(SUP, "gyr142-p34-support_DATA_2026-10-01.csv"); w_out(rp, "gyr142-p34-repro_DATA_2026-10-01.csv"); w_out(rbindlist(PROV), "gyr142-p34-provenance_DATA_2026-10-01.csv")
writeLines(c(readLines(file.path(J, "logs/prereg_md5.txt")), sprintf("ns_long_c bin v141LTf fold B reference %.6f", REF), verdict), file.path(O, "gyr142-p34-verdict_2026-10-01.txt"))

## ---- figure, fold B: level ratio and bias by program and t1 class, both sets, v141LT and v141LTf
FD <- ST[fold == "B" & arm %in% c("v141LT", "v141LTf") & ((set == "ns_long_fl" & expl %in% c("all", "a", "b") & subset %in% c("bin", "class below 12.7", "class 12.7 to 25", "class 25 and over") & stratum != "all programs") |
         (set == "ns_long_fl" & stratum == "all programs" & subset == "bin") | (set == "ns_long_c" & expl == "ref"))]
FD <- FD[!(set == "ns_long_c" & stratum == "NS_RS")]
FD[, cl := factor(sub("^class ", "", fifelse(subset == "bin", "all classes", subset)), c("all classes", "below 12.7", "12.7 to 25", "25 and over"))]
FD[, panel := factor(paste(set, stratum, sep = ", "), c("ns_long_c, all programs", "ns_long_c, NS_OP", "ns_long_fl, all programs", "ns_long_fl, NS_OP", "ns_long_fl, NS_RS"))]
FD <- FD[!is.na(panel)]; FD[, arm := factor(arm, c("v141LT", "v141LTf"), c("v141LT (14.1)", "v141LTf (height form)"))]
pd <- position_dodge(width = 0.5); cols <- c("#4D4D4D", "#1B6FA8")
bp <- function(y, lo, hi, yl, ref) ggplot(FD, aes(cl, .data[[y]], colour = arm, shape = arm)) + geom_hline(yintercept = ref, linewidth = 0.3, linetype = 2) +
  geom_errorbar(aes(ymin = .data[[lo]], ymax = .data[[hi]]), width = 0.25, position = pd, linewidth = 0.4) + geom_point(size = 1.6, position = pd) +
  facet_wrap(~panel, nrow = 1) + scale_colour_manual(NULL, values = cols) + scale_shape_manual(NULL, values = c(16, 17)) + labs(x = NULL, y = yl) +
  theme_classic(base_size = 8) + theme(strip.background = element_blank(), strip.text = element_text(face = "bold", size = 7), legend.position = "bottom",
  axis.text.x = element_text(angle = 35, hjust = 1))
p1 <- bp("level", "level_lo", "level_hi", expression("Predicted / observed " * italic(H)[2]), 1) + theme(axis.text.x = element_blank())
p2 <- bp("bias_m", "bias_lo", "bias_hi", expression("Bias in " * italic(H)[2] ~ "(m)"), 0) + labs(x = expression("Diameter class at " * italic(t)[1] ~ "(cm)"))
fig <- (p1 / p2) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
ggsave(file.path(O, "gyr142-p34-bin-foldB_2026-10-01.png"), fig, width = 180, height = 130, units = "mm", dpi = 300, bg = "white")
cat("P34_ASSEMBLE_DONE\n")
