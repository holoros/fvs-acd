# Open draft PRs on holoros/fvs-acd for heads that have none. Never merges, never marks ready. Token never printed. No em dashes.
# Usage: python3 open_draft_prs_20261026.py [--go]   (without --go it only reports)
import sys, requests
T = open('/home/aaron/.gh-holoros/token').read().strip()
H = {'Authorization': 'Bearer ' + T, 'Accept': 'application/vnd.github+json'}; R = 'https://api.github.com/repos/holoros/fvs-acd'
g = lambda p: requests.get(R + p, headers=H, timeout=30).json()
openp = g('/pulls?state=open&per_page=100')
for p in openp: print('open', p['number'], p['head']['ref'], '->', p['base']['ref'], 'draft', p['draft'])
WANT = [('v142-autopilot-20261026', 'v142-p46p47-docs-20261026',
         'FVS-ACD 14.2/14.3: PREREG2 and PREREG48 registered, release notes f, Howland cross-version projections',
         'Stacked on the v142-p46p47-docs-20261026 PR. Draft; do not merge before the PRs below it.\n\n'
         '- 14.3 PREREG2 (T form re-estimation) registered as revision 5 (md5 b7562e8b); not run.\n'
         '- PREREG48 (QC stems deficit split) registered as revision 1 (md5 61ab907e); second arm frozen qc_rh.\n'
         '- Release notes revision f (md5 08414cbc) with content inventory diff, unified diff, build script and render check.\n'
         '- Companion PREREG46 figure with one legend (the frozen figure is unchanged).\n'
         '- results/howland_20261026/: 13.1h and 14.0.4 L2 on the 93 Howland plots (OSC job 15888501), same runner, inputs and ESI as the frozen v141L run; figure, table, aggregate means and README comparing five versions. No plot identifiers.\n'
         '- Session handoffs.\n\n'
         'No engine file, coefficient or default of 14.1 changed.\n\n'
         '\U0001F916 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01EEanCNiLsFzoCJGfYY5gUr')]
for head, base, title, body in WANT:
    if [p for p in openp if p['head']['ref'] == head]: print('SKIP, PR exists for', head); continue
    c = g('/compare/%s...%s' % (base, head)); print(head, 'ahead', c.get('ahead_by'), 'behind', c.get('behind_by'), 'files', len(c.get('files', [])))
    assert '—' not in title + body
    if '--go' in sys.argv:
        r = requests.post(R + '/pulls', headers=H, timeout=30, json={'title': title, 'body': body, 'head': head, 'base': base, 'draft': True})
        print(r.status_code, r.json().get('html_url'), 'draft', r.json().get('draft')); assert r.status_code == 201
for b in ('engine-frozen-cardinal-20261019',):
    print(b, 'open PR:', [p['number'] for p in openp if p['head']['ref'] == b])
