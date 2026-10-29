# model_b0b1b2.r -- p4e refit overlay. Substitutes refitted b0, b1, b2 into ddbh().
# Overlay on AcadianGY_13.1.r; does NOT edit it. Same functional form and link as line 1015,
# species deviation table and b3/b4/b5/b8 untouched. Defaults are the CURRENT v13.1 values, so
# with no env vars set this is byte-identical to base.
source("/users/PUOM0008/crsfaaron/AcadianGY_13.1.r")
.B0NEW <- as.numeric(Sys.getenv("B0NEW", "-1.64233500448509"))
.B1NEW <- as.numeric(Sys.getenv("B1NEW",  "0.37697814748048"))
.B2NEW <- as.numeric(Sys.getenv("B2NEW", "-0.0256836602459228"))
ddbh <- function(dbh, cr, bal.sw, bal.hw, csi, ddbh.b0.spp, ddbh.b2.spp, ddbh.b3.spp, ddbh.b4.spp, ht) {
  b0 = .B0NEW
  b1 = .B1NEW
  b2 = .B2NEW
  b3 = 0.713456068528815
  b4 = -0.0657468647965586
  b5 = -0.0177402942446082
  b8 = 0.135377049425137
  dbh = ifelse(dbh < 1, 1, dbh)
  ifelse(ht < 1.3716, 0, exp((b0 + ddbh.b0.spp) + (b1 * log(dbh)) + ((b2 + ddbh.b2.spp) * dbh) +
               ((b3 + ddbh.b3.spp) * log(cr)) + ((b4 + ddbh.b4.spp) * log(bal.sw + 0.1)) +
               (b5 * bal.hw) + (b8 * log(csi))))
}
cat("PATCHED ddbh: b0=", .B0NEW, " b1=", .B1NEW, " b2=", .B2NEW, "\n")
