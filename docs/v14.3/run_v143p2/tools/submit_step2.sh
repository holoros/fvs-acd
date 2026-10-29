#!/bin/bash
# submits the real step 2 and step 3 chain with dependencies (run on the login node; it only calls sbatch)
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p2; S=$P/scripts; T=$P/tools
a=$(sbatch --parsable $T/s2a.sbatch); echo "s2a $a"
h=$(sbatch --parsable --dependency=afterok:$a --array=1-$(( $(awk -F, '$2=="e0off"' $P/../v143p1/work/v143_taskmap_DATA.csv | wc -l) * 2 )) --export=ALL,V143_TASKMAP=$P/work/v143p2_taskmap_harness_DATA.csv $S/v143p2_arm_array.sbatch); echo "harness $h"
t=$(sbatch --parsable --dependency=afterok:$a --array=1 --export=ALL,V143_TASKMAP=$P/work/v143p2_taskmap_trH3_DATA.csv $S/v143p2_arm_array.sbatch); echo "trH3 $t"
s=$(sbatch --parsable --dependency=afterok:$a --array=1-2 --export=ALL,V143_TASKMAP=$P/work/v143p2_taskmap_sealed_A0_DATA.csv $S/v143p2_arm_array.sbatch); echo "sealedA0 $s (108 admitted stands in 2 chunks, as the dry build)"
g1=$(sbatch --parsable --dependency=afterok:$a --array=0-19 --export=ALL,V143_GRID_ARM=e0off $S/v143p2_grid.sbatch); echo "grid e0off $g1"
g2=$(sbatch --parsable --dependency=afterok:$a --array=0-19 --export=ALL,V143_GRID_ARM=C0f $S/v143p2_grid.sbatch); echo "grid C0f $g2"
b=$(sbatch --parsable --dependency=afterok:$s:$t $T/s2b_gf.sbatch); echo "s2b $b"
f=$(sbatch --parsable --dependency=afterok:$b $T/s3_fit.sbatch); echo "fit $f"
echo "$a $h $t $s $g1 $g2 $b $f" > $P/logs/chain_step2_jobs.txt
