# read-only: print full matching patch lines with context for named commits/files
import json, os, re, sys, urllib.request
TOK = open(os.path.expanduser('~/.gh-holoros/token')).read().strip()
targets = {'4af1b2da':['20260704_v12101_stress_and_parity.md'],
 'e5d74579':['20260708_v130_joint_and_v131_refit_results.md','20260710_v1210_freeze_and_v13_migration_plan.md','zenodo_v12101/README.md','20260710_v12101_FREEZE_and_run_recipe.md'],
 'bd03e858':['scripts/phase2/phase2_run_order.md']}
shas = {l.split(',')[0][:8]: l.split(',')[0] for l in open('hits_raw.csv') if l[:1] != 's'}
for k, files in targets.items():
    req = urllib.request.Request('https://api.github.com/repos/holoros/fvs-acd/commits/' + shas[k], headers={'Authorization': 'Bearer ' + TOK, 'User-Agent': 'prereg43'})
    d = json.loads(urllib.request.urlopen(req, timeout=60).read())
    for f in d['files']:
        if f['filename'] not in files: continue
        L = f.get('patch', '').split('\n')
        for i, ln in enumerate(L):
            if re.search(r'afac|AFAC|0\.111', ln):
                print('==', k, f['filename'], 'patchline', i); print('\n'.join(x[:700] for x in L[max(0, i-2):i+3])); print()
