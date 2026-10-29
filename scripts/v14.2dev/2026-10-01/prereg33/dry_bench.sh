#!/bin/bash
# PREREG33 benchmark assembly dry run: p33_dyn stood in by frozen p23_a1250; output to dry/bench_assembled. No em dashes.
cd /home/aaron/jobs/v142p33; P33_DRYRUN=1 Rscript scripts/2026-10-01_v142_p33_assemble_bench.R > logs/dry_bench_assemble.txt 2>&1; echo "dry bench exit $? $(date -Is)" >> logs/dry_bench_assemble.txt
