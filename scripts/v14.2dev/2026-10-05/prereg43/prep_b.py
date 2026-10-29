# Searcher B: attach mtime and md5 to raw hits; write intermediate table (no per tree rows printed to console).
import os, hashlib, csv, re, datetime
OUT=os.path.expanduser('~/jobs/v142p43/search_b')
os.chdir(os.path.expanduser('~'))
md5c={}; mtc={}
def info(p):
    if p not in md5c:
        h=hashlib.md5()
        with open(p,'rb') as f:
            for b in iter(lambda: f.read(1<<20), b''): h.update(b)
        md5c[p]=h.hexdigest()
        mtc[p]=datetime.datetime.fromtimestamp(os.path.getmtime(p)).strftime('%Y-%m-%d %H:%M')
    return mtc[p], md5c[p]
rows=[]
with open(OUT+'/raw_hits_B.txt',encoding='utf-8',errors='replace') as f:
    for ln in f:
        ln=ln.rstrip('\n')
        m=re.match(r'^(.*?):(\d+):(.*)$',ln)
        if not m: continue
        p,n,t=m.groups()
        if not os.path.isfile(p):
            continue
        mt,md=info(p)
        rows.append((p,n,mt,md,t))
with open(OUT+'/hits_with_meta_B.tsv','w') as w:
    for r in rows:
        w.write('\t'.join([r[0],r[1],r[2],r[3],r[4].replace('\t',' ')])+'\n')
print(len(rows), len(md5c))
