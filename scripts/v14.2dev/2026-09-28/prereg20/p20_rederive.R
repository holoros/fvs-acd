## Independent F9 re-derivation of PREREG20 C1 volume numbers from the scorer stands table. No coordinates.
suppressMessages(library(data.table))
S <- fread(list.files("/home/aaron/jobs/v142p20/tables","stands_DATA",full.names=TRUE))
o <- S[, .(n=.N, C1_bias=100*(mean(V_ph)-mean(V_oh))/mean(V_oh), C1_rmse=100*sqrt(mean((V_ph-V_oh)^2))/mean(V_oh),
           C0_bias=100*(mean(V_p)-mean(V_o))/mean(V_o)), by=.(label,arm)]
print(o, digits=5); fwrite(o,"p20_rederive_DATA_2026-09-28.csv")
