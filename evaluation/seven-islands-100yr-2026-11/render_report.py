#!/usr/bin/env python3
"""Render the final aggregate report to print-friendly HTML and PDF."""
from pathlib import Path
import markdown2

O=Path(__file__).resolve().parent.parent/'outputs'
source=(O/'Seven_Islands_100yr_strata_review.md').read_text()
body=markdown2.markdown(source,extras=['tables'])
css='''
@page { size: A4 landscape; margin: 13mm; }
body {font: 10pt Arial,sans-serif; color: #14201a; line-height:1.27; max-width: 1100px; margin:auto;}
h1 {font-size:21pt; color:#134a31; margin-bottom:8px;} h2 {font-size:14pt; color:#134a31; border-bottom:1px solid #d3dcd6; padding-bottom:4px; margin-top:24px;}
p {margin:8px 0;} table {border-collapse:collapse;width:100%;font-size:8.4pt; margin:12px 0 14px; page-break-inside:avoid;}
th,td {padding:5px 6px;text-align:center;vertical-align:middle;} th {border-top:1px solid #14201a;border-bottom:1px solid #14201a;} tr:last-child td {border-bottom:1px solid #14201a;}
td:first-child,th:first-child {text-align:left;} img {max-width:93%; max-height:145mm; display:block; margin:10px auto; page-break-inside:avoid;}
a {color:#0072b2;} h2, h1 {page-break-after:avoid;}
'''
(O/'Seven_Islands_100yr_strata_review.html').write_text('<!doctype html><html><head><meta charset="utf-8"><style>'+css+'</style></head><body>'+body+'</body></html>')
