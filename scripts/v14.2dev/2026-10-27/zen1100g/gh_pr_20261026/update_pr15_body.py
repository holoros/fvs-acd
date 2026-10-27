# Update the body of draft PR #15 (holoros/fvs-acd) to describe the branch as of 27 October 2026. Never merges, never marks ready,
# never prints the token. Usage: python3 update_pr15_body.py [--go]. No em dashes.
import sys, requests
T = open('/home/aaron/.gh-holoros/token').read().strip()
H = {'Authorization': 'Bearer ' + T, 'Accept': 'application/vnd.github+json'}; R = 'https://api.github.com/repos/holoros/fvs-acd'
p = requests.get(R + '/pulls/15', headers=H, timeout=30).json()
assert p['head']['ref'] == 'v142-autopilot-20261026' and p['draft'] and p['state'] == 'open', (p.get('head', {}).get('ref'), p.get('draft'), p.get('state'))
body = ("Stacked on PR #14 (`v142-p46p47-docs-20261026`). Draft; merge only after the PRs below it.\n\n"
"**Records**\n"
"- 14.3 PREREG2 (T form re-estimation): registered revision 5 (b7562e8b) and run on October 27 (`docs/v14.3/run_v143p2/`). C2 selected, not adopted under rule 3 (survivor gate on mefia_ph_c); 14.3 keeps the 14.1 T. Sealed NH and VT confirmation open; climate site index fallback for 68 of 108 sealed stands by Aaron's decision.\n"
"- PREREG48 (QC stems deficit split): registered (61ab907e) and run; rule 3, 14.3 ingrowth track; RESULT r1 with an independent verification addendum (`scripts/v14.2dev/2026-10-26/rec_b/v142p48/`).\n"
"- PREREG49 (NS survival step, v141LTfi on measured stand lists): five server lookups, registered revision 1 (c2188088) and run; survival step not adopted, v141LTfi not cleared (`scripts/v14.2dev/2026-10-27/prereg49/`).\n"
"- Howland Research Forest: 13.1h and 14.0.4 L2 added to the five version comparison (`results/howland_20261026/`). No plot identifiers.\n"
"- Zenodo 1.10.0 drivers (restage with notes f and g, draft upload, publish) in `scripts/v14.2dev/2026-10-26/rec_b/`.\n\n"
"**Documentation**\n"
"- Release notes revisions f and g, each with build script, unified diff, content inventory diff and render check; numbers in g checked independently against the RESULT files.\n"
"- README status, VERSION_HISTORY Era 9 and 10, preregistration index and branch map updated.\n\n"
"No engine file, coefficient or default of 14.1 changed.\n\n"
"\U0001F916 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01EEanCNiLsFzoCJGfYY5gUr")
assert chr(0x2014) not in body
print('current title:', p['title'])
if '--go' in sys.argv:
    r = requests.patch(R + '/pulls/15', headers=H, timeout=30, json={'body': body, 'title': 'FVS-ACD 14.2/14.3: PREREG2, PREREG48 and PREREG49 runs, release notes f and g, Howland cross-version, docs update'})
    print(r.status_code, r.json().get('html_url'), 'draft', r.json().get('draft')); assert r.status_code == 200
