cd ~/v143p3
[ -e logs/launch_md5s.txt ] && { echo "launch_md5s exists"; exit 3; }
t=$(date +%Y-%m-%dT%H:%M:%S%z)
for f in scripts/v143p3_fitframe.R scripts/v143p3_fit.R tools/s2_frame.sbatch tools/s3_fit.sbatch scripts/v143p3_conf_fia.R scripts/v143p3_conf_nbqc.py scripts/v143p3_conf_pool.py; do
  echo "$(md5sum $f | cut -d' ' -f1)  $f  launch md5 $t (after the dry runs dry/ and dry2/, before the frame step)" >> logs/launch_md5s.txt; done
J1=$(sbatch --parsable tools/s2_frame.sbatch)
J2=$(V143P3_VARIANT=p2repro sbatch --parsable --job-name=v143p3h2b --dependency=afterok:$J1 --cpus-per-task=8 --mem=16G --time=01:00:00 tools/s3_fit.sbatch)
J3=$(V143P3_VARIANT=primary sbatch --parsable --job-name=v143p3fit --dependency=afterok:$J1 tools/s3_fit.sbatch)
echo "frame $J1 h2b $J2 primary $J3" | tee -a logs/chain_jobs.txt
cat logs/launch_md5s.txt
