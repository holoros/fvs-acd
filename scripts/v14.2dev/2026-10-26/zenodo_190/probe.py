# Read-only probe of Zenodo state for the FVS-ACD 14.2 concept record. No writes.
import requests
T=open('/home/aaron/.config/zenodo/token').read().strip(); H={"Authorization":f"Bearer {T}"}; API="https://zenodo.org/api"
r=requests.get(f"{API}/records/23168366",timeout=60); j=r.json()
print("rec 23168366",r.status_code,j.get("metadata",{}).get("version"),j.get("doi"),j.get("conceptdoi"))
r=requests.get(f"{API}/records/23168366/versions?size=20&sort=version",timeout=60)
for h in r.json().get("hits",{}).get("hits",[]): print(" version",h["id"],h["metadata"].get("version"),h["metadata"].get("publication_date"))
r=requests.get(f"{API}/deposit/depositions?size=40&sort=mostrecent",headers=H,timeout=60)
for d in r.json():
    if not d.get("submitted") or "FVS" in d.get("title","") or "Acadian" in d.get("title",""):
        print(" dep",d["id"],"submitted",d.get("submitted"),"state",d.get("state"),"ver",d.get("metadata",{}).get("version"),d.get("title","")[:70])
