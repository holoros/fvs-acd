#!/usr/bin/env python3
"""Extract modeled dominant height and a common volume proxy for Bakuzis checks.

Run on firebreather. Plot-level output remains restricted.
"""
import argparse,math,sqlite3,subprocess,tempfile
from pathlib import Path
import numpy as np
import pandas as pd
from run_seven_islands_100yr import BASE,FVS,KEY,OSM,OSM_LIB,HA,FT2_PER_M2HA,trees_for_plot

a=argparse.ArgumentParser();a.add_argument('model',choices=['FVS-NE','FVS-ACD','OSM']);args=a.parse_args()
p=pd.read_csv(BASE/'plots.csv',dtype={'Stand':str})
t=pd.read_csv(BASE/'trees.csv')
by={int(k):trees_for_plot(g) for k,g in t.groupby('PLOT_ID')}
rows=[];errors=[]
if args.model.startswith('FVS'):
    for i,plot in enumerate(p.itertuples(),1):
        trees=by.get(int(plot.PLOT_ID),[])
        if not trees:continue
        sid=f'P{int(plot.PLOT_ID)}'
        with tempfile.TemporaryDirectory(prefix='silc_bakuzis_fvs_') as td:
            d=Path(td);db=d/'fvsout.db'
            si=pd.DataFrame([dict(stand_id=sid,variant='NE' if args.model=='FVS-NE' else 'ACD',
                inv_year=int(plot.INV_YEAR),latitude=float(plot.LATITUDE),longitude=float(plot.LONGITUDE),
                region=9,forest=0,district=0,basal_area_factor=float(plot.BASAL_AREA_FACTOR),
                inv_plot_size=500,brk_dbh=float(plot.BRK_DBH),num_plots=1,age=60,aspect=0,slope=5,
                elevft=float(plot.ElevationMeters)/.3048,site_species=12,
                site_index=float(plot.ClimateSiteIndexMeters)/.3048,state=23,county=21,
                forest_type=121,sam_wt=1.)])
            ti=pd.DataFrame([dict(stand_id=sid,plot_id=1,tree_id=z['tree_id'],tree_count=1,
                species={'CE':'WC','WB':'PB'}.get(z['species'],z['species']),
                diameter=z['diameter'],ht=z['ht'],crratio=40) for z in trees])
            with sqlite3.connect(db) as c:
                si.to_sql('fvs_standinit',c,index=False)
                ti.to_sql('fvs_treeinit',c,index=False)
            (d/'run.key').write_text(KEY.format(sid=sid,db=db))
            r=subprocess.run([str(FVS[args.model]),'--keywordfile=run.key'],cwd=d,
                capture_output=True,text=True,timeout=600)
            try:
                with sqlite3.connect(db) as c:x=pd.read_sql_query('select Year,TopHt,BA from FVS_Summary2',c)
                assert len(x)>=21
                x['year_offset']=(x.Year-x.Year.min()).round().astype(int)
                for z in x.itertuples():
                    if z.year_offset not in range(0,101,5):continue
                    ht=float(z.TopHt)*.3048
                    ba=float(z.BA)/FT2_PER_M2HA
                    rows.append(dict(plot_id=int(plot.PLOT_ID),model=args.model,
                        year_offset=int(z.year_offset),HT=ht,VOL=ba*ht*.4))
            except Exception as e:errors.append((int(plot.PLOT_ID),str(e)[:200]))
        if i%40==0:print(args.model,i,'/',len(p),flush=True)
else:
    import sys
    sys.path.insert(0,str(OSM_LIB));import osm_engine as oe
    lookup=pd.read_csv(Path.home()/'perseus_me/me_state/v23_D/work/eng/osmwork/acd_plt_cn_lookup_with_bgi_csi.csv',usecols=['LAT','LON','BGI'])
    lookup=lookup[pd.to_numeric(lookup.BGI,errors='coerce')>0]
    lat=np.asarray(lookup.LAT,float);lon=np.asarray(lookup.LON,float);bgi=np.asarray(lookup.BGI,float)
    batches=[]
    for plot in p.itertuples():
        trees=by.get(int(plot.PLOT_ID),[])
        if not trees:continue
        dist=(lat-float(plot.LATITUDE))**2+((lon-float(plot.LONGITUDE))*math.cos(math.radians(45)))**2
        bg=int(round(np.median(bgi[np.argpartition(dist,5)[:5]])))
        rec=[]
        for z in trees:
            sp={'PB':'WB','TA':'TL','PC':'PR','CE':'WC','HE':'EH'}.get(z['species'],z['species'])
            if sp not in {'AB','AS','BA','BC','BF','BP','BS','BT','EC','EH','GA','GB','HH','HW','JP','NS','OH','OS','PR','QA','RB','RM','RN','RO','RP','RS','SB','SM','ST','SW','TL','WA','WB','WC','WP','WS','YB'}:
                sp='OS' if z['species']=='NC' else 'OH'
            rec.append((sp,z['diameter']*2.54,z['ht']*.3048 if z['ht']>0 else None,z['tpa']*HA))
        batches.append((int(plot.PLOT_ID),bg,rec))
    for start in range(0,len(batches),20):
        b=batches[start:start+20]
        with tempfile.TemporaryDirectory(prefix='silc_bakuzis_osm_') as td:
            oe.run_osm(str(OSM),td,[(i+1,z[1],z[2]) for i,z in enumerate(b)],105,5,set(range(21)))
            x=pd.read_csv(Path(td)/'ss.csv');x.columns=x.columns.str.strip()
            for i,z in enumerate(b):
                g=x[pd.to_numeric(x.SurveyID,errors='coerce')==i+1].copy()
                if g.empty:errors.append((z[0],'missing OSM summary'));continue
                g['year_offset']=(pd.to_numeric(g.Year)-pd.to_numeric(g.Year).min()).round().astype(int)
                for v in g.itertuples():
                    if v.year_offset not in range(0,101,5):continue
                    ht=float(v.T50HT);ba=float(v.BA)
                    rows.append(dict(plot_id=z[0],model=args.model,year_offset=int(v.year_offset),
                        HT=ht,VOL=ba*ht*.4))
        print(args.model,min(start+20,len(batches)),'/',len(batches),flush=True)
out=BASE/'results';pd.DataFrame(rows).to_csv(out/('bakuzis_height_'+args.model.lower().replace('-','_')+'.csv'),index=False)
pd.DataFrame(errors,columns=['plot_id','reason']).to_csv(out/('bakuzis_height_'+args.model.lower().replace('-','_')+'_errors.csv'),index=False)
print(args.model,len(rows),len(errors),flush=True)
