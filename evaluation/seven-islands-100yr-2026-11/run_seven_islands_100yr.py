#!/usr/bin/env python3
"""Plot-level, no-treatment 100-year OSM, FVS-NE and FVS-ACD projections.

Run on firebreather. Input CSVs stay in the restricted job directory.
"""
import argparse, hashlib, json, math, os, sqlite3, subprocess, tempfile, time
from pathlib import Path
import pandas as pd
import numpy as np

BASE = Path(__file__).resolve().parent
FVS = {
    'FVS-NE': Path.home()/'jobs/fvs-build-9c99ff1/bin-v1_9c99ff1_fb/FVSne',
    'FVS-ACD': Path.home()/'jobs/acd142_fvsacd/lib/FVSacd',
}
OSM = Path.home()/'perseus_me/me_state/v23_D/work/eng/osm/OSM.ConsoleApp'
OSM_LIB = Path.home()/'perseus_me/tracks/G/engines/osm'
HA = 2.4710538147
FT2_PER_M2HA = 4.356

KEY = '''STDIDENT
{sid}
DATABASE
DSNIN
{db}
DSNOUT
{db}
STANDSQL
SELECT * FROM fvs_standinit WHERE stand_id = '%StandID%'
ENDSQL
TREESQL
SELECT * FROM fvs_treeinit WHERE stand_id = '%StandID%'
ENDSQL
END
DATABASE
SUMMARY            2
END
TIMEINT            0         5
NUMCYCLE          20
PROCESS
STOP
'''

def file_md5(path):
    return hashlib.md5(Path(path).read_bytes()).hexdigest()

def trees_for_plot(t):
    out=[]
    for r in t.itertuples():
        d=float(r.DIAMETER)
        # OSM Acadian requires DBH >= 1 cm. Apply that floor to every model.
        if not np.isfinite(d) or d*2.54<1: continue
        # Seven Islands' 20 BAF prism above 4.6 in; 1/500 ac subplot below it.
        tpa=20/(math.pi*(d/24)**2) if d>=4.6 else 500.0
        tpa*=float(r.TREE_COUNT)
        out.append(dict(tree_id=int(r.TREE_ID),species=str(r.SPECIES).strip().upper(),
                        diameter=d,ht=float(r.HT) if pd.notna(r.HT) and float(r.HT)>0 else 0.0,
                        tpa=tpa))
    return out

def fvs_plot(p, trees, model):
    sid=f'P{int(p.PLOT_ID)}'
    with tempfile.TemporaryDirectory(prefix='silcfvs_') as d:
        d=Path(d); db=d/'fvsout.db'
        si=pd.DataFrame([dict(stand_id=sid,variant='NE' if model=='FVS-NE' else 'ACD',
            inv_year=int(p.INV_YEAR),latitude=float(p.LATITUDE),longitude=float(p.LONGITUDE),
            region=9,forest=0,district=0,basal_area_factor=float(p.BASAL_AREA_FACTOR),inv_plot_size=500,
            brk_dbh=float(p.BRK_DBH),num_plots=1,age=60,aspect=0,slope=5,
            elevft=float(p.ElevationMeters)/0.3048,site_species=12,
            site_index=float(p.ClimateSiteIndexMeters)/0.3048,state=23,county=21,
            forest_type=121,sam_wt=1.0)])
        ti=pd.DataFrame([dict(stand_id=sid,plot_id=1,tree_id=x['tree_id'],tree_count=1,
            species=x['species'],diameter=x['diameter'],ht=x['ht'],crratio=40) for x in trees])
        with sqlite3.connect(db) as c:
            si.to_sql('fvs_standinit',c,index=False)
            ti.to_sql('fvs_treeinit',c,index=False)
        (d/'run.key').write_text(KEY.format(sid=sid,db=db))
        r=subprocess.run([str(FVS[model]),'--keywordfile=run.key'],cwd=d,
            capture_output=True,text=True,timeout=600)
        try:
            with sqlite3.connect(db) as c:
                x=pd.read_sql_query('select * from FVS_Summary2',c)
        except Exception as e:
            return [],f'summary missing: {e}; rc={r.returncode}; stderr={r.stderr[-250:]}'
        if len(x)<21: return [],f'only {len(x)} summary rows; rc={r.returncode}'
        yr=pd.to_numeric(x.Year,errors='coerce')
        offset=(yr-yr.min()).round().astype(int)
        rows=[]
        for _,v in x.assign(year_offset=offset).iterrows():
            if int(v.year_offset) in range(0,101,5):
                rows.append(dict(plot_id=int(p.PLOT_ID),stand_id=str(p.Stand),model=model,
                    year_offset=int(v.year_offset),calendar_year=int(p.INV_YEAR)+int(v.year_offset),
                    ba_ft2ac=float(v.get('BA',np.nan)),tpa=float(v.get('Tpa',np.nan)),
                    qmd_in=float(v.get('QMD',np.nan)),mcuft_ac=float(v.get('MCuFt',np.nan)),
                    bdft_ac=float(v.get('BdFt',np.nan))))
        return rows,('' if len(rows)==21 else f'{len(rows)} requested years')

