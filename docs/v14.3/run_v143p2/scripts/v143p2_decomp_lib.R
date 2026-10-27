## v143p2_decomp_lib.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b): the heavy gap decomposition S, M, I, R (and W) and the survivor
## tree table, sourced by v143p2_decomp.R (step 2 on mefia_ph_c, A0 and 14.1), by the step 4 scorer (candidate on
## mefia_ph_c) and by the step 5 scorer (sealed set). Pure functions; reads only what the caller passes. No em dashes.
##
## Definitions (plan section "Heavy stand AGB"), in the engine's weight based representation, per stand, Mg ha-1 yr-1
## with dt = the runner's iv = max(1, round(interval_years)):
##   AGB(.)  the runner's NSVB DRYBIO_AG call (nsvb emulator coefficients, himp when height is missing), times the
##           runner's metrics() floor indicator d >= SCORE_MINDBH_OBS (the scorer's floor, at least 5 cm).
##   v1 records  the engine's start-of-projection split tree list (t1_split_tree), each mapped to its frame tree.
##   fate     from FIADB: a v1 live tree is a SURVIVOR if a v2 record with PREV_TRE_CN equal to its CN is STATUSCD 1 and
##            is in the frame's v2 list; DEAD if that record is STATUSCD 2 with an agent other than 80 (AGENTCD and
##            AGENTCD_NERS); REMOVED if STATUSCD 3, or STATUSCD 2 with agent 80, or no v2 record, or any other status
##            (PREREG1 removal codes applied to v1 -> v2; absent and other status are counted apart).
##   U        v1 records at or above the floor at v1.
##   S_pred = sum_{U, surv} e1 (P - A1);  S_obs = sum_{U, surv} e1 (O - A1)   (weights held at v1)
##   M_pred = sum_U (e1 - ep2) P - sum_{U, not surv} e1 (P - A1);  M_obs = sum_{U, dead} e1 A1
##   R_obs  = sum_{U, removed} e1 A1
##   I_pred = sum_{not U} ep2 P + sum_{engine ingrowth records} e P;  I_obs = sum over v2 frame trees not linked to a
##            U survivor of e2 O
##   W_obs  = sum_{U, surv} (e2 - e1) O   (the scorer weights observed survivors at v2)
##   with P = AGB(d_pred,v2, h_pred,v2), A1 = AGB(d1, h1), O = AGB(d_obs,v2, h_obs,v2); a v1 record the engine dropped
##   has ep2 = 0 and P = A1 (counted).
##   S = S_pred - S_obs, M = M_obs - M_pred, I = I_pred - I_obs, R = R_obs, W = W_obs, all over dt.
##   Identity: (BIOMASS_p - BIOMASS_o) / iv = S + M + I + R - W, checked per stand and on the heavy mean.
suppressMessages(library(data.table))
.V <- "/users/PUOM0008/crsfaaron/magplot/verify"
.co <- fread(file.path(.V, "nsvb_emulator_coefs.csv")); .sp2g <- fread(file.path(.V, "spcd_spgrpcd.csv"))
.AGY2SPCD <- c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=125,BC=762,PR=761,ST=315,HH=701,SB=372,RB=370,AS=541,SW=299,HW=998,OH=998,OS=299,PC=761)
.sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
.himp <- function(sp, d) ifelse(sp %in% .sw, 1.3 + 27 * (1 - exp(-0.030 * d)), 1.3 + 25 * (1 - exp(-0.028 * d)))
.agy <- names(.AGY2SPCD)
.spcd2grp <- setNames(.sp2g$SPGRPCD, as.character(.sp2g$SPCD))
.agy_grp <- sapply(.AGY2SPCD, function(s) { g <- .spcd2grp[as.character(s)]; if (is.na(g)) 998L else as.integer(g) })
.ci <- match(.agy_grp, .co$SPGRPCD); .ci[is.na(.ci)] <- match(998, .co$SPGRPCD); .ci[is.na(.ci)] <- 1
.CFB <- list(a = setNames(.co[["DRYBIO_AG_a"]][.ci], .agy), b = setNames(.co[["DRYBIO_AG_b"]][.ci], .agy), sm = setNames(.co[["DRYBIO_AG_sm"]][.ci], .agy))
mapsp <- function(s) { s <- toupper(s); ifelse(s %in% .agy, s, ifelse(s %in% .sw, "OS", "OH")) }
## per tree AGB in Mg per tree times 1 (the caller multiplies by expf); the runner's bio = sum(nsvb * expf) * LB_KG / 1000
agb_tree <- function(sp, d, h) { ht <- ifelse(is.finite(h) & h > 0, h, .himp(sp, d))
  lX <- log((d / 2.54)^2 * (ht / 0.3048)); y <- .CFB$sm[sp] * exp(.CFB$a[sp] + .CFB$b[sp] * lX); y[!is.finite(y)] <- 0
  unname(y) * 0.453592 / 1000 }
## the runner's metrics() BIOMASS: live = finite d, d >= mindbh, finite expf, expf > 0
stand_bio <- function(sp, d, h, e, mindbh) { k <- is.finite(d) & d >= mindbh & is.finite(e) & e > 0; sum(agb_tree(sp[k], d[k], h[k]) * e[k]) }

