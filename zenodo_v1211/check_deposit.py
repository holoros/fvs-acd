#!/usr/bin/env python3
"""Pre-publish gates for the FVS-ACD v12.11 Zenodo deposit.

Six gates, run in order, non-zero exit on any failure. Run this as the first
step of the publish driver so a failure stops the job before anything touches
the network.

Usage: check_deposit.py [--skip-freshness]
"""
import argparse
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, "files_to_upload.txt")
METADATA = os.path.join(HERE, "zenodo_metadata.json")
LEAD = "00_FVS-ACD_v1211_graphical_abstract.png"

ap = argparse.ArgumentParser()
ap.add_argument("--skip-freshness", action="store_true",
                help="only for a source touched for a non-content reason, with the render verified by eye")
args = ap.parse_args()

fails, warns = [], []


def entries():
    out = []
    for raw in open(MANIFEST, encoding="utf8"):
        line = raw.split("#")[0].strip()
        if line:
            out.append(line)
    return out


paths = entries()
resolved = [(p, os.path.normpath(os.path.join(HERE, p))) for p in paths]

print("=" * 74)
print("FVS-ACD v12.11 deposit gates")
print("=" * 74)

# ---------------------------------------------------------------- Gate 0
missing = [p for p, a in resolved if not os.path.exists(a)]
if missing:
    fails.append("Gate 0 existence: %d manifest paths do not exist: %s"
                 % (len(missing), ", ".join(missing[:6])))
print("\nGate 0  existence            %d files, %d missing"
      % (len(resolved), len(missing)))

# ---------------------------------------------------------------- Gate 1
meta = json.load(open(METADATA, encoding="utf8"))["metadata"]
g1 = []
if not paths or os.path.basename(paths[0]) != LEAD:
    g1.append("lead file is not first in the manifest")
if meta.get("default_preview") != LEAD:
    g1.append("default_preview does not name the lead file")
others = [os.path.basename(p) for p in paths[1:]]
if others and any(os.path.basename(LEAD) > o for o in others):
    g1.append("lead filename does not sort first")
if g1:
    fails.append("Gate 1 lead file: " + "; ".join(g1))
print("Gate 1  lead file            %s" % ("FAIL" if g1 else "pass"))

# ---------------------------------------------------------------- Gate 2
pairs, stale = [], []
for p, a in resolved:
    if a.endswith(".docx"):
        src = a[:-5] + ".md"
        if os.path.exists(src):
            pairs.append((src, a))
for src, out in pairs:
    if os.path.getmtime(out) < os.path.getmtime(src):
        stale.append("%s older than %s" % (os.path.basename(out), os.path.basename(src)))
if stale and not args.skip_freshness:
    fails.append("Gate 2 freshness: " + "; ".join(stale))
elif stale:
    warns.append("Gate 2 freshness WAIVED: " + "; ".join(stale))
print("Gate 2  source freshness     %d rendered pairs, %d stale%s"
      % (len(pairs), len(stale), " (waived)" if stale and args.skip_freshness else ""))

# ---------------------------------------------------------------- Gate 3
# Restricted-data audit. No override. Sweeps every staged file, not a sample.
CODE_SUFFIX = (".py", ".R", ".r", ".sh", ".slurm")
TEXTLIKE = CODE_SUFFIX + (".md", ".csv", ".txt", ".cff", ".json")
COORD_FIELDS = ["LAT_ACTUAL", "LON_ACTUAL", "ACTUAL_LAT", "ACTUAL_LON",
                "TRUE_LAT", "TRUE_LON", "LAT_FUZZ", "LON_FUZZ", "PLT_CN"]
TOKENS = ["_SERVERSIDE", "FIA.xy", "per_plot_embedding", "plot_coords"]
# Decimal degrees inside the Acadian envelope at 3+ decimals. A bare numeric
# range test is useless here: RMSE, percent RMSE and bias values land in the
# same range constantly (an rmse of 47.0614864894249 is not a latitude). The
# literal must therefore carry coordinate CONTEXT to count, either a
# coordinate-ish column header in a CSV or a lat/lon token nearby in prose or
# code. A latitude and longitude appearing as an adjacent pair also counts.
DD_LAT = r"-?(?:4[3-9]|5[0-2])\.\d{3,}"
DD_LON = r"-?(?:6[0-9]|7[0-1])\.\d{3,}"
DD_ANY = re.compile(r"(?<![\w.])(?:%s|%s)(?![\w.])" % (DD_LAT, DD_LON))
# The word boundary must sit AFTER the optional minus, or the pattern can never
# match a negative longitude, which is every longitude in the Acadian region.
DD_PAIR = re.compile(r"(?<![\w.])%s\s*[,;\s]\s*%s(?![\w.])" % (DD_LAT, DD_LON))
DMS = re.compile(r"\b\d{1,3}\s*[dD°]\s*\d{1,2}\s*['′]\s*\d{1,2}(?:\.\d+)?\s*[\"″]")
COORD_HDR = re.compile(r"^(lat|lon|long|latitude|longitude|x|y|xcoord|ycoord|x_coord|y_coord|"
                       r"lat_dd|lon_dd|plot_lat|plot_lon|lat_wgs84|lon_wgs84|point_x|point_y|"
                       r"geometry|wkt|utm_e|utm_n|coord\w*|easting|northing)$", re.I)