def osm_all(plots, grouped, out, bgi_multiplier=1.0, model_label='OSM'):
    import sys
    sys.path.insert(0,str(OSM_LIB)); import osm_engine as oe
    # Use the same BGI lookup as the current November regional comparison.
    lpath=Path.home()/'perseus_me/me_state/v23_D/work/eng/osmwork/acd_plt_cn_lookup_with_bgi_csi.csv'
    lookup=pd.read_csv(lpath,usecols=['LAT','LON','BGI'])
    lookup=lookup[pd.to_numeric(lookup.BGI,errors='coerce')>0]
    lat=np.asarray(lookup.LAT,float); lon=np.asarray(lookup.LON,float); bgi=np.asarray(lookup.BGI,float)
    rows=[]; errors=[]
    batches=[]
    for p in plots.itertuples():
        trees=grouped.get(int(p.PLOT_ID),[])
        if not trees:
            errors.append(dict(plot_id=int(p.PLOT_ID),model=model_label,reason='no live input trees'))
            continue
        d=(lat-float(p.LATITUDE))**2+((lon-float(p.LONGITUDE))*math.cos(math.radians(45)))**2
        bg=int(round(np.median(bgi[np.argpartition(d,5)[:5]])*bgi_multiplier))
        rec=[]
        remap={'PB':'WB','TA':'TL','PC':'PR','CE':'WC','HE':'EH'}
        for x in trees:
            sp=remap.get(x['species'],x['species'])
            if sp not in {'AB','AS','BA','BC','BF','BP','BS','BT','EC','EH','GA','GB','HH','HW','JP','NS','OH','OS','PR','QA','RB','RM','RN','RO','RP','RS','SB','SM','ST','SW','TL','WA','WB','WC','WP','WS','YB'}:
                sp='OS' if x['species'] in {'NC'} else 'OH'
            rec.append((sp,x['diameter']*2.54,x['ht']*0.3048 if x['ht']>0 else None,x['tpa']*HA))
        batches.append((int(p.PLOT_ID),bg,rec,int(p.INV_YEAR),str(p.Stand)))
    for start in range(0,len(batches),20):
        b=batches[start:start+20]
        with tempfile.TemporaryDirectory(prefix='silcosm_') as d:
            got,bad,rc=oe.run_osm(str(OSM),d,[(i+1,x[1],x[2]) for i,x in enumerate(b)],105,5,set(range(21)))
            ss=Path(d)/'ss.csv'
            if not ss.exists():
                errors += [dict(plot_id=x[0],model=model_label,reason=f'no summary rc={rc}') for x in b]
                continue
            s=pd.read_csv(ss)
            s.columns=s.columns.str.strip()
            for i,x in enumerate(b):
                z=s[pd.to_numeric(s.get('SurveyID'),errors='coerce')==i+1].copy()
                if z.empty:
                    errors.append(dict(plot_id=x[0],model=model_label,reason=f'no rows rc={rc}'))
                    continue
                y=pd.to_numeric(z['Year'],errors='coerce'); z['offset']=(y-y.min()).round().astype(int)
                for v in z.itertuples():
                    off=int(v.offset)
                    if off not in range(0,101,5): continue
                    rows.append(dict(plot_id=x[0],stand_id=x[4],model=model_label,year_offset=off,
                        calendar_year=x[3]+off,ba_ft2ac=float(getattr(v,'BA'))*FT2_PER_M2HA,
                        tpa=float(getattr(v,'Trees'))/HA,qmd_in=float(getattr(v,'QMD'))/2.54,
                        mcuft_ac=np.nan,bdft_ac=np.nan))
                if set(pd.DataFrame(rows[-21:]).year_offset)!=set(range(0,101,5)):
                    errors.append(dict(plot_id=x[0],model=model_label,reason=f'incomplete years rc={rc}, bad={bad}'))
        print(f'OSM {min(start+20,len(batches))}/{len(batches)}',flush=True)
    return rows,errors

def main():
    a=argparse.ArgumentParser();a.add_argument('--head',type=int,default=0);a.add_argument('--models',default='FVS-NE,FVS-ACD,OSM');a.add_argument('--resume',action='store_true');args=a.parse_args()
    p=pd.read_csv(BASE/'plots.csv',dtype={'Stand':str});t=pd.read_csv(BASE/'trees.csv',dtype={'STAND_ID':str})
    if args.head:p=p.head(args.head)
    models=args.models.split(','); out=BASE/'results';out.mkdir(exist_ok=True)
    grouped={int(k):trees_for_plot(v) for k,v in t.groupby('PLOT_ID')}
    meta=dict(started=time.strftime('%Y-%m-%dT%H:%M:%S'),input_md5={f:file_md5(BASE/f) for f in ('plots.csv','trees.csv')},
        engine_md5={m:file_md5(FVS[m] if m in FVS else OSM) for m in models},plots=len(p),models=models,
        assumptions='No treatment; 5-year cycles; tree_count 1; BAF 20 at DBH >=4.6 in, otherwise 1/500 ac; FVS SI from CSI m; OSM BGI median of 5 nearest lookup plots.')
    (out/'meta.json').write_text(json.dumps(meta,indent=2))
    for model in models:
        dest=out/(model.lower().replace('-','_')+'.csv'); errdest=out/(model.lower().replace('-','_')+'_errors.csv')
        if args.resume and dest.exists():continue
        rows=[]; errors=[]
        if model=='OSM':rows,errors=osm_all(p,grouped,out)
        else:
            for i,plot in enumerate(p.itertuples(),1):
                trees=grouped.get(int(plot.PLOT_ID),[])
                if not trees:
                    errors.append(dict(plot_id=int(plot.PLOT_ID),model=model,reason='no live input trees'));continue
                z,e=fvs_plot(plot,trees,model);rows+=z
                if e: errors.append(dict(plot_id=int(plot.PLOT_ID),model=model,reason=e))
                if i%20==0: print(f'{model} {i}/{len(p)}',flush=True)
        pd.DataFrame(rows).to_csv(dest,index=False)
        pd.DataFrame(errors).to_csv(errdest,index=False)
        print(model,len(rows),len(errors),flush=True)

if __name__=='__main__':main()