## the hardwood split map (verbatim rule of the 19 October diagnostic)
.SPLIT_QUIET <- TRUE; source("/users/PUOM0008/crsfaaron/hw_formrisk_split.R")
.AGYR <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
.nsub <- vapply(.a9$sp, function(k) { J <- outer(.pform[k, ], .prisk[k, ]); J[J < 0.03] <- 0; if (sum(J) == 0) J <- outer(.pform[k, ], .prisk[k, ]); sum(J > 0) }, 0L)
splitmap <- function(ti) { ti <- copy(ti); ti[, SPR := { s <- toupper(SP); ifelse(s %in% .AGYR, s, ifelse(s %in% .sw, "OS", "OH")) }]
  ti[, { hw <- SPR %in% .a9$sp; key <- ifelse(SPR %in% HW_SPP, SPR, "OH"); n <- .N
    hh <- which(hw); ns <- unname(.nsub[key[hh]]); st <- n + cumsum(c(0, head(ns, -1)))
    hwt <- if (length(hh)) as.integer(unlist(mapply(function(a, b) a + seq_len(b), st, ns, SIMPLIFY = FALSE))) else integer(0)
    rbind(data.table(tree = which(!hw), TREE_IDX = which(!hw)), data.table(tree = hwt, TREE_IDX = rep(hh, ns))) }, by = STAND] }

## FIA linkage: frame TREE index -> FIADB CN at v1 and v2, fates of v1 live trees (the builder's mk_tree order:
## live trees STATUSCD 1 and DIA > 0 at the visit CN, setorder(STAND, CN), TREE = row number)
fia_link <- function(cl, trees) {
  tr <- trees[PLT_CN %in% c(cl$CN_V1, cl$CN_V2)]
  tr[PREV_TRE_CN %in% c("", "NA"), PREV_TRE_CN := NA_character_]
  lv <- tr[STATUSCD == 1 & is.finite(DIA) & DIA > 0]
  v1 <- merge(lv[, .(PLT_CN, CN, DIA)], cl[, .(PLT_CN = CN_V1, STAND)], by = "PLT_CN"); setorder(v1, STAND, CN); v1[, TREE := seq_len(.N), by = STAND]
  v2 <- merge(lv[, .(PLT_CN, CN, PREV_TRE_CN, DIA)], cl[, .(PLT_CN = CN_V2, STAND)], by = "PLT_CN"); setorder(v2, STAND, CN); v2[, TREE := seq_len(.N), by = STAND]
  nx <- tr[PLT_CN %in% cl$CN_V2 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, st2 = STATUSCD, ag = AGENTCD, agn = AGENTCD_NERS, CN2 = CN)]
  if (anyDuplicated(nx$PREV_TRE_CN)) stop("a v1 tree has more than one v2 record")
  v1[nx, on = .(CN = PREV_TRE_CN), `:=`(st2 = i.st2, ag = i.ag, agn = i.agn, CN2 = i.CN2)]
  v1[v2, on = .(CN2 = CN), TREE2 := i.TREE]
  v1[, fate := fifelse(is.na(st2), "absent", fifelse(st2 == 1L & !is.na(TREE2), "surv", fifelse(st2 == 3L | (st2 == 2L & (ag %in% 80L | agn %in% 80L)), "removed",
               fifelse(st2 == 2L, "dead", "other"))))]
  list(v1 = v1[, .(STAND, TREE, CN, fate, TREE2)], v2 = v2[, .(STAND, TREE, CN)]) }

