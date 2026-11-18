from pathlib import Path
import markdown2

O=Path(__file__).resolve().parent.parent/'outputs'
body=markdown2.markdown((O/'Seven_Islands_Bakuzis_assessment.md').read_text(),extras=['tables'])
css='''@page{size:A4 landscape;margin:14mm}body{font:10pt Arial,sans-serif;color:#14201a;line-height:1.25;max-width:1100px;margin:auto}h1{color:#134a31;font-size:21pt}h2{color:#134a31;font-size:14pt;border-bottom:1px solid #d3dcd6;margin-top:22px}p,li{margin:6px 0}table{border-collapse:collapse;width:100%;font-size:8pt;page-break-inside:avoid}th,td{padding:4px 5px;border-bottom:1px solid #ccd6cf;text-align:center;vertical-align:top}th:first-child,td:first-child{text-align:left}img{display:block;max-width:80%;max-height:130mm;margin:12px auto;page-break-inside:avoid}a{color:#0072b2}h1,h2{page-break-after:avoid}'''
(O/'Seven_Islands_Bakuzis_assessment.html').write_text('<!doctype html><html><head><meta charset="utf-8"><style>'+css+'</style></head><body>'+body+'</body></html>')
