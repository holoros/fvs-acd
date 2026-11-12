# Generate acd7/R/acd7_params.R from Greg Johnson's acdR 0.75 src/parameters.cpp (values copied verbatim).
# Usage: python3 acd7/tools/gen_params.py <acdR>/src/parameters.cpp acd7/R/acd7_params.R
import re,sys
src=open(sys.argv[1]).read(); out=open(sys.argv[2],'w')
def block(start):
    i=src.index(start); j=src.index('};',i); return src[i:j]
num=r'-?\d+(?:\.\d*)?(?:[eE]-?\d+)?'
w=out.write
w("# ACD7 (acdR 0.75, Greg Johnson Biometrics LLC, 2024) parameter tables.\n# Generated verbatim from src/parameters.cpp by tools/gen_params.py; do not edit by hand.\n\n")
# species_map
rows=re.findall(r'\{\s*(\d+),\s*\{\s*(-?\d+),\s*"(..)",\s*(true|false),\s*"([^"]*)"\s*\}\}',block('species_map = {{'))
w("acd7_species_map <- data.frame(\n  fia = c(%s),\n  idx = c(%s),\n  code = c(%s),\n  softwood = c(%s),\n  name = c(%s),\n  stringsAsFactors = FALSE)\n\n"%(
 ",".join(r[0] for r in rows),",".join(r[1] for r in rows),",".join('"%s"'%r[2] for r in rows),
 ",".join('TRUE' if r[3]=='true' else 'FALSE' for r in rows),",".join('"%s"'%r[4].replace('"','') for r in rows)))
rows=re.findall(r'\{\s*(\d+),\s*\{\s*"(..)",\s*(\d+)\s*\}\s*\}',block('species_crosswalk = {{'))
w("acd7_crosswalk <- data.frame(fia = c(%s), mapped = c(%s))\n\n"%(",".join(r[0] for r in rows),",".join(r[2] for r in rows)))
def arr(start,n):
    b=block(start); b=b[b.index('{')+1:]
    b=re.sub(r'/\*.*?\*/','',b)
    vals=re.findall(num,b); return vals
v=arr('species_attrib = {{',0); assert len(v)==71*5,len(v)
w("acd7_species_attrib <- matrix(c(%s), ncol = 5, byrow = TRUE,\n  dimnames = list(NULL, c(\"sg\",\"wd\",\"shade\",\"drought\",\"waterlog\")))\n\n"%",".join(v))
for nm,st in [('mcw','mcw_parms = {{'),('lcw','lcw_parms = {{')]:
    v=arr(st,0); assert len(v)==142,(nm,len(v))
    w("acd7_%s <- matrix(c(%s), ncol = 2, byrow = TRUE, dimnames = list(NULL, c(\"a1\",\"a2\")))\n\n"%(nm,",".join(v)))
b=block('hcb_parms = {'); b=b[b.index('{')+1:]; b=re.sub(r'/\*.*?\*/','',b); v=re.findall(num,b); assert len(v)==71,len(v)
w("acd7_hcb_re <- c(%s)\n\n"%",".join(v))
v=re.findall(num,block('hcb_fixed_parms = {{').split('{{')[1]); w("acd7_hcb_fixed <- c(%s)\n\n"%",".join(v))
for nm,st,k in [('htpred','htpred_parms = {{',6),('dht','dht_parms = {{',6),('dhcb','std::array<double,6>> dhcb_parms = {{',6),('ddbh','ddbh_parms = {{',6),('mort','mort_parms = {{',5)]:
    b=block(st); b=re.sub(r'//[^\n]*','',b)
    rows=re.findall(r'\{\s*(\d+),\s*\{([^}]*)\}\s*\}',b)
    keys=[];vals=[]
    for key,body in rows:
        vv=re.findall(num,body); assert len(vv)==k,(nm,key,vv); keys.append(key); vals+= vv
    w("acd7_p_%s <- matrix(c(%s), ncol = %d, byrow = TRUE,\n  dimnames = list(c(%s), paste0(\"b\", 0:%d)))\n\n"%(nm,",".join(vals),k,",".join('"%s"'%x for x in keys),k-1))
out.close()
