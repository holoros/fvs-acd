#!/usr/bin/env python3
"""Add one fast-forward commit to an EXISTING branch through the GitHub Git Data API (no git binary): blobs, tree on the head's
tree, commit with parent = current head, PATCH the ref (force false), then read every blob back and compare md5. Used to update
holoros/fvs-acd PR 29 (branch evaluation-2026-11-regional). Token read from file, masked in any error text."""
import argparse, base64, hashlib, json, sys, requests
ap = argparse.ArgumentParser()
ap.add_argument("--repo", required=True); ap.add_argument("--branch", required=True)
ap.add_argument("--add", action="append", default=[], metavar="REPO_PATH=LOCAL_FILE")
ap.add_argument("--message-file", required=True); ap.add_argument("--token-file", required=True)
ap.add_argument("--expect-head"); ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--result")
a = ap.parse_args()
tok = open(a.token_file).read().strip(); H = {"Authorization": f"Bearer {tok}", "Accept": "application/vnd.github+json"}
U = f"https://api.github.com/repos/{a.repo}"
def req(m, p, **k):
    r = requests.request(m, U + p, headers=H, timeout=60, **k)
    if r.status_code >= 300: sys.exit(f"STOP {m} {p}: HTTP {r.status_code} {r.text.replace(tok, '***')[:300]}")
    return r.json()
head = req("GET", f"/git/ref/heads/{a.branch}")["object"]["sha"]; print("head", head)
if a.expect_head and head != a.expect_head: sys.exit(f"STOP head {head} != expected {a.expect_head}")
base_tree = req("GET", f"/git/commits/{head}")["tree"]["sha"]
files = []
for s in a.add:
    p, f = s.split("=", 1); b = open(f, "rb").read(); files.append((p, b, hashlib.md5(b).hexdigest()))
    print(f"  {p} {len(b)} bytes md5 {files[-1][2]}")
if a.dry_run: print("DRY RUN OK"); sys.exit(0)
tree = [{"path": p, "mode": "100644", "type": "blob", "sha": req("POST", "/git/blobs", json={"content": base64.b64encode(b).decode(), "encoding": "base64"})["sha"]} for p, b, _ in files]
t = req("POST", "/git/trees", json={"base_tree": base_tree, "tree": tree})["sha"]
c = req("POST", "/git/commits", json={"message": open(a.message_file).read(), "tree": t, "parents": [head],
        "author": {"name": "Aaron Weiskittel", "email": "aaron.weiskittel@maine.edu"}})["sha"]
req("PATCH", f"/git/refs/heads/{a.branch}", json={"sha": c, "force": False})
now = req("GET", f"/git/ref/heads/{a.branch}")["object"]["sha"]
if now != c: sys.exit(f"STOP ref {now} != commit {c}")
for p, b, m in files:
    g = req("GET", f"/contents/{p}?ref={c}"); got = hashlib.md5(base64.b64decode(g["content"])).hexdigest()
    if got != m: sys.exit(f"STOP read-back md5 {p} {got} != {m}")
out = {"commit": c, "parent": head, "files": len(files)}; print(json.dumps(out))
if a.result: open(a.result, "w").write(json.dumps(out))
