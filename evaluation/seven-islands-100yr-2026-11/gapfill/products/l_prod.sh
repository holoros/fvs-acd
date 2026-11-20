#!/bin/bash
cd ~/jobs/silc_agmbench_100yr_20261117/products
export NCORES=3
~/bin/fbq run -t 3 -n silc_prod_merch -- Rscript 21_products.R > s21.log 2>&1 && ~/bin/fbq run -t 1 -n silc_prod_agg -- python3 22_products_aggregate.py > s22.log 2>&1 && ~/bin/fbq run -t 1 -n silc_prod_fig -- Rscript 23_products_figure.R > s23.log 2>&1
