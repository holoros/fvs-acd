# Identifier screen for files staged for the repository. Prints counts and file paths only, never matched values.
import os, re, sys, csv, glob
S = sys.argv[1]; idfiles = sys.argv[2:]
ids = set()
for f in idfiles:
    if f.endswith('.csv'):
        with open(f, newline='') as fh:
            r = csv.reader(fh); h = next(r)
            cols = [i for i, c in enumerate(h) if re.search(r'STAND|SITE|PLOT|INST|PLT|_ID$|^ID$', c, re.I)]
            for row in r:
                for i in cols:
                    if i < len(row) and len(row[i]) >= 6: ids.add(row[i])
    else:
        for line in open(f):
            v = line.strip()
            if len(v) >= 6 and not re.fullmatch(r'\d{1,7}', v): ids.add(v)
print("id values loaded:", len(ids))
keycol = re.compile(r'^(lat|lon|long|latitude|longitude|lat_dd|lon_dd|x_coord|y_coord|easting|northing|stand|stand_id|standid|plot|plot_id|plotid|plt_cn|cn|site|site_id|tree_cn|statecd|countycd|unitcd)$', re.I)
pats = {
 'howland_stand': re.compile(r'[A-Za-z]{7}__[A-Za-z]{2}_\d{3}__\d{4}_\d{4}_[A-Za-z]\d{2}'),
 'fia_stand': re.compile(r'[A-Za-z]{5}_[A-Za-z]__[A-Za-z]{3}\d{14,15}'),
 'long_digit_run': re.compile(r'(?<![\d.eE+-])\d{13,}(?![\d.])'),
 'latlon_word': re.compile(r'\b(lat|lon|LAT|LON|latitude|longitude|LATITUDE|LONGITUDE)\b'),
}
tok = re.compile(r'[A-Za-z0-9_.\-]+')
n = 0; refused = []; flags = []
for root, _, fs in os.walk(S):
    for fn in fs:
        p = os.path.join(root, fn); rel = os.path.relpath(p, S); n += 1
        if 'SERVERONLY' in fn.upper(): refused.append((rel, 'name')); continue
        try: t = open(p, encoding='utf8').read()
        except Exception: continue  # binary (png, pdf, tgz)
        if fn.endswith('.csv'):
            h = t.split('\n', 1)[0].replace('"', '').split(',')
            bad = [c for c in h if keycol.match(c.strip())]
            if bad: refused.append((rel, 'key or coordinate column: ' + ' '.join(bad)))
        hit = sum(1 for w in tok.findall(t) if w in ids)
        if hit: refused.append((rel, 'exact id values: %d' % hit))
        for k, rx in pats.items():
            c = len(rx.findall(t))
            if c: flags.append((rel, k, c))
print("files screened:", n)
print("REFUSE", len(refused)); [print("  ", r, why) for r, why in refused]
print("PATTERN FLAGS", len(flags)); [print("  ", r, k, c) for r, k, c in flags]
