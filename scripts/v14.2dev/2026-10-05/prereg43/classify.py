# PREREG43 searcher A: classify raw literal hits into SET, FIT, USE, MENTION and write the hits table.
# Per tree csv rows and anything that could be a coordinate are never copied into excerpts.
import os, re, csv, hashlib, datetime, collections
OUT = os.path.expanduser('~/jobs/v142p43/search_a')
H = os.path.expanduser('~')
FIT_FILES = {H+'/jobs/v142p23/scripts/2026-09-29_v142_p23_fit.R', H+'/jobs/v142p23/fit/log_fit.txt',
 H+'/jobs/v142p23/fit/gyr142-p23-fit-hinc-foldA_DATA_2026-09-29.csv',
 H+'/jobs/v142p28/scripts/2026-09-30_v142_p28_fit.R', H+'/jobs/xfer_p26p29/p28/scripts/2026-09-30_v142_p28_fit.R',
 H+'/jobs/v142p28/fit/gyr142-p28-fit-class-foldA_DATA_2026-09-30.csv', H+'/jobs/xfer_p26p29/p28/fit/gyr142-p28-fit-class-foldA_DATA_2026-09-30.csv',
 H+'/jobs/v142p19/assembled/gyr142-p19-selection_DATA_2026-09-28.csv'}
SET_RE = re.compile(r'(export\s[^#\n]*\bQC_AFAC(_SMALL|_LARGE)?=0\.111\b)|(QC_AFAC(_SMALL|_LARGE)?\s*=\s*"?0\.111\b(?!\d))|(\bQC\s*=\s*0\.111\b(?!\d))|("QC_AFAC=0\.111")|(QC_AFAC\s*<-\s*0\.111\b)')
COORD_RE = re.compile(r'(?i)\b(lat|lon|long|latitude|longitude|coord|easting|northing|utm)\b|-?\d{2,3}\.\d{4,}')
md5c, mtc = {}, {}
def fmeta(p):
    if p not in md5c:
        try:
            md5c[p] = hashlib.md5(open(p,'rb').read()).hexdigest()
            mtc[p] = datetime.datetime.fromtimestamp(os.path.getmtime(p)).strftime('%Y-%m-%d %H:%M')
        except Exception:
            md5c[p], mtc[p] = 'NA', 'NA'
    return mtc[p], md5c[p]
def hdr(p):
    try:
        with open(p, errors='replace') as f: return f.readline()
    except Exception: return ''
def clean(t):
    t = t.strip().replace('\t',' ')
    if COORD_RE.search(t): return '[excerpt withheld: possible coordinate or long numeric field]'
    return t[:160]
rows, agg = [], collections.Counter()
with open(OUT+'/raw_hits.txt', errors='replace') as f:
    for ln in f:
        ln = ln.rstrip('\n')
        m = re.match(r'^(.*?\.(?:r|R|md|txt|csv|json|sh|py|log)):(\d+):(.*)$', ln)
        if not m: agg['UNPARSED'] += 1; continue
        p, n, t = m.group(1), int(m.group(2)), m.group(3)
        ext = p.rsplit('.',1)[1]
        lit_qc = ('QC_AFAC' in t) or ('dht.mult' in t)
        if ext == 'csv':
            h = hdr(p).lower()
            anchor_tab = re.search(r'qc_afac|(^|,)afac(,|$)', h) and 'serveronly' not in p.lower() and 'tree' not in os.path.basename(p).lower()
            if p in FIT_FILES:
                cls, ex = 'FIT', clean(t)
            elif n == 1:
                cls, ex = 'USE', clean(t)
            elif anchor_tab:
                cls, ex = 'USE', clean(t)
            elif lit_qc and 'tree' not in os.path.basename(p).lower():
                cls, ex = 'MENTION', clean(t)
            else:
                agg[p] += 1; continue
            rows.append((p, n, cls, ex)); continue
        s = t.strip()
        if p in FIT_FILES: cls = 'FIT'
        elif ext in ('log',) or (ext == 'txt' and 'adds_' not in p):
            cls = 'USE' if (lit_qc or SET_RE.search(t)) else 'MENTION'
        elif SET_RE.search(t) and not s.startswith('#') and ext in ('r','R','sh','py'):
            cls = 'SET'
        elif ext == 'md' and re.match(r'^(export\s|qc141\)|p\d+\w*\)\s*export)', s) and SET_RE.search(t):
            cls = 'SET'
        elif ext in ('r','R','sh','py') and lit_qc and not s.startswith('#'):
            cls = 'USE'
        else:
            cls = 'MENTION'
        rows.append((p, n, cls, clean(t)))
with open(OUT+'/p43_hits_A_DATA_2026-10-05.csv','w',newline='') as f:
    w = csv.writer(f); w.writerow(['path','line','file_mtime','md5','class','text_excerpt'])
    for p,n,cls,ex in rows:
        mt, md = fmeta(p); w.writerow([p.replace(H,'~'), n, mt, md, cls, ex])
    for p,c in sorted(agg.items()):
        if p == 'UNPARSED': continue
        mt, md = fmeta(p)
        w.writerow([p.replace(H,'~'), 'NA', mt, md, 'MENTION', '%d matches of the literal 0.111 as numeric csv data, unrelated to the QC anchor; rows not copied' % c])
cnt = collections.Counter(r[2] for r in rows)
print('listed', dict(cnt), 'aggregated_files', len([k for k in agg if k!='UNPARSED']), 'aggregated_hits', sum(v for k,v in agg.items() if k!='UNPARSED'), 'unparsed', agg['UNPARSED'])
