suppressMessages(library(data.table)); V <- "/home/aaron/jobs/v142p41/verify_20261002"
X <- rbind(fread(file.path(V, "partA_DATA_2026-10-02.csv")), fread(file.path(V, "partB_DATA_2026-10-02.csv")))
fwrite(X, file.path(V, "p41_verify_DATA_2026-10-02.csv")); cat(sprintf("rows %d\n", nrow(X)))
