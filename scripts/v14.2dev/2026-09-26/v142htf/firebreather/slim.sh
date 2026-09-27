#!/bin/bash
## Slim transfer set for PREREG11 scoring: all v141LTh chunk results, plus STAND,tree,ht,ing of pred_t2_tree for ns_c and ns_long_c (H2). Full outputs stay on firebreather.
set -e
S=~/jobs/v142htf/home/out/v141LTh; D=~/jobs/v142htf_xfer/slim
for s in ns_c ns_fl ns_long_c ns_long_fl baxter_c; do mkdir -p $D/$s; cp $S/$s/c*_results.csv $D/$s/; done
for s in ns_c ns_long_c; do for f in $S/$s/c*_pred_t2_tree.csv; do
  Rscript -e 'suppressMessages(library(data.table)); a<-commandArgs(TRUE); fwrite(fread(a[1], select=c("STAND","tree","ht","ing")), a[2])' $f $D/$s/$(basename $f); done; done
cd ~/jobs/v142htf_xfer && tar czf v141LTh_slim_2026-09-26.tgz slim && md5sum v141LTh_slim_2026-09-26.tgz > slim.md5 && echo SLIM_DONE
