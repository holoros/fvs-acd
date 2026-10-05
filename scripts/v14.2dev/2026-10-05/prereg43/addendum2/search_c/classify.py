# hand classification of hits_raw.csv (reviewed line by line with full patch context) -> hits_DATA.csv
import csv, collections
rows = list(csv.DictReader(open('hits_raw.csv')))
def cls(r):
    s, f, t = r['sha'][:8], r['file'], r['line']
    if s == '4af1b2da': return 'SET', 'states 0.111 is the observed over predicted QC top height increment ratio from topht_recal_diag.R; derivation stated, no computation in the line'
    if f.endswith('.csv') or f.startswith('20260629_FVS') or f in ('20260702_site_variable_bakeoff.md', '20260703_v13_kickoff_results.md'):
        return 'OTHER', 'numeric coincidence (scorecard, test statistic or table cell), not the multiplier'
    if 'QC_AFAC=0.111' in t or 'QC_AFAC 0.111' in t or 'QC 0.111' in t or 'Quebec 0.111' in t or t.startswith('+# 0.111)'):
        return 'SET', 'run setting recorded'
    full_ctx_set = ('+v13.0 was built but against the WRONG', '+Ops set inside bench_parity', '+The shipped model is v12.9.2', '+The model is a single R source')
    if t.startswith(full_ctx_set): return 'SET', 'run setting recorded (value beyond the 300 character cut; read in full patch context)'
    if t.startswith('+So four of the six anchors'): return 'USE', 'names ops$esi.domht.afac beside fitted CR values; afac not estimated'
    if '.afac' in t or 'afac' in t.lower(): return 'USE', 'reads or names the afac factor; no value estimated'
    return 'OTHER', ''
out = []
for r in rows:
    c, n = cls(r); out.append([r['sha'], r['date'], r['branch'], r['file'], c, r['line'][:300], n])
br = rows[0]['branch']
out.append(['a259273d (see commits_list.json)', '2026-07-02T10:32:32Z', br, 'scripts/topht_recal_diag.R', 'FIT',
            '+    pv, nrow(s), mean(s$f), 100*(mean(s$TOPHT_p)/mean(s$TOPHT_o)-1), mean(s$hgi_o), mean(s$hgi_p), mean(s$hgi_p)/mean(s$hgi_o), mean(s$esi8,na.rm=TRUE))) }',
            'estimates QC pred/obs top height increment ratio (commit message 8.9x QC; 4 Jul doc 8.89); inverse 0.1124 to 0.1125, does not round to 0.111; found by following the 4af1b2da reference, not by the pattern'])
for r in csv.DictReader(open('hits_supp_rounding.csv')):
    out.append([r['sha'], r['date'], br, r['file'], 'OTHER', r['line'][:300], 'supplementary rounding scan (0.1105 to 0.1114); test statistic or coefficient, not the multiplier'])
import json
full = {k[:8]: k for k in json.load(open('commits_list.json'))}
for o in out:
    if o[0].startswith('a259273d'): o[0] = full['a259273d']
with open('hits_DATA.csv', 'w', newline='') as fh:
    w = csv.writer(fh); w.writerow(['sha', 'date', 'branch', 'file', 'class', 'line', 'note']); w.writerows(out)
print(collections.Counter(o[4] for o in out))
for o in out:
    if o[4] in ('SET','USE','FIT'): print(o[0][:8], o[3], o[4], o[5][:90])
