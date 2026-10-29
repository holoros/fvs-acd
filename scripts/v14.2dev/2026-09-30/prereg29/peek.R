suppressMessages(library(data.table)); options(width=250)
F <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
p <- fread(file.path(F,"bench_gyr_ns_c_pairs.csv"))
p[, prog := fifelse(grepl("^NS(_LONG)?__NS_RS_", STAND), "NS_RS", "NS_OP")]
for (cc in setdiff(names(p), c("STAND","SITE","OLD_STAND","PLOTKEY"))) { v <- p[[cc]]
  if (is.numeric(v) && uniqueN(v) > 12) print(p[, .(col=cc, n=.N, na=sum(is.na(get(cc))), min=min(get(cc),na.rm=T), med=median(get(cc),na.rm=T), max=max(get(cc),na.rm=T)), by=prog]) else print(p[, .N, by=.(prog, v=as.character(get(cc)))][order(prog, v)][, col:=cc][1:min(.N,20)]) }
