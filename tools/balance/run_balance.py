"""Balance simulator runner (ADR 0019): plays many full runs headless in parallel
(src/debug/balance/balance_sim.tscn) and writes one JSON per run, then the report.

    python tools/balance/run_balance.py [--characters all|a,b] [--seals 0-5] [--weapons both|first]
        [--policies dps,family,random] [--seeds 1] [--workers 14] [--out balance_reports/<name>]

Each run takes 1-3 min of CPU; runs are independent, so workers ~ cores - 2.
Then: python tools/balance/report.py <out>  (done automatically at the end).
"""
import argparse
import datetime
import itertools
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GODOT = os.environ.get("GODOT_BIN", r"C:\Program Files\Godot\Godot.exe")


def _ids(folder):
    return sorted(f[:-5] for f in os.listdir(os.path.join(ROOT, "data", folder)) if f.endswith(".tres"))


def _starting_weapons(character):
    text = open(os.path.join(ROOT, "data", "characters", character + ".tres"), encoding="utf-8").read()
    paths = dict(re.findall(r'path="res://data/weapons/([a-z_]+)\.tres" id="(w\d)"', text))
    order = re.search(r'starting_weapons = [^\n]*', text)
    ids = {v: k for k, v in paths.items()}
    return [ids[w] for w in re.findall(r'ExtResource\("(w\d)"\)', order.group(0))] if order else []


def _seals(spec):
    if "-" in spec:
        a, b = spec.split("-")
        return list(range(int(a), int(b) + 1))
    return [int(s) for s in spec.split(",")]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--characters", default="all")
    parser.add_argument("--seals", default="0-5")
    parser.add_argument("--weapons", default="both", choices=["both", "first"])
    parser.add_argument("--policies", default="dps,family,random")
    parser.add_argument("--seeds", type=int, default=1)
    parser.add_argument("--workers", type=int, default=max(1, (os.cpu_count() or 4) - 2))
    parser.add_argument("--out", default="")
    parser.add_argument("--endless", type=int, default=0, help="keep playing endless waves up to this wave")
    parser.add_argument("--static", action="store_true", help="the bot never moves (static build)")
    parser.add_argument("--static-after", type=int, default=0, help="the bot moves up to this wave, then stands still")
    args = parser.parse_args()

    characters = _ids("characters") if args.characters == "all" else args.characters.split(",")
    out = args.out or os.path.join(ROOT, "balance_reports", datetime.datetime.now().strftime("%Y%m%d_%H%M"))
    runs_dir = os.path.join(out, "runs")
    os.makedirs(runs_dir, exist_ok=True)
    jobs = []
    for character in characters:
        weapons = _starting_weapons(character)
        if args.weapons == "first":
            weapons = weapons[:1]
        for weapon, seal, policy, seed in itertools.product(weapons, _seals(args.seals),
                                                           args.policies.split(","), range(1, args.seeds + 1)):
            name = "%s_%s_s%d_%s_%d" % (character, weapon, seal, policy, seed)
            jobs.append((name, character, weapon, seal, policy, seed))
    print("%d runs, %d workers -> %s" % (len(jobs), args.workers, out), flush=True)
    subprocess.run([GODOT, "--headless", "--path", ROOT, "res://src/debug/balance/balance_model.tscn", "--",
                    "--out=" + os.path.join(out, "model.json")], capture_output=True, text=True, timeout=300)

    def run(job):
        name, character, weapon, seal, policy, seed = job
        path = os.path.join(runs_dir, name + ".json")
        if os.path.exists(path):
            return name, "cached"
        cmd = [GODOT, "--headless", "--path", ROOT, "--fixed-fps", "60", "res://src/debug/balance/balance_sim.tscn",
               "--", "--character=" + character, "--weapon=" + weapon, "--seal=%d" % seal,
               "--policy=" + policy, "--seed=%d" % seed, "--endless=%d" % args.endless, "--static=%d" % int(args.static), "--static_after=%d" % args.static_after, "--out=" + path]
        subprocess.run(cmd, capture_output=True, text=True, timeout=2400 if args.endless else 1200)
        if not os.path.exists(path):
            return name, "no output"
        return name, json.load(open(path, encoding="utf-8")).get("outcome")

    start = time.time()
    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for future in as_completed([pool.submit(run, j) for j in jobs]):
            done += 1
            name, outcome = future.result()
            print("[%d/%d %.0f min] %s: %s" % (done, len(jobs), (time.time() - start) / 60, name, outcome), flush=True)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "balance", "report.py"), out])


if __name__ == "__main__":
    main()
