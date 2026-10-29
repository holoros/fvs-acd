# Publish the Zenodo 1.10.0 draft (Aaron approved on 26 October 2026) after re-checking state: unsubmitted, version 1.10.0, 100 files, md5 equal to staging. No em dashes.
import requests, json, hashlib, os
T=open('/home/aaron/.config/zenodo/token').read().strip(); H={"Authorization":f"Bearer {T}"}; API="https://zenodo.org/api"
st=json.load(open("/home/aaron/jobs/zen1100f_20261026/zen_1100_state.json")); dep=st["draft_id"]
os.chdir("/home/aaron/jobs/gh_v142/zenodo_upload_p38p47_1100g")
L=[l.strip() for l in open("zenodo_upload_manifest_1100.txt") if l.strip() and not l.startswith("#")]
d=requests.get(f"{API}/deposit/depositions/{dep}",headers=H,timeout=60).json()
print("before: submitted",d.get("submitted"),"files",len(d["files"]),"version",d["metadata"].get("version"))
if d.get("submitted"): print("ALREADY PUBLISHED", d.get("doi")); raise SystemExit
srv={f["filename"]:f["checksum"] for f in d["files"]}
bad=[os.path.basename(p) for p in L if srv.get(os.path.basename(p))!=hashlib.md5(open(p,"rb").read()).hexdigest()]
assert not bad and len(srv)==len(L)==100 and d["metadata"].get("version")=="1.10.0", ("refuse",bad[:5],len(srv))
r=requests.post(f"{API}/deposit/depositions/{dep}/actions/publish",headers=H,timeout=300); print("publish",r.status_code)
assert r.ok, r.text.replace(T,"***")[:300]
j=r.json(); print("doi",j.get("doi"),"conceptdoi",j.get("conceptdoi"),"url",j["links"].get("record_html") or j["links"].get("html"))
