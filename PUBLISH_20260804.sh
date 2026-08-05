#!/usr/bin/env bash
# PUBLISH_20260804.sh
#
# Commit and push the 4 August 2026 FVS-ACD v12.11 work, then optionally stage
# the Zenodo draft. Run this on the laptop or Cardinal, NOT in Cowork: the
# sandbox cannot remove the stale git lock and cannot reach zenodo.org.
#
#   bash PUBLISH_20260804.sh            # git only, review before pushing
#   PUSH=1 bash PUBLISH_20260804.sh     # git commit and push
#   PUSH=1 ZENODO=1 bash PUBLISH_20260804.sh   # also create the Zenodo DRAFT
#
# Nothing here publishes to Zenodo. Creating a draft is the furthest it goes,
# because publishing a NEW record is not idempotent.

set -euo pipefail

REPO="${REPO:-$HOME/Documents/Claude/CRSF-Cowork/repos/fvs-acd}"
BRANCH="${BRANCH:-hardwood-formrisk-wip}"
TOKEN="${TOKEN:-$HOME/.zenodo_token}"

cd "$REPO"

# ---------------------------------------------------------------- 1. the lock
# A stale index.lock dated 27 July blocks every git write. The Cowork sandbox
# could not remove it (Operation not permitted on .git internals). Remove it
# only if no git process is actually running.
if [ -f .git/index.lock ]; then
  if pgrep -x git >/dev/null 2>&1; then
    echo "A git process is running. Not touching .git/index.lock. Aborting."
    exit 1
  fi
  echo "Removing stale .git/index.lock ($(date -r .git/index.lock '+%Y-%m-%d'))"
  rm -f .git/index.lock
fi

# ---------------------------------------------------------------- 2. safety
# Backups are covered by the *_PREV* rule in .gitignore. Verify that holds and
# that nothing sensitive or restricted is about to be staged.
echo
echo "== pre-commit safety sweep =="
git add -A --dry-run >/dev/null

BAD=$(git status --porcelain | awk '{print $NF}' | grep -iE '\.zenodo_token|_SERVERSIDE|tree_t2\.csv|plot_coords|\.pem$|\.key$|id_rsa' || true)
if [ -n "$BAD" ]; then
  echo "REFUSING TO COMMIT. Sensitive or restricted paths detected:"
  echo "$BAD"
  exit 1
fi
echo "  no token, key, per-tree list or coordinate file in the working tree"

PREV=$(git status --porcelain | awk '{print $NF}' | grep -c '_PREV' || true)
echo "  _PREV backups that would be staged: $PREV (expect 0; .gitignore covers them)"

# ---------------------------------------------------------------- 3. commit
git add -A
echo
echo "== staged =="
git status --short | head -40
echo "  ($(git diff --cached --name-only | wc -l | tr -d ' ') paths total)"

git commit -F - <<'MSG'
v12.11 benchmark: height-coverage census, rescores, and the Zenodo deposit

Closes the height-imputation work opened by the 29 July v13.1 pass and stages
the benchmark for archival.

Findings
- Coverage census across all 11 staged sources (SLURM 13305450). The managed
  sources carrying the central claim are the heavily imputed ones: CTRN 51.99%
  and NB+QC MagPlot 32.82% of t2 basal area, against PEF 4.02% and Baxter
  18.45%. The diameter-only curve runs 12 to 33 percent short on hardwood on
  every source large enough to be informative; its softwood direction varies.
- CTRN rescored under a fitted curve (SLURM 13306328): all three models move
  about 0.7 points together and the ordering and margins are unchanged, so the
  imputation did not manufacture the managed win.
- QC MagPlot's disclosed +9.46% volume flag reads +0.41% under the fitted
  curve. The flag is not withdrawn but is far smaller than published.
- Baxter closed at +0.38% for the v12.11 candidate, down from +6.92%, derived
  on the harness's own validated observed volumes. Lever 3b over 3a is
  vindicated: 3b lands at +0.38% where 3a would fall near -12.9%.
- Section 7 verified. Its source was recovered as scorecard_five_v1210_frozen
  (POOLED_indomain, n=705) and Table 7 reproduces exactly on all nine metrics.
- 95% intervals added throughout. On the legacy in-domain set the three most
  recent generations and OSM are not statistically separable on pooled total
  volume (SLURM 13309361 for the all-sites bootstrap).

Corrections
- Quebec MagPlot flag direction (volume relative to basal area, not the
  reverse), Table 24 Reineke verdict, the Quercus rubra coefficient basis, an
  impossible cell range, and a softwood sign error in the curve description.

Deposit
- zenodo_v1211/ staged, 40 files, all six gates passing. NOT uploaded.
- Gate 3 and Gate 5 both hardened after an adversarial audit found them
  certifying things they did not check: the coordinate-pair regex could never
  match a negative longitude, and Gate 5's producer map was hand-written and
  six of thirteen entries were wrong. Gate 5 now reads each script.
MSG

echo
echo "== commit created =="
git --no-pager log --oneline -1

# ---------------------------------------------------------------- 4. push
if [ "${PUSH:-0}" = "1" ]; then
  echo
  echo "== pushing to origin/$BRANCH =="
  git push origin "$BRANCH"
else
  echo
  echo "Not pushed. Review, then:  git push origin $BRANCH"
  echo "Or re-run with:            PUSH=1 bash PUBLISH_20260804.sh"
fi

# ---------------------------------------------------------------- 5. zenodo
if [ "${ZENODO:-0}" = "1" ]; then
  echo
  echo "== Zenodo: gates, then DRAFT =="
  [ -f "$TOKEN" ] || { echo "No token at $TOKEN"; exit 1; }
  cd "$REPO/zenodo_v1211"
  python3 check_deposit.py
  python3 upload_to_zenodo.py \
      --token-file "$TOKEN" \
      --metadata zenodo_metadata.json \
      --files-list files_to_upload.txt 2>&1 | tee upload_log.txt
  echo
  echo "DRAFT created. Open the edit URL above and confirm the graphical"
  echo "abstract previews at the top before publishing. Publishing a NEW"
  echo "record is NOT idempotent: re-running creates a second record."
fi
