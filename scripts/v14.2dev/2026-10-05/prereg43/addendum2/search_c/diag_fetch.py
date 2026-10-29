# read-only: fetch scripts/topht_recal_diag.R at 4af1b2da and its commit history
import json, os, urllib.request, hashlib
TOK = open(os.path.expanduser('~/.gh-holoros/token')).read().strip()
H = {'Authorization': 'Bearer ' + TOK, 'User-Agent': 'prereg43'}
B = 'https://api.github.com/repos/holoros/fvs-acd/'
hist = json.loads(urllib.request.urlopen(urllib.request.Request(B + 'commits?path=scripts/topht_recal_diag.R&per_page=100', headers=H), timeout=60).read())
for c in hist: print('hist', c['sha'][:8], c['commit']['committer']['date'], c['commit']['message'].split('\n')[0][:120])
raw = urllib.request.urlopen(urllib.request.Request(B + 'contents/scripts/topht_recal_diag.R?ref=4af1b2da3ba5c1ca8dccbeb38ef72f033f425152', headers=dict(H, Accept='application/vnd.github.raw')), timeout=60).read()
open('evidence_4af1b2da_topht_recal_diag.R', 'wb').write(raw)
print('md5', hashlib.md5(raw).hexdigest(), len(raw))
