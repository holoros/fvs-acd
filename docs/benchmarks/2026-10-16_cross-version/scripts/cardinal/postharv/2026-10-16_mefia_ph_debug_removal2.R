## Diagnostic 2: how cut trees are coded at v1 in ME_TREE. Codes only. No em dashes.
suppressMessages(library(data.table))
cl <- fread("/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work/mefia_ph_class_DATA_2026-10-16.csv", colClasses = list(character = c("CN_V0","CN_V1","CN_V2")))
h <- names(fread("/users/PUOM0008/crsfaaron/fia_data/ME_TREE.csv", nrows = 0))
sel <- intersect(c("PLT_CN","STATUSCD","AGENTCD","AGENTCD_NERS","RECONCILECD","STANDING_DEAD_CD","TREECLCD","CCLCD","MORTCD","DIA","VOLCFNET"), h)
tr <- fread("/users/PUOM0008/crsfaaron/fia_data/ME_TREE.csv", select = sel, colClasses = list(character = "PLT_CN"))
d <- tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 2]
for (k in setdiff(sel, c("PLT_CN","STATUSCD","DIA","VOLCFNET"))) { cat("\n", k, "\n"); print(d[, .N, by = k][order(-N)][1:10]) }
cat("\nshare of STATUSCD 2 with DIA NA:", mean(is.na(d$DIA)), "\n")
cat("all ME_TREE STATUSCD:\n"); print(tr[, .N, by = STATUSCD])
