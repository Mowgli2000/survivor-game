"""Balance report (ADR 0019): reads <dir>/runs/*.json written by the balance simulator and
writes <dir>/report.html (self-contained, inline SVG charts) and <dir>/summary.json.

    python tools/balance/report.py balance_reports/<name>

"Decent player" = policies dps + family (+ tank, economy); "random" = weak, unfocused player.
Targets (dev's choice, Brotato-like): Copper ~80 % wins, each seal harder, Astral ~20-30 %;
no "no need to move" before wave 18-19; classes within +-10 % of each other.
"""
import html
import json
import math
import os
import statistics
import sys
from collections import defaultdict

SEALS = ["Cuivre", "Fer", "Argent", "Or", "Obsidienne", "Astral"]
CLASS_NAMES = {"drifter": "Chasseur novice", "hero": "Assassin", "ronin": "Épéiste", "gunslinger": "Archer",
               "merchant": "Contrebandier", "mage": "Mage", "berserker": "Berserker"}
TARGET_WIN = [0.80, 0.68, 0.56, 0.44, 0.34, 0.25]
PALETTE = ["#3b82f6", "#ef4444", "#10b981", "#f59e0b", "#8b5cf6", "#ec4899", "#14b8a6", "#64748b"]
DECENT = {"dps", "family", "tank", "economy"}


def load(folder):
    runs = []
    for f in sorted(os.listdir(os.path.join(folder, "runs"))):
        if f.endswith(".json"):
            try:
                d = json.load(open(os.path.join(folder, "runs", f), encoding="utf-8"))
            except (OSError, ValueError):
                continue
            if d.get("outcome") in ("won", "died", "timeout"):
                runs.append(d)
    return runs


def rate(runs):
    return sum(r["won"] for r in runs) / len(runs) if runs else None


def median(values):
    return statistics.median(values) if values else None


def trivial_wave(run):
    """First wave from which the bot never loses more than 5 % HP again (the "no need to move" point)."""
    waves = run["waves"]
    for i, w in enumerate(waves):
        if all(x["damage_ratio"] <= 0.05 for x in waves[i:]) and len(waves) - i >= 2:
            return w["wave"]
    return None


def pct(value):
    return "—" if value is None else "%d %%" % round(value * 100)


def heat(value, target=None):
    if value is None:
        return "#eee"
    if target is not None:
        gap = value - target
        if abs(gap) <= 0.1:
            return "#bbf7d0"
        return "#fecaca" if gap > 0 else "#bfdbfe"
    return "hsl(%d, 70%%, 80%%)" % round(120 * value)


