echo "== magplot dirs"; ls ~/magplot | head -30; ls /fs/scratch/PUOM0008/crsfaaron/canada/magplot | head -40
echo "== psp files"; timeout 120 find ~ /fs/scratch/PUOM0008/crsfaaron -maxdepth 6 -iname '*psp*' -not -path '*/R/*' 2>/dev/null | head -40
echo "== treatment files"; timeout 120 find ~ /fs/scratch/PUOM0008/crsfaaron -maxdepth 7 -iname '*treatment*' -not -path '*/R/*' 2>/dev/null | head -40
echo FIND3_DONE