NEAR = re.compile(r"\b(lat|lon|long|latitude|longitude|coord|easting|northing|"
                  r"wgs84|epsg|crs)\b", re.I)

scanned = chars = 0
hard, waived = [], []
for p, a in resolved:
    if not a.endswith(TEXTLIKE) or not os.path.exists(a):
        continue
    txt = open(a, encoding="utf8", errors="replace").read()
    scanned += 1
    chars += len(txt)
    is_code = a.endswith(CODE_SUFFIX)
    for f in COORD_FIELDS:
        if re.search(r"\b%s\b" % re.escape(f), txt):
            hard.append("%s: true-coordinate field %s" % (os.path.basename(a), f))
    for tk in TOKENS:
        if tk in txt:
            # A script naming a restricted input path documents provenance and is
            # the reason to deposit it. The same token in a data file would be a
            # per-plot record and stays a hard failure.
            (waived if is_code else hard).append(
                "%s: token %s" % (os.path.basename(a), tk))

    # An adjacent lat/lon pair is a coordinate in PROSE or CODE, where writing two
    # such numbers side by side means a location. It is not evidence in a CSV,
    # where adjacent numeric columns are ordinary: five_way_scorecard.csv row 37
    # holds pai_pred 49.0390369296994 beside pai_bias -68.4838806501757, which
    # are periodic annual increments on stand value, not a coordinate. CSVs are
    # covered by the column-header test below, which is the right instrument.
    if not a.endswith(".csv"):
        m = DD_PAIR.search(txt)
        if m:
            hard.append("%s: decimal-degree PAIR %r" % (os.path.basename(a), m.group(0)[:40]))

    if a.endswith(".csv"):
        # Column-aware: flag a coordinate-range value only under a header that
        # names a coordinate.
        lines = txt.splitlines()
        if lines:
            hdr = [h.strip().strip('"') for h in lines[0].split(",")]
            bad = [i for i, h in enumerate(hdr) if COORD_HDR.match(h)]
            for ln in lines[1:]:
                cells = ln.split(",")
                for i in bad:
                    if i < len(cells) and DD_ANY.search(cells[i]):
                        hard.append("%s: coordinate column %r carries %s"
                                    % (os.path.basename(a), hdr[i], cells[i][:20]))
                        break
    else:
        # Prose and code: flag only when a coordinate word sits within 40 chars.
        for m in DD_ANY.finditer(txt):
            w = txt[max(0, m.start() - 40):m.end() + 40]
            if NEAR.search(w):
                hard.append("%s: decimal degrees near a coordinate term: %r"
                            % (os.path.basename(a), m.group(0)))
                break

    m = DMS.search(txt)
    if m:
        hard.append("%s: DMS string %r" % (os.path.basename(a), m.group(0)[:32]))
for w in waived:
    print("        waived (code only): %s" % w)
if hard:
    fails.append("Gate 3 RESTRICTED DATA: " + "; ".join(hard[:8]))
unscanned = [os.path.basename(a) for p, a in resolved if not a.endswith(TEXTLIKE)]
print("Gate 3  restricted data      %d files, %d chars scanned, %d hard, %d waived"
      % (scanned, chars, len(hard), len(waived)))
if unscanned:
    print("        NOT text-scannable (%d): %s" % (len(unscanned), ", ".join(unscanned)))
    warns.append("Gate 3 coverage: %d binary files not text-scanned: %s"
                 % (len(unscanned), ", ".join(unscanned)))

# ---------------------------------------------------------------- Gate 4
sums = {}
for p, a in resolved:
    if os.path.exists(a):
        h = hashlib.sha256()
        with open(a, "rb") as fh:
            for blk in iter(lambda: fh.read(1 << 20), b""):
                h.update(blk)
        sums[p] = h.hexdigest()
