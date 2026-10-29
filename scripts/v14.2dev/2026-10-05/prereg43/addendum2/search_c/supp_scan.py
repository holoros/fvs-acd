# read-only supplementary: values rounding to 0.111 (0.1105 to 0.11149) not caught by '0.111', plus files of a259273d
import json, os, re, urllib.request, csv
TOK = open(os.path.expanduser('~/.gh-holoros/token')).read().strip()
H = {'Authorization': 'Bearer ' + TOK, 'User-Agent': 'prereg43'}
B = 'https://api.github.com/repos/holoros/fvs-acd/'
R = re.compile(r'(?<![\d.])0\.110[5-9]\d*|(?<![\d.])0\.1114\d*')
commits = json.load(open('commits_list.json'))
rows = []
for sha, c in sorted(commits.items(), key=lambda kv: kv[1]['date']):
    d = json.loads(urllib.request.urlopen(urllib.request.Request(B + 'commits/' + sha, headers=H), timeout=60).read())
    if sha.startswith('a259273d'):
        print('a259273d files:', [(f['filename'], f['status']) for f in d['files']])
        for f in d['files']:
            for ln in (f.get('patch') or '').split('\n'):
                if re.search(r'8\.8|8\.9|ratio|QC', ln) and ln[:1] == '+' and not f['filename'].endswith('.csv'): print('   A2', f['filename'], ln[:400])
    for f in d['files']:
        for ln in (f.get('patch') or '').split('\n'):
            if ln[:1] in '+-' and not ln.startswith(('+++', '---')) and R.search(ln):
                rows.append([sha, c['date'], f['filename'], ln[:300]])
with open('hits_supp_rounding.csv', 'w', newline='') as fh:
    w = csv.writer(fh); w.writerow(['sha', 'date', 'file', 'line']); w.writerows(rows)
print('supp rows', len(rows))
for r in rows: print(r[0][:8], r[1], r[2], r[3][:200])
