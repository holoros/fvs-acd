## Independent F9 re-derivation of PREREG19 headline numbers from results and scorer stands table. No coordinates.
suppressMessages({library(data.table); library(digest)})
J <- "/home/aaron/jobs/v142p19"
S <- fread(list.files(file.path(J,"tables"),"stands_DATA",full.names=TRUE)); S[,STAND:=as.character(STAND)]
fd <- function(x) ifelse(strtoi(substr(sapply(as.character(x), digest, algo="md5", serialize=FALSE),1,1),16L)%%2==0,"A","B")
out <- rbindlist(lapply(c("p19_a0030","p19_a0060","p19_a0111","p19_a0250","p19_a0500","p19_a1000"), function(a){
  r <- fread(file.path(J,"results",a,sprintf("gyr_%s_qc_c_results.csv",a)))[RUN_OK==1]; r[,STAND:=as.character(STAND)]
  v <- merge(S[label=="qc_c"&arm==a&cut==FALSE], r[,.(STAND,SITE,BA_o,BA_p,QMD_o,QMD_p)], by="STAND"); v[,fold:=fd(SITE)]
  v[,`:=`(T_o=BA_o/(pi/40000*QMD_o^2),T_p=BA_p/(pi/40000*QMD_p^2))]
  rbind(v[,.(arm=a,pop="scr",n=.N,C1h=sum(V_ph)/sum(V_oh),C1=sum(V_p)/sum(V_o))],
        v[,.(arm=a,pop=paste0("scr",fold),n=.N,sites=uniqueN(SITE),C1h=sum(V_ph)/sum(V_oh),C1=sum(V_p)/sum(V_o),
             bias_h=100*(mean(V_ph)-mean(V_oh))/mean(V_oh),rmse_h=100*sqrt(mean((V_ph-V_oh)^2))/mean(V_oh),
             ba=sum(BA_p)/sum(BA_o),stems=sum(T_p)/sum(T_o)),by=fold][,fold:=NULL], fill=TRUE)}))
print(out, digits=5)
fwrite(out,"p19_rederive_DATA_2026-09-28.csv")
