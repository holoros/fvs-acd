# read-only: list files of commit 4af1b2da and fetch full content of the stress_and_parity doc at that commit
import json, os, urllib.request, hashlib
TOK = open(os.path.expanduser('~/.gh-holoros/token')).read().strip()
H = {'Authorization': 'Bearer ' + TOK, 'User-Agent': 'prereg43'}
sha = [l.split(',')[0] for l in open('hits_raw.csv') if l.startswith('4af1b2da')][0]
d = json.loads(urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/holoros/fvs-acd/commits/' + sha, headers=H), timeout=60).read())
print(sha, d['commit']['committer']['date'], d['commit']['message'][:600])
for f in d['files']: print(' ', f['status'], f['filename'], f['changes'])
raw = urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/holoros/fvs-acd/contents/20260704_v12101_stress_and_parity.md?ref=' + sha, headers=dict(H, Accept='application/vnd.github.raw')), timeout=60).read()
open('evidence_4af1b2da_20260704_v12101_stress_and_parity.md', 'wb').write(raw)
print('md5', hashlib.md5(raw).hexdigest(), len(raw))
