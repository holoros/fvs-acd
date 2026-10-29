# read-only: does topht_recal_diag exist in the repo tree at 4af1b2da or on main
import json, os, urllib.request
TOK = open(os.path.expanduser('~/.gh-holoros/token')).read().strip()
H = {'Authorization': 'Bearer ' + TOK, 'User-Agent': 'prereg43'}
for ref in ['4af1b2da3ba5c1ca8dccbeb38ef72f033f425152', 'main', 'v142-refinement-20260926']:
    d = json.loads(urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/holoros/fvs-acd/git/trees/%s?recursive=1' % ref, headers=H), timeout=60).read())
    hits = [t['path'] for t in d['tree'] if 'recal_diag' in t['path'] or 'topht_recal' in t['path']]
    print(ref[:12], 'entries', len(d['tree']), 'truncated', d.get('truncated'), 'hits', hits)