def line_chart(series, title, x_label, y_label, log=False, width=760, height=320, y_max=None):
    """series: {name: [(x, y), ...]} -> inline SVG."""
    pts = [(x, y) for s in series.values() for x, y in s if y is not None and (not log or y > 0)]
    if not pts:
        return "<p><em>%s : pas de données</em></p>" % html.escape(title)
    xs = [p[0] for p in pts]
    ys = [math.log10(p[1]) if log else p[1] for p in pts]
    x0, x1 = min(xs), max(xs)
    y0, y1 = (min(ys), max(ys)) if log else (0.0, y_max if y_max is not None else max(ys) * 1.08 or 1.0)
    if y1 <= y0:
        y1 = y0 + 1
    left, right, top, bottom = 56, 160, 30, 40
    pw, ph = width - left - right, height - top - bottom

    def px(x):
        return left + (x - x0) / max(x1 - x0, 1e-9) * pw

    def py(y):
        v = math.log10(y) if log else y
        return top + ph - (v - y0) / (y1 - y0) * ph

    out = ['<svg viewBox="0 0 %d %d" class="chart"><text x="%d" y="18" class="t">%s</text>' % (
        width, height, left, html.escape(title))]
    for k in range(5):
        v = y0 + (y1 - y0) * k / 4
        y = top + ph - ph * k / 4
        label = ("%.0f" % (10 ** v)) if log else ("%.2g" % v)
        out.append('<line x1="%d" x2="%d" y1="%.1f" y2="%.1f" class="g"/><text x="%d" y="%.1f" class="a" '
                   'text-anchor="end">%s</text>' % (left, left + pw, y, y, left - 6, y + 4, label))
    for x in sorted(set(xs)):
        out.append('<text x="%.1f" y="%d" class="a" text-anchor="middle">%s</text>' % (px(x), top + ph + 16, x))
    out.append('<text x="%d" y="%d" class="a">%s</text>' % (left + pw // 2 - 20, height - 4, html.escape(x_label)))
    out.append('<text x="12" y="%d" class="a" transform="rotate(-90 12 %d)">%s</text>' % (
        top + ph // 2 + 30, top + ph // 2 + 30, html.escape(y_label)))
    for i, (name, s) in enumerate(series.items()):
        color = PALETTE[i % len(PALETTE)]
        s = [(x, y) for x, y in s if y is not None and (not log or y > 0)]
        if not s:
            continue
        d = " ".join("%s%.1f,%.1f" % ("M" if j == 0 else "L", px(x), py(y)) for j, (x, y) in enumerate(s))
        out.append('<path d="%s" fill="none" stroke="%s" stroke-width="2.4"/>' % (d, color))
        ly = top + 14 + i * 18
        out.append('<rect x="%d" y="%d" width="12" height="4" fill="%s"/><text x="%d" y="%d" class="l">%s</text>' % (
            left + pw + 14, ly - 4, color, left + pw + 32, ly, html.escape(name)))
    out.append("</svg>")
    return "".join(out)


def per_wave(runs, key, seal=None, agg=median):
    by_wave = defaultdict(list)
    for r in runs:
        if seal is not None and r["seal"] != seal:
            continue
        for w in r["waves"]:
            if w.get(key) is not None:
                by_wave[w["wave"]].append(w[key])
    return [(wave, agg(v)) for wave, v in sorted(by_wave.items())]


def table(headers, rows):
    out = ["<table><tr>" + "".join("<th>%s</th>" % h for h in headers) + "</tr>"]
    for row in rows:
        out.append("<tr>" + "".join(row) + "</tr>")
    out.append("</table>")
    return "".join(out)


def model_section(folder, summary):
    """Fast model (balance_model.tscn): tier IV weapons ranked by DPS in a crowd."""
    path = os.path.join(folder, "model.json")
    if not os.path.exists(path):
        return ""
    rows = [r for r in json.load(open(path, encoding="utf-8"))["weapons"] if r["tier"] == 4]
    overall = median([r["crowd_dps"] for r in rows]) or 1.0
    out = []
    for r in sorted(rows, key=lambda r: -r["crowd_dps"]):
        ratio = r["crowd_dps"] / overall
        color = "#fecaca" if ratio > 1.8 else ("#bfdbfe" if ratio < 0.55 else "transparent")
        out.append(["<td>%s</td>" % r["weapon"], "<td>%s</td>" % ", ".join(r["families"]),
                    "<td>%s</td>" % ("mêlée" if r["melee"] else "distance"), "<td>%.0f</td>" % r["sheet_dps"],
                    "<td>%.1f</td>" % r["targets"], '<td style="background:%s">%.0f (×%.1f)</td>' % (
                        color, r["crowd_dps"], ratio), "<td>%.2f</td>" % r["crowd_dps_per_material"]])
        summary.setdefault("model_tier4", {})[r["weapon"]] = round(ratio, 2)
    return ("<h2>7. Modèle rapide : armes au rang IV dans une foule</h2><p>Sans combat : DPS écrit sur l'arme, "
            "nombre d'ennemis touchés par coup dans une foule dense (1 ennemi / 70×70 px, max 12), DPS de foule = "
            "les deux multipliés. Rouge = plus de 1,8× la médiane, bleu = moins de 0,55×.</p>" + table(
        ["Arme", "Familles", "Type", "DPS", "Cibles", "DPS de foule", "par matériau (vague 10)"], out))


def main(folder):
    runs = load(folder)
    decent = [r for r in runs if r["policy"] in DECENT]
    weak = [r for r in runs if r["policy"] == "random"]
    classes = sorted({r["character"] for r in runs})
    seals = sorted({r["seal"] for r in runs})
    summary = {"runs": len(runs), "decent": len(decent), "weak": len(weak)}
    parts = []

    # 1. Win rate by seal vs target.
    rows = []
    for s in seals:
        d = rate([r for r in decent if r["seal"] == s])
        wk = rate([r for r in weak if r["seal"] == s])
        tw = [trivial_wave(r) for r in decent if r["seal"] == s and r["won"]]
        tw = [t for t in tw if t]
        rows.append(["<td>%s</td>" % SEALS[s], '<td style="background:%s">%s</td>' % (heat(d, TARGET_WIN[s]), pct(d)),
                     "<td>%s</td>" % pct(TARGET_WIN[s]), "<td>%s</td>" % pct(wk),
                     "<td>%s</td>" % (median(tw) or "—")])
        summary.setdefault("win_by_seal", {})[SEALS[s]] = d
    parts.append("<h2>1. Victoires par sceau</h2><p>Vert = à ±10 points de la cible, rouge = trop facile, "
                 "bleu = trop dur. « Vague triviale » = médiane de la vague à partir de laquelle le bot ne perd "
                 "plus de PV (cible : 18-19 ou jamais).</p>" + table(
        ["Sceau", "Joueur correct", "Cible", "Joueur faible (au hasard)", "Vague triviale (médiane)"], rows))

    # 2. Class x seal heatmap.
    rows = []
    for c in classes:
        row = ["<td>%s</td>" % CLASS_NAMES.get(c, c)]
        for s in seals:
            v = rate([r for r in decent if r["character"] == c and r["seal"] == s])
            row.append('<td style="background:%s">%s</td>' % (heat(v, TARGET_WIN[s]), pct(v)))
        allv = rate([r for r in decent if r["character"] == c])
        row.append("<td><b>%s</b></td>" % pct(allv))
        summary.setdefault("win_by_class", {})[c] = allv
        rows.append(row)
    parts.append("<h2>2. Victoires par classe et par sceau (joueur correct)</h2>" + table(
        ["Classe"] + [SEALS[s] for s in seals] + ["Total"], rows))

    # 3. Curves.
    for s in [seals[0], seals[-1]] if len(seals) > 1 else seals:
        series = {CLASS_NAMES.get(c, c): per_wave([r for r in decent if r["character"] == c], "damage_ratio", s)
                  for c in classes}
        parts.append(line_chart(series, "PV perdus par vague (part des PV max), sceau %s" % SEALS[s], "vague",
                                "PV perdus / PV max", y_max=1.5))
        series = {CLASS_NAMES.get(c, c): per_wave([r for r in decent if r["character"] == c], "kill_ratio", s)
                  for c in classes}
        parts.append(line_chart(series, "Ennemis tués / apparus, sceau %s" % SEALS[s], "vague", "ratio", y_max=1.3))
    series = {CLASS_NAMES.get(c, c): per_wave([r for r in decent if r["character"] == c and r["seal"] == 0],
                                              "sheet_dps") for c in classes}
    parts.append("<h2>3. Courbes</h2>" + line_chart(series, "Puissance du build (DPS théorique), Cuivre", "vague",
                                                   "DPS (log)", log=True))
    series = {"matériaux en poche après la boutique": per_wave(decent, "materials_after_shop"),
              "dépensés à la boutique": per_wave(decent, "spent")}
    parts.append(line_chart(series, "Économie (médiane, joueur correct, tous sceaux)", "vague", "matériaux"))

    # 4. Deaths.
    deaths = defaultdict(int)
    for r in decent:
        if not r["won"]:
            deaths[r["wave_reached"]] += 1
    parts.append(line_chart({"défaites": sorted(deaths.items())}, "Vague de la défaite (joueur correct)", "vague",
                            "nombre de parties"))

    # 5. Weapons and items in final builds.
    def presence_table(key, label, extract):
        stats = defaultdict(list)
        for r in decent:
            for thing in set(extract(r)):
                stats[thing].append(r)
        base = rate(decent) or 0
        rows = []
        for thing, rs in sorted(stats.items(), key=lambda kv: -(rate(kv[1]) or 0)):
            if len(rs) < 4:
                continue
            v = rate(rs)
            gap = v - base
            color = "#fecaca" if gap > 0.15 else ("#bfdbfe" if gap < -0.15 else "transparent")
            rows.append(['<td>%s</td>' % thing, "<td>%d</td>" % len(rs),
                         '<td style="background:%s">%s</td>' % (color, pct(v)),
                         "<td>%+d pts</td>" % round(gap * 100)])
            summary.setdefault(key, {})[thing] = {"runs": len(rs), "win": v}
        intro = ("<h2>%s</h2><p>Présence dans le build final (joueur correct). Rouge = gagne bien plus souvent que "
                 "la moyenne (%s), bleu = bien moins (≥ 15 points).</p>" % (label, pct(base)))
        return intro + table(["Nom", "Parties", "Victoires", "Écart"], rows)

    parts.append(presence_table("weapons", "4. Armes", lambda r: [w.split(":")[0] for w in r["waves"][-1]["weapons"]]))
    parts.append(presence_table("items", "5. Objets", lambda r: [i.split(":")[0] for i in r.get("items", [])]))
    starters = defaultdict(list)
    for r in decent:
        starters[(r["character"], r["weapon"])].append(r)
    rows = [["<td>%s</td>" % CLASS_NAMES.get(c, c), "<td>%s</td>" % w, "<td>%d</td>" % len(rs),
             "<td>%s</td>" % pct(rate(rs)), "<td>%s</td>" % median([r["wave_reached"] for r in rs])]
            for (c, w), rs in sorted(starters.items())]
    parts.append("<h2>6. Armes de départ</h2>" + table(["Classe", "Arme", "Parties", "Victoires", "Vague (méd.)"],
                                                      rows))
    parts.append(model_section(folder, summary))
    timeouts = sum(1 for r in runs if r["outcome"] == "timeout")
    real = median([r["real_seconds"] for r in runs])

    page = """<!doctype html><html lang="fr"><head><meta charset="utf-8"><title>Rapport d'équilibrage</title>
<style>body{font:15px/1.5 system-ui,sans-serif;max-width:1000px;margin:24px auto;padding:0 16px;color:#1e293b;background:#fff}
h1{margin-bottom:4px}h2{margin-top:36px;border-bottom:2px solid #e2e8f0;padding-bottom:4px}
table{border-collapse:collapse;margin:8px 0}th,td{border:1px solid #e2e8f0;padding:4px 10px;text-align:left}
th{background:#f1f5f9}.chart{width:100%%;max-width:760px;display:block;margin:16px 0}
.t{font-weight:600;font-size:14px;fill:#1e293b}.a{font-size:11px;fill:#64748b}.l{font-size:12px;fill:#1e293b}
.g{stroke:#e2e8f0}.note{color:#64748b}</style></head><body>
<h1>Rapport d'équilibrage</h1><p class="note">%d parties simulées (%d « joueur correct », %d « joueur faible »),
%d hors délai, %s s de calcul par partie (médiane). Bot : se bat à la portée de ses armes, esquive les tirs, fuit
quand il est encerclé ; stratégies d'achat dps / famille / hasard. Les chiffres comparent classes, sceaux et
versions entre eux : un bot ne joue pas comme un humain.</p>%s</body></html>""" % (
        len(runs), len(decent), len(weak), timeouts, real, "".join(parts))
    open(os.path.join(folder, "report.html"), "w", encoding="utf-8").write(page)
    json.dump(summary, open(os.path.join(folder, "summary.json"), "w", encoding="utf-8"), indent=1)
    print("report:", os.path.join(folder, "report.html"))


if __name__ == "__main__":
    main(sys.argv[1])
