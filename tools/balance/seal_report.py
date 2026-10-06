"""Per-seal summary of a simulator batch: wins, death waves, HP lost per wave
(waves 6/10/14/18), final boss and mini-boss kill times.
Usage: python tools/balance/seal_report.py <batch name in balance_reports/>
"""
import json, glob, statistics as st, sys, os
name = sys.argv[1]
runs = [json.load(open(f, encoding='utf-8')) for f in glob.glob(os.path.join(os.path.dirname(__file__), '..', '..', 'balance_reports', name, 'runs', '*.json'))]
print('==', name, len(runs), 'runs', '(static bot)' if runs and runs[0].get('static') else '')
for seal in range(6):
    rs = [r for r in runs if r['seal'] == seal]
    if not rs: continue
    wins = sum(r['won'] for r in rs)
    early = sum(1 for r in rs if not r['won'] and r['wave_reached'] < 10)
    deaths = sorted(r['wave_reached'] for r in rs if not r['won'])
    fin = [b['killed_after'] for r in rs for b in r.get('bosses', []) if b['wave'] == 20]
    mini = [b['killed_after'] for r in rs for b in r.get('bosses', []) if b['wave'] == 10]
    dmg = {}
    for w in (6, 10, 14, 18):
        v = [x['damage_ratio'] for r in rs for x in r['waves'] if x['wave'] == w]
        dmg[w] = st.median(v) if v else -1
    fk = [t for t in fin if t >= 0]
    mk = [t for t in mini if t >= 0]
    print('seal %d: wins %d/%d deaths %s | dmg w6 %.2f w10 %.2f w14 %.2f w18 %.2f | final boss killed %d/%d %s | mini %d/%d %s' % (
        seal, wins, len(rs), deaths, dmg[6], dmg[10], dmg[14], dmg[18], len(fk), len(fin),
        ('med %.0fs' % st.median(fk)) if fk else '', len(mk), len(mini), ('med %.0fs' % st.median(mk)) if mk else ''))
