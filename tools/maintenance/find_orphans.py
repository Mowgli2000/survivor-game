"""Lists the files of assets/ that nothing seems to use (candidates for removal; nothing is moved or deleted).

A file counts as USED when its res:// path or its repo-relative path appears in any script, resource, scene, tool or
config text, or when its stem (name without extension and without trailing _N / -N) appears as a whole word in that text
(content ids, icons and sprites are found by id: the code builds those paths). The test errs on the side of "used".
Also prints the size of the big source folders. Usage: python tools/maintenance/find_orphans.py [out.md]"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TEXT_DIRS = ["src", "data", "tools", "tests", "localization", "addons"]
TEXT_EXT = (".gd", ".tres", ".tscn", ".gdshader", ".py", ".ps1", ".sh", ".json", ".cfg", ".csv", ".godot", ".md", ".txt")
SKIP_PARTS = ("addons/gut", "tools/maintenance")


def read_all():
    chunks = []
    for folder in TEXT_DIRS:
        for base, _dirs, files in os.walk(os.path.join(ROOT, folder)):
            rel = os.path.relpath(base, ROOT).replace("\\", "/")
            if any(p in rel for p in SKIP_PARTS):
                continue
            for name in files:
                if name.endswith(TEXT_EXT):
                    try:
                        chunks.append(open(os.path.join(base, name), encoding="utf-8", errors="ignore").read())
                    except OSError:
                        pass
    for name in ("project.godot", "export_presets.cfg"):
        path = os.path.join(ROOT, name)
        if os.path.exists(path):
            chunks.append(open(path, encoding="utf-8", errors="ignore").read())
    return "\n".join(chunks)


def folder_size(path):
    total = 0
    for base, _d, files in os.walk(path):
        for name in files:
            try:
                total += os.path.getsize(os.path.join(base, name))
            except OSError:
                pass
    return total


def mb(n):
    return "%.1f Mo" % (n / 1048576.0)


def main():
    text = read_all()
    words = set(re.findall(r"[A-Za-z0-9_]+", text))
    orphans = []
    total_files = 0
    for base, _dirs, files in os.walk(os.path.join(ROOT, "assets")):
        for name in files:
            if name.endswith((".import", ".uid")):
                continue
            total_files += 1
            full = os.path.join(base, name)
            rel = os.path.relpath(full, ROOT).replace("\\", "/")
            if rel in text:
                continue
            stem = os.path.splitext(name)[0]
            stem_clean = re.sub(r"[_-]\d+$", "", stem)
            if stem in words or stem_clean in words:
                continue
            orphans.append((rel, os.path.getsize(full)))
    orphans.sort(key=lambda t: -t[1])
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "a_supprimer", "ORPHELINS.md")
    lines = ["# Fichiers de `assets/` que rien ne semble utiliser", "",
             "Généré par `tools/maintenance/find_orphans.py`. **Rien n'a été déplacé ni supprimé.** Faux positifs possibles : "
             "à relire avant tout déplacement.", "",
             "%d fichiers examinés, %d candidats, %s au total." % (total_files, len(orphans), mb(sum(s for _p, s in orphans))), "",
             "| Fichier | Taille |", "|---|---|"]
    for rel, size in orphans:
        lines.append("| `%s` | %s |" % (rel, mb(size)))
    lines += ["", "## Tailles des dossiers sources", "", "| Dossier | Taille |", "|---|---|"]
    for folder in ["assets", "assets_src", "art_source", "art_tests", "art_showcase", "builds", "balance_reports", "a_supprimer"]:
        path = os.path.join(ROOT, folder)
        if os.path.isdir(path):
            lines.append("| `%s` | %s |" % (folder, mb(folder_size(path))))
    lines += ["", "## Sous-dossiers de `art_tests/` (non versionné)", "", "| Dossier | Taille |", "|---|---|"]
    tests = os.path.join(ROOT, "art_tests")
    if os.path.isdir(tests):
        subs = [(d, folder_size(os.path.join(tests, d))) for d in os.listdir(tests) if os.path.isdir(os.path.join(tests, d))]
        for d, size in sorted(subs, key=lambda t: -t[1])[:25]:
            lines.append("| `art_tests/%s` | %s |" % (d, mb(size)))
    open(out, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("%d files examined, %d orphan candidates, report: %s" % (total_files, len(orphans), out))


if __name__ == "__main__":
    main()
