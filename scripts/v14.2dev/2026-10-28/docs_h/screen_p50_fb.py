# PREREG50 identifier screen, run on firebreather against the export tarball unpacked in /tmp/p50scr, using the STAND and SITE
# values of out/p50-stands_SERVERONLY.csv (read on the server, never printed). Prints counts and file paths only.
import csv,re,os
ids=set()
for row in csv.DictReader(open('out/p50-stands_SERVERONLY.csv')):
    ids.add(row['STAND']); ids.add(row['SITE'])
print('id values loaded',len(ids))
pat=re.compile(r'[A-Za-z]{2}__\d{8}[A-Za-z]\d')
key=re.compile(r'^(lat|lon|latitude|longitude|stand|site|plot|plot_id|stand_id|plt_cn|cn|x_coord|y_coord)$',re.I)
ll=re.compile(r'\b(lat|lon|LAT|LON|latitude|longitude)\b')
tok=re.compile(r'[A-Za-z0-9_.\-]+')
n=0;bad=[];fl=[]
for root,_,fs in os.walk('/tmp/p50scr'):
  for fn in fs:
    p=os.path.join(root,fn);rel=os.path.relpath(p,'/tmp/p50scr');n+=1
    if 'SERVERONLY' in fn.upper(): bad.append((rel,'name'));continue
    try:t=open(p,encoding='utf8').read()
    except Exception: continue
    if fn.endswith('.csv'):
      h=[c.strip().strip('"') for c in t.split('\n',1)[0].split(',')]
      b=[c for c in h if key.match(c)]
      if b: bad.append((rel,'key column '+' '.join(b)))
    k=sum(1 for w in tok.findall(t) if w in ids or pat.fullmatch(w))
    k2=len(pat.findall(t))
    if k or k2: bad.append((rel,'id values %d pattern %d'%(k,k2)))
    c=len(ll.findall(t))
    if c: fl.append((rel,'latlon word',c))
print('files',n,'REFUSE',len(bad));[print(' ',*x) for x in bad]
print('FLAGS',len(fl));[print(' ',*x) for x in fl]
