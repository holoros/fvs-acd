#!/bin/bash
#SBATCH --job-name=v143p3conf
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=00:30:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p3/logs/conf_nbqc_%j.out
cd /users/PUOM0008/crsfaaron/v143p3
md5sum scripts/v143p3_conf_nbqc.py | tee -a logs/script_md5s.txt
python3 scripts/v143p3_conf_nbqc.py
