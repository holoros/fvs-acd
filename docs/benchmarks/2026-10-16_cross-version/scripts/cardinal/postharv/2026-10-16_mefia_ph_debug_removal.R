## Diagnostic for the tree-linked removal in the mefia_ph_c classification. Identifiers and codes only. No em dashes.
suppressMessages(library(data.table))
cl <- fread("/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work/mefia_ph_class_DATA_2026-10-16.csv", colClasses = list(character = c("CN_V0","CN_V1","CN_V2")))
tr <- fread("/users/PUOM0008/crsfaaron/fia_data/ME_TREE.csv", select = c("CN","PLT_CN","PREV_TRE_CN","STATUSCD","DIA","TPA_UNADJ","VOLCFNET","RECONCILECD"),
            colClasses = list(character = c("CN","PLT_CN","PREV_TRE_CN")))
tr <- tr[PLT_CN %in% c(cl$CN_V0, cl$CN_V1)]
cat("v1 STATUSCD table:\n"); print(tr[PLT_CN %in% cl$CN_V1, .N, by = STATUSCD])
cat("v1 PREV_TRE_CN empty share:", tr[PLT_CN %in% cl$CN_V1, mean(is.na(PREV_TRE_CN) | PREV_TRE_CN == "")], "\n")
cat("example CN and PREV_TRE_CN strings:\n"); print(head(tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 3, .(CN, PREV_TRE_CN)], 3))
v0 <- tr[PLT_CN %in% cl$CN_V0 & STATUSCD == 1]
cat("v0 live trees:", nrow(v0), " matched by a v1 PREV_TRE_CN:", sum(v0$CN %in% tr$PREV_TRE_CN), "\n")
cat("v1 STATUSCD 3 trees with DIA NA:", tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 3, mean(is.na(DIA))], " VOLCFNET NA:", tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 3, mean(is.na(VOLCFNET))], "\n")
