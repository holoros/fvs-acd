# Shared volume + stumpage-value functions for AcadianGY regional scoring.
# Applied identically to predicted and observed tree lists so the comparison is
# fair and height-free (a single regional H-D is imputed for both, isolating the
# dbh / density / composition effects the model configs actually change).
#
# Prices are approximate Maine 2024 statewide-average stumpage (Maine Forest
# Service 2024 Stumpage Price Report; cross-checked vs Timberland Investor Q4
# 2025): softwood pulp is severely depressed (~$2-3/ton ~= $6/cord), spruce-fir
# sawlog ~$115/MBF, white pine sawlog ~$250/MBF, premium hardwood (sugar maple/
# yellow birch/red oak) ~$300/MBF, red maple and other hardwood ~$130/MBF,
# hardwood pulp ~$12/cord. USD. For RELATIVE comparison of model configs, not
# an appraisal.

# Normalize species to the model's known set so predicted (already mapped by the
# driver) and observed (raw) are priced identically. Off-list codes -> OS / OH.
.acadgy_codes <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
.sw_codes <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
.normsp <- function(sp){ sp <- toupper(sp); ifelse(sp %in% .acadgy_codes, sp, ifelse(sp %in% .sw_codes, "OS", "OH")) }
.spgrp <- function(sp){
  sp <- .normsp(sp)
  dplyr::case_when(
    sp %in% c("WP","RP","PP","JP","RN","SCP") ~ "PINE",
    sp %in% c("RS","BF","BS","WS","NS","SPR") ~ "SF",
    sp %in% c("EH","WC","TA","HM","CE","OS") ~ "OSW",
    sp %in% c("SM","YB","RO","WO","BO","RB") ~ "PREMHW",
    TRUE ~ "HW")                                  # RM,PB,AB,QA,BC,WA,GB,BT,EC,etc
}
.price_saw  <- c(PINE=250, SF=115, OSW=120, PREMHW=300, HW=130)   # $/MBF
.price_pulp <- c(PINE=5,   SF=6,   OSW=6,   PREMHW=14,  HW=12)    # $/cord

# tree list: sp (AGY code), dbh_cm, expf_tph (per hectare). Returns one-row df.
plot_value <- function(sp, dbh_cm, expf_tph){
  ok <- is.finite(dbh_cm) & is.finite(expf_tph) & dbh_cm > 0
  sp <- sp[ok]; d_cm <- dbh_cm[ok]; e_tph <- expf_tph[ok]
  merch <- d_cm >= 11.43                                   # 4.5 in
  # plot structure (merch)
  BA_m2ha <- sum(pi*(d_cm[merch]/200)^2 * e_tph[merch])
  TPH     <- sum(e_tph[merch])
  QMD_cm  <- if (TPH>0) sqrt((BA_m2ha/TPH)/(pi/40000)) else NA_real_
  # height-free volume: single regional H-D, softwood vs hardwood
  sw <- .spgrp(sp) %in% c("PINE","SF","OSW")
  ht_m <- ifelse(sw, 1.3 + 27*(1-exp(-0.030*d_cm)), 1.3 + 25*(1-exp(-0.028*d_cm)))
  DBH_in <- d_cm/2.54; HT_ft <- ht_m/0.3048; e_ac <- e_tph/2.4710538147
  grp <- .spgrp(sp)
  sawlog <- merch & ((sw & DBH_in>=9) | (!sw & DBH_in>=11))
  pulp   <- merch & !sawlog
  sawMBF_ac  <- sum(0.01*DBH_in[sawlog]^2*HT_ft[sawlog]*e_ac[sawlog])/1000
  tcuft <- 0.0025*DBH_in^2*HT_ft
  pulpcord_ac <- sum(tcuft[pulp]*0.90*e_ac[pulp])/79
  # value: per-tree product value summed
  val_saw  <- sum( (0.01*DBH_in[sawlog]^2*HT_ft[sawlog]*e_ac[sawlog]/1000) * .price_saw[grp[sawlog]] )
  val_pulp <- sum( (tcuft[pulp]*0.90*e_ac[pulp]/79) * .price_pulp[grp[pulp]] )
  data.frame(BA_m2ha=BA_m2ha, TPH=TPH, QMD_cm=QMD_cm,
             sawMBF_ac=sawMBF_ac, pulpcord_ac=pulpcord_ac,
             value_ac=val_saw+val_pulp)
}
