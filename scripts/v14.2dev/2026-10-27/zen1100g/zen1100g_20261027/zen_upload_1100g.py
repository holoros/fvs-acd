# Fill the Zenodo 1.10.0 new version draft with the 1.10.0 staging (revision g restage) files (flat names), set metadata, verify md5. Never publishes. No em dashes.
import requests, json, hashlib, os, time
T=open('/home/aaron/.config/zenodo/token').read().strip(); H={"Authorization":f"Bearer {T}"}; API="https://zenodo.org/api"
st=json.load(open("/home/aaron/jobs/zen1100f_20261026/zen_1100_state.json")); dep=st["draft_id"]
os.chdir("/home/aaron/jobs/gh_v142/zenodo_upload_p38p47_1100g")
L=[l.strip() for l in open("zenodo_upload_manifest_1100.txt") if l.strip() and not l.startswith("#")]
assert len(set(os.path.basename(x) for x in L))==len(L)
d=requests.get(f"{API}/deposit/depositions/{dep}",headers=H,timeout=60).json(); assert not d.get("submitted"), "published; refusing"
bucket=d["links"]["bucket"]
for f in d["files"]:
    r=requests.delete(f["links"]["self"],headers=H,timeout=60); assert r.status_code==204,(f["filename"],r.status_code)
print("deleted existing", len(d["files"]), flush=True)
for i,p in enumerate(L):
    n=os.path.basename(p)
    for a in range(3):
        with open(p,"rb") as fp: r=requests.put(f"{bucket}/{n}",headers=H,data=fp,timeout=600)
        if r.ok: break
        time.sleep(5)
    assert r.ok,(n,r.status_code,r.text.replace(T,"***")[:200])
    if i%25==0: print("uploaded",i+1,"of",len(L),flush=True)
md=json.load(open("zenodo_metadata.json"))["metadata"]
md.pop("communities",None)
md["prereserve_doi"]=True if False else md.get("prereserve_doi")
md={k:v for k,v in md.items() if v is not None}
r=requests.put(f"{API}/deposit/depositions/{dep}",headers={**H,"Content-Type":"application/json"},data=json.dumps({"metadata":md}),timeout=120)
print("metadata", r.status_code, r.text.replace(T,"***")[:300] if not r.ok else "ok", flush=True)
d=requests.get(f"{API}/deposit/depositions/{dep}",headers=H,timeout=60).json()
srv={f["filename"]:f["checksum"] for f in d["files"]}; bad=[]
for p in L:
    m=hashlib.md5(open(p,"rb").read()).hexdigest()
    if srv.get(os.path.basename(p))!=m: bad.append(os.path.basename(p))
print("files on server",len(srv),"manifest",len(L),"md5 mismatches",len(bad),bad[:5])
print("version",d["metadata"].get("version"),"doi",d["metadata"].get("prereserve_doi"),"submitted",d.get("submitted"))
print("ZEN_UPLOAD_DONE" if not bad and len(srv)==len(L) and r.ok else "ZEN_UPLOAD_PROBLEM")
