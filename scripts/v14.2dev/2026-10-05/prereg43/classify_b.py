# Searcher B classifier per PREREG43 hit classes. Writes the hits table; per tree CSV rows are never written (counted only).
import os, re, csv, collections
OUT=os.path.expanduser('~/jobs/v142p43/search_b')
UNREL=re.compile(r'(koa|Koa|arena_|higy|perseus|howland|maine-sae|nb_multimap|cspi|lsog|menb|voicepass|silc_v32_docbuild/zenodo_upload/../)')
UNREL=re.compile(r'(koa|Koa|arena_|higy|perseus|howland|maine-sae|nb_multimap|cspi)')
SETRE=re.compile(r'(QC_AFAC(_SMALL|_LARGE)?\s*=\s*["\']?0\.111\b|\bQC\s*=\s*0\.111\b|Sys\.getenv\(\s*"QC_AFAC"\s*,\s*"0\.111")')
QCCTX=re.compile(r'(QC|qc|AFAC|afac|dht|DHTM|anchor|quebec|Quebec)')
rows=[]; cnt=collections.Counter(); csv_numeric=collections.Counter(); unrel=collections.Counter()
with open(OUT+'/hits_with_meta_B.tsv',encoding='utf-8',errors='replace') as f:
    for ln in f:
        p,n,mt,md,t=ln.rstrip('\n').split('\t',4)
        ext=os.path.splitext(p)[1]
        s=t.strip()
        cls=None; note=''
        if UNREL.search(p):
            cls='MENTION'; note='[unrelated] '
            unrel[('dht.mult' if 'dht.mult' in t else '0.111')]+=1
            if ext=='.csv':
                csv_numeric['unrelated_csv']+=1; cnt[cls]+=1; continue
        elif ext=='.csv':
            if n=='1' or re.search(r'QC_AFAC|qc_afac|\bafac\b|dht\.mult',t) or '/v142notes' in p:
                cls='USE' if not '/v142notes' in p else 'MENTION'
            else:
                cls='MENTION'; csv_numeric[p.split('/')[1] if p.startswith('jobs/') else p.split('/')[0]]+=1; cnt[cls]+=1; continue
        elif ext in ('.r','.R','.sh','.py') or (ext=='.md' and s.startswith('export ')):
            if s.startswith('#') :
                cls='MENTION'
            elif SETRE.search(t) and not re.search(r'message\(|echo |cat\(|sprintf\(|labs\(|fifelse\(', t):
                cls='SET'
            elif ext=='.py' and not SETRE.search(t):
                cls='MENTION'
            else:
                cls='USE'
        elif ext in ('.log','.txt'):
            cls='USE' if re.search(r'QC_AFAC|dht\.mult|afac',t) else ('USE' if QCCTX.search(t) else 'MENTION')
            if not QCCTX.search(t) and not re.search(r'QC_AFAC|dht\.mult',t):
                note='[unrelated] '
        else:
            cls='MENTION'
            if not QCCTX.search(t) and not re.search(r'QC_AFAC|dht\.mult',t): note='[unrelated] '
        cnt[cls]+=1
        ex=(note+s).replace('—','-')[:160]
        rows.append([p,n,mt,md,cls,ex])
with open(OUT+'/p43_hits_B_DATA_2026-10-05.csv','w',newline='') as w:
    cw=csv.writer(w); cw.writerow(['path','line','file_mtime','md5','class','text_excerpt'])
    for r in rows: cw.writerow(r)
print('class counts (all hits):',dict(cnt))
print('rows written:',len(rows))
print('numeric csv data hits not listed:',sum(v for k,v in csv_numeric.items() if k!='unrelated_csv'),'unrelated csv:',csv_numeric['unrelated_csv'])
print('unrelated by literal:',dict(unrel))
