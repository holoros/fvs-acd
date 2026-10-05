#!/usr/bin/env python3
# PREREG43 addendum 2, part C: read-only scan of holoros/fvs-acd history up to 2026-07-10.
import json, os, re, sys, time, csv, urllib.request, urllib.error, urllib.parse
OUT = os.path.dirname(os.path.abspath(__file__))
TOK = open(os.path.expanduser('~/.gh-holoros/token')).read().strip()
REPO = 'holoros/fvs-acd'
UNTIL = '2026-07-10T23:59:59Z'
PAT = re.compile(r'QC_AFAC|qc_afac|AFAC|afac|0\.111')
FITPAT = re.compile(r'optim|nls\(|nlme|uniroot|optimi[sz]e|lm\(|glm\(|fit|solve|estimat|calibrat|grid|minimi|SSE|rmse|bias', re.I)
SETPAT = re.compile(r'(QC_AFAC|qc_afac|afac|AFAC)\w*\s*(=|<-|:=|:)\s*["\']?0?\.111|0\.111')
def get(url, accept='application/vnd.github+json'):
    for attempt in range(5):
        req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + TOK, 'Accept': accept,
                                                   'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'prereg43-search-c'})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode()), dict(r.headers)
        except urllib.error.HTTPError as e:
            body = e.read().decode()[:300]
            if e.code in (403, 429) and attempt < 4:
                reset = int(e.headers.get('X-RateLimit-Reset', time.time() + 60))
                wait = max(10, min(reset - time.time() + 5, 900)); log('rate limit, wait %d s: %s' % (wait, body)); time.sleep(wait); continue
            raise RuntimeError('HTTP %s %s %s' % (e.code, url, body))
        except Exception as e:
            log('retry %s %s' % (url, e)); time.sleep(5)
    raise RuntimeError('failed ' + url)
def log(m):
    with open(os.path.join(OUT, 'progress.log'), 'a') as f: f.write(time.strftime('%H:%M:%S ') + m + '\n')
def paged(url):
    out, page = [], 1
    while True:
        sep = '&' if '?' in url else '?'
        data, _ = get('%s%sper_page=100&page=%d' % (url, sep, page))
        if not data: break
        out += data
        if len(data) < 100: break
        page += 1
    return out
def classify(t):
    s = t[1:] if t[:1] in '+-' else t
    has_val = '0.111' in s
    has_var = re.search(r'afac', s, re.I) is not None
    if has_var and FITPAT.search(s) and not re.search(r'^\s*(export\s+)?\w*AFAC\w*\s*=\s*0\.111', s, re.I):
        return 'FIT?'   # candidate, reviewed by hand
    if has_val and has_var: return 'SET'
    if has_var: return 'USE'
    return 'OTHER'
branches = paged('https://api.github.com/repos/%s/branches' % REPO)
log('branches: %d %s' % (len(branches), [b['name'] for b in branches]))
commits = {}
for b in branches:
    q = 'https://api.github.com/repos/%s/commits?sha=%s&until=%s' % (REPO, urllib.parse.quote(b['name'], safe=''), UNTIL)
    try: cl = paged(q)
    except Exception as e: log('branch %s error %s' % (b['name'], e)); continue
    for c in cl:
        commits.setdefault(c['sha'], {'date': c['commit']['committer']['date'], 'msg': c['commit']['message'].split('\n')[0][:200], 'branches': []})['branches'].append(b['name'])
    log('branch %s: %d commits (unique so far %d)' % (b['name'], len(cl), len(commits)))
json.dump(commits, open(os.path.join(OUT, 'commits_list.json'), 'w'), indent=1)
rows, nfiles, truncated = [], 0, []
for i, (sha, c) in enumerate(sorted(commits.items(), key=lambda kv: kv[1]['date'])):
    d, _ = get('https://api.github.com/repos/%s/commits/%s' % (REPO, sha))
    files = d.get('files', []); nfiles += len(files)
    if len(files) >= 300: truncated.append(sha)
    for f in files:
        patch = f.get('patch')
        if patch is None and PAT.search(f['filename']):
            rows.append([sha, c['date'], ';'.join(c['branches']), f['filename'], 'OTHER', '[no patch; filename match]', c['msg']])
        if not patch: continue
        for ln in patch.split('\n'):
            if ln.startswith('@@') or not PAT.search(ln): continue
            if ln[:1] not in '+-': continue
            rows.append([sha, c['date'], ';'.join(c['branches']), f['filename'], classify(ln), ln[:300], c['msg']])
    if i % 25 == 0: log('commit %d/%d rows %d' % (i, len(commits), len(rows)))
with open(os.path.join(OUT, 'hits_raw.csv'), 'w', newline='') as fh:
    w = csv.writer(fh); w.writerow(['sha', 'date', 'branch', 'file', 'class', 'line', 'message']); w.writerows(rows)
cs = {}
for q in ['0.111+repo:' + REPO, 'QC_AFAC+repo:' + REPO]:
    try:
        d, _ = get('https://api.github.com/search/code?q=' + q + '&per_page=100', 'application/vnd.github.text-match+json')
        cs[q] = {'total_count': d.get('total_count'), 'incomplete': d.get('incomplete_results'),
                 'items': [{'path': it['path'], 'fragments': [m.get('fragment', '')[:300] for m in it.get('text_matches', [])]} for it in d.get('items', [])]}
    except Exception as e: cs[q] = {'error': str(e)}
    time.sleep(7)
json.dump(cs, open(os.path.join(OUT, 'code_search.json'), 'w'), indent=1)
json.dump({'branches': [b['name'] for b in branches], 'commits': len(commits), 'files_changed': nfiles, 'commits_300plus_files': truncated, 'rows': len(rows)}, open(os.path.join(OUT, 'summary.json'), 'w'), indent=1)
log('DONE')
