# Create (or reuse) the Zenodo new version draft after published 1.8.0 record 23168366. Never publishes. No em dashes.
import requests, json, os
T=open('/home/aaron/.config/zenodo/token').read().strip(); H={"Authorization":f"Bearer {T}"}; API="https://zenodo.org/api"
S="/home/aaron/jobs/zen190_20261026/zen_190_state.json"
if os.path.exists(S): print("REUSE", open(S).read()); raise SystemExit
r=requests.post(f"{API}/deposit/depositions/23168366/actions/newversion",headers=H,timeout=120); print("newversion",r.status_code)
assert r.ok, r.text.replace(T,"***")[:300]
ld=r.json()["links"]["latest_draft"]; d=requests.get(ld,headers=H,timeout=60).json()
st={"draft_id":d["id"],"prereserve_doi":d["metadata"].get("prereserve_doi",{}).get("doi"),"files_inherited":len(d.get("files",[])),"bucket":d["links"]["bucket"]}
json.dump(st,open(S,"w")); print(st)