with open(os.path.join(HERE, "CHECKSUMS.sha256"), "w", encoding="utf8") as fh:
    for p in paths:
        if p in sums:
            fh.write("%s  %s\n" % (sums[p], p))
print("Gate 4  checksums            %d written to CHECKSUMS.sha256" % len(sums))

# ---------------------------------------------------------------- Gate 5
# Every deposited data file needs its producing script deposited too, or an
# explicit declaration that it is a compiled reference table with a named source.
REFERENCE_TABLES = {
    "data_dictionary.csv": "hand-written reference table",
    "five_way_scorecard.csv": "legacy n=733 scorecard, superseded by the frozen in-domain file; deposited for comparison only",
    "v1211_sample_sizes.csv": "compiled stand counts, derived from the scorecards deposited alongside",
    "master_scorecard.csv": "compiled by hand from the deposited per-source scorecards; see report Section 12",
    "overall_ranking.csv": "compiled by hand from the deposited per-source scorecards; see report Section 12",
    "overall_ranking_summary.csv": "rollup of overall_ranking.csv; see report Section 12",
    "bakuzis_longterm.csv": "compiled from the 160-year Bakuzis runs; source memo 20260723_bakuzis_longterm.md. Producing script not archived",
    "v1211_maturity_scorecard.csv": "lever-selection run (3a vs 3b) driven by bench_parity_split_ms_v131.R, which is deposited and consumes it; the ad-hoc write step was never archived. Cited by report Section 3 and GTR 10.4, so deposited with the gap disclosed",
}
# Producers are VERIFIED by reading each deposited script for a write call
# naming the table, not asserted from a hand-written map. An earlier version of
# this gate carried such a map and six of its thirteen entries were wrong, so
# the gate certified provenance it had never checked.
WRITE_CALL = re.compile(r"(?:fwrite|write\.csv|to_csv|write_csv)\s*\(", re.I)


def produced_by(csv_name, script_abs):
    """True if script_abs contains a write call and names csv_name."""
    try:
        src = open(script_abs, encoding="utf8", errors="replace").read()
    except OSError:
        return False
    return bool(WRITE_CALL.search(src)) and csv_name in src


script_abs = [a for p, a in resolved if a.endswith((".R", ".r", ".py"))]
g5 = []
for p in paths:
    b = os.path.basename(p)
    if not b.endswith(".csv"):
        continue
    if b in REFERENCE_TABLES:
        continue
    hits = [os.path.basename(s_) for s_ in script_abs if produced_by(b, s_)]
    if not hits:
        g5.append("%s: no deposited script writes it" % b)
if g5:
    fails.append("Gate 5 provenance: " + "; ".join(g5))
print("Gate 5  code reproduces data %d csv files, %d without a deposited producer"
      % (sum(1 for p in paths if p.endswith(".csv")), len(g5)))
for g in g5:
    print("        %s" % g)

# ---------------------------------------------------------------- Gate 6
g6 = []
for f in ("title", "upload_type", "creators", "description", "license", "version"):
    if not meta.get(f):
        g6.append("missing %s" % f)
for c in meta.get("creators", []):
    if "," not in c.get("name", ""):
        g6.append("creator not in 'Family, Given' form: %s" % c.get("name"))
for k in meta.get("keywords", []):
    if k != k.strip():
        g6.append("keyword has whitespace: %r" % k)
for ri in meta.get("related_identifiers", []):
    if "XXXX" in ri.get("identifier", "") or "PLACEHOLDER" in ri.get("identifier", "").upper():
        g6.append("placeholder DOI in related_identifiers")
if isinstance(meta.get("grants"), list) and not meta["grants"]:
    g6.append("empty grants array (omit it instead)")
RETIRED = ["1.58%", "runs 16% tall", "447 measured stems"]
desc = meta.get("description", "")
for rv in RETIRED:
    if rv in desc:
        g6.append("retired value in description: %s" % rv)
if g6:
    fails.append("Gate 6 metadata: " + "; ".join(g6))
print("Gate 6  metadata             %s" % ("FAIL" if g6 else "pass"))

# ---------------------------------------------------------------- verdict
print("\n" + "-" * 74)
for w in warns:
    print("WARN  " + w)
for f in fails:
    print("FAIL  " + f)
if fails:
    print("\nGATES FAILED. Nothing should be uploaded.")
    sys.exit(1)
print("\nAll gates passed. %d files staged." % len(resolved))
sys.exit(0)