## the decomposition for one arm. ti, t2: frame tree lists; res: runner results; sp0: t1_split_tree; pt: pred_t2_tree;
## lk: fia_link(); pr: pairs (STAND, SCORE_MINDBH_OBS); stands: the population to decompose.
decompose <- function(ti, t2, res, sp0, pt, lk, pr, stands, tol = 1e-6) {
  ti <- ti[STAND %in% stands]; t2 <- t2[STAND %in% stands]; sp0 <- sp0[STAND %in% stands]; pt <- pt[STAND %in% stands]
  res <- res[STAND %in% stands]; pr <- pr[STAND %in% stands, .(STAND, SMD = SCORE_MINDBH_OBS)]
  ti[, TREE_IDX := seq_len(.N), by = STAND]
  ## restate the runner's three stand biomasses from tree lists (validates the AGB replication)
  b1 <- merge(ti, pr, by = "STAND")[, .(B1 = stand_bio(mapsp(SP), DBH, HT, EXPF, SMD[1])), by = STAND]
  bo <- merge(t2, pr, by = "STAND")[, .(BO = stand_bio(mapsp(SP), DBH, HT, EXPF, SMD[1])), by = STAND]
  bp <- merge(pt, pr, by = "STAND")[, .(BP = stand_bio(sp, dbh, ht, expf, SMD[1])), by = STAND]
  chk <- Reduce(function(x, y) merge(x, y, by = "STAND", all = TRUE), list(res[, .(STAND, iv, BIOMASS_t1, BIOMASS_o, BIOMASS_p)], b1, bo, bp))
  restate <- chk[, .(stands = .N, max_abs_t1 = max(abs(B1 - BIOMASS_t1)), max_abs_o = max(abs(BO - BIOMASS_o)), max_abs_p = max(abs(BP - BIOMASS_p)))]
  ## v1 split records with their frame tree, fate, prediction
  pm <- splitmap(ti[, .(STAND, SP)])
  r1 <- merge(sp0[, .(STAND, tree, sp, d1 = dbh, h1 = ht, e1 = expf)], pm, by = c("STAND", "tree"))
  if (nrow(r1) != nrow(sp0)) stop("split records not mapped to frame trees")
  r1 <- merge(r1, lk$v1[, .(STAND, TREE_IDX = TREE, fate, TREE2)], by = c("STAND", "TREE_IDX"), all.x = TRUE)
  if (r1[is.na(fate), .N] > 0) stop("v1 records without an FIADB fate: ", r1[is.na(fate), .N])
  pn <- pt[ing == 0L, .(STAND, tree, dp = dbh, hp = ht, ep = expf)]
  r1 <- merge(r1, pn, by = c("STAND", "tree"), all.x = TRUE)
  n_dropped <- r1[is.na(ep), .N]
  r1[is.na(ep), `:=`(dp = d1, hp = h1, ep = 0)]
  r1 <- merge(r1, pr, by = "STAND")
  r1[, `:=`(A1 = agb_tree(sp, d1, h1) * (d1 >= SMD), P = agb_tree(sp, dp, hp) * (dp >= SMD), U = d1 >= SMD)]
  ## observed v2 values for survivors, by frame t2 TREE
  t2[, TREE2 := TREE]
  t2 <- merge(t2, pr, by = "STAND"); t2[, O := agb_tree(mapsp(SP), DBH, HT) * (is.finite(DBH) & DBH >= SMD & EXPF > 0)]
  r1[t2, on = .(STAND, TREE2), `:=`(O = i.O, e2 = i.EXPF)]
  ## survivors are tree level: every sub-record of a surviving tree is a survivor; O and e2 are per tree, so the
  ## observed side is computed on frame trees (e1 of the tree = sum of its sub-records' e1, A1 of the tree = A1)
  trees_obs <- r1[, .(e1 = sum(e1), A1 = A1[1], U = U[1], fate = fate[1], O = O[1], e2 = e2[1], TREE2 = TREE2[1]), by = .(STAND, TREE_IDX)]
  S_pred <- r1[U & fate == "surv", .(S_pred = sum(e1 * (P - A1))), by = STAND]
  M_pred <- r1[U == TRUE, .(M_pred = sum((e1 - ep) * P) - sum((e1 * (P - A1))[fate != "surv"])), by = STAND]
  I_pred1 <- r1[U == FALSE, .(Ip1 = sum(ep * P)), by = STAND]
  I_pred2 <- merge(pt[ing == 1L], pr, by = "STAND")[, .(Ip2 = sum(expf * agb_tree(sp, dbh, ht) * (is.finite(dbh) & dbh >= SMD & expf > 0))), by = STAND]
  So <- trees_obs[U & fate == "surv", .(S_obs = sum(e1 * (O - A1)), W_obs = sum((e2 - e1) * O)), by = STAND]
  Mo <- trees_obs[U & fate == "dead", .(M_obs = sum(e1 * A1)), by = STAND]
  Ro <- trees_obs[U & fate %in% c("removed", "absent", "other"), .(R_obs = sum(e1 * A1), R_absent = sum((e1 * A1)[fate == "absent"]), R_other = sum((e1 * A1)[fate == "other"])), by = STAND]
  linkedU <- trees_obs[U & fate == "surv", .(STAND, TREE2)]
  Io <- t2[!paste(STAND, TREE2) %chin% linkedU[, paste(STAND, TREE2)], .(I_obs = sum(EXPF * O)), by = STAND]
  D <- Reduce(function(x, y) merge(x, y, by = "STAND", all.x = TRUE), list(res[, .(STAND, iv, BIOMASS_t1, BIOMASS_o, BIOMASS_p)], S_pred, M_pred, I_pred1, I_pred2, So, Mo, Ro, Io))
  for (k in setdiff(names(D), c("STAND", "iv", "BIOMASS_t1", "BIOMASS_o", "BIOMASS_p"))) set(D, which(is.na(D[[k]])), k, 0)
  D[, `:=`(I_pred = Ip1 + Ip2)]
  D[, `:=`(gap = (BIOMASS_p - BIOMASS_o) / iv, S = (S_pred - S_obs) / iv, M = (M_obs - M_pred) / iv, I = (I_pred - I_obs) / iv, R = R_obs / iv, W = W_obs / iv,
           S_obs_rate = S_obs / iv, S_pred_rate = S_pred / iv)]
  D[, resid := gap - (S + M + I + R - W)]
  list(D = D, restate = restate, n_dropped_records = n_dropped,
       fates = trees_obs[, .(trees = .N, U_trees = sum(U)), by = fate], r1 = r1, trees_obs = trees_obs) }
