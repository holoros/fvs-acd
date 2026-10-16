"""Build the FVS-ACD cross-version benchmark workbook from the acdx analysis CSVs (aggregates only, no plot identifiers).
Usage: python3 build_acdx_xlsx.py <analysis_dir> <out.xlsx>"""
import sys, csv
from openpyxl import Workbook
from openpyxl.cell.rich_text import CellRichText, TextBlock
from openpyxl.cell.text import InlineFont
from openpyxl.styles import Alignment, Font, Border, Side
from openpyxl.utils import get_column_letter

R, out = sys.argv[1], sys.argv[2]
def rd(f):
    with open(f"{R}/{f}") as fh: return list(csv.DictReader(fh))
VN = {"v131h": "13.1h", "v141off": "14.0.4 L2", "v141LT": "14.1"}
B = InlineFont(b=True); SUP = InlineFont(vertAlign="superscript", b=True)
def hdr(txt):
    if "^" not in txt: return txt
    parts, s = [], txt
    while "^" in s:
        pre, rest = s.split("^", 1); e = ""
        while rest and rest[0] in "-0123456789": e += rest[0]; rest = rest[1:]
        parts += [TextBlock(B, pre), TextBlock(SUP, e.replace("-", "−"))]; s = rest
    if s: parts.append(TextBlock(B, s))
    return CellRichText(parts)
thin = Side(style="thin"); ctr = Alignment(horizontal="center", vertical="center", wrap_text=True)
def num(x, d=3):
    try: return round(float(x), d)
    except Exception: return x
def sheet(wb, name, cols, rows, widths=None):
    ws = wb.create_sheet(name)
    for j, (h, _) in enumerate(cols, 1):
        c = ws.cell(1, j, hdr(h)); c.font = Font(bold=True); c.alignment = ctr; c.border = Border(top=thin, bottom=thin)
    for i, r in enumerate(rows, 2):
        for j, (_, f) in enumerate(cols, 1): ws.cell(i, j, f(r)).alignment = ctr
    last = len(rows) + 1
    for j in range(1, len(cols) + 1):
        if last > 1: ws.cell(last, j).border = Border(bottom=thin)
        ws.column_dimensions[get_column_letter(j)].width = (widths or {}).get(j, max(11, min(24, len(cols[j - 1][0]) + 2)))
    ws.row_dimensions[1].height = 42; ws.freeze_panes = "A2"
    return ws

wb = Workbook(); wb.remove(wb.active)
notes = [
 "FVS-ACD cross-version benchmark on Maine FIA plots (CRSF, October 16, 2026; DRAFT). Companion to the memo 2026-10-16_fvs-acd-crossversion-benchmark-memo_DRAFT.docx.",
 "Versions: 13.1h = AcadianGY 13.1 with hierarchical ingrowth and mortality posteriors (Seven Islands configuration); 14.0.4 L2 = linked mortality, 14.1 overlay with both gates off; 14.1 = current release (L and T on), equal to the 14.2 reference arm qc141 on Maine plots. 14.2 arms p38_fit and qc_rh were not run (engine copies on firebreather only).",
 "Hindcast: 19 frozen benchmark sets plus the new post-harvest Maine FIA set (mefia_ph_c, 827 stands). Paired stands only. Bias % = 100 (mean predicted / mean observed - 1) with 95% stand bootstrap interval (1,000 resamples).",
 "Equivalence: observed regressed on mean-centred predicted; intercept test on mean observed minus mean predicted with region +/- 25% of mean observed; slope region 1 +/- 0.25; 90% bootstrap intervals. Regions fixed before reading new output.",
 "Biomass: NSVB DRYBIO_AG of trees >= 5 cm dbh (Mg ha-1). For comparison with the Maine FIA AGB curves (10.5281/zenodo.23406410) engine biomass was scaled by the median FIADB/engine ratio at t1 (1.067).",
 "Long horizon: 918 unmanaged Maine FIA stands (mefia_l_c t1 tree lists) projected 200 yr without harvest; stand age from FIA STDAGE; forest type group from FORTYPCD.",
 "Volume is scored under the published convention (C0), which equals measured height scoring on FIA plots; Seven Islands figures use the 120 stand frame, not the 65 routine plots of the SILC report.",
 "Bridge sheet: rescored frozen 14.x runs against the published bench141 per set scores; identical where stand sets match (differences arise only where the frozen scorer dropped stands)."]
ws = wb.create_sheet("README")
for i, t in enumerate(notes, 1): ws.cell(i, 1, t).alignment = Alignment(wrap_text=True, vertical="top")
ws.column_dimensions["A"].width = 150

sheet(wb, "Versions", [("Label", lambda r: r[0]), ("Engine and settings", lambda r: r[1]), ("Role", lambda r: r[2]), ("Status", lambda r: r[3])], [
  ["13.1h", "AcadianGY_13.1.r (md5 5894df60), USE_HIER_ING and USE_HIER_MORT TRUE, posteriors ~/v13_comb_post, ONSET 0.30", "Seven Islands long horizon configuration", "Run"],
  ["14.0.4 L2", "AcadianGY_14.0.4.r (61f95d99) over 13.1 with p4e model_b0b1b2.r, LINKED L2, 14.1 overlay (0bf27dde) gates off", "Last release before 14.1", "Run"],
  ["14.1", "As 14.0.4 L2 with LSDG_V141 and THIN_V141 on (coefs c8f02f55, RELCAP 2.9848)", "Current release; equals 14.2 qc141 on Maine plots", "Run"],
  ["14.2 p38_fit, qc_rh", "Frozen 14.2 candidate arms, Quebec height path only", "Engine copies on firebreather only", "Not run"]], {1: 18, 2: 70, 3: 40, 4: 10})

S = rd("acdx_hindcast_scores_DATA.csv")
sheet(wb, "Hindcast_scores", [("Set", lambda r: r["set"]), ("Version", lambda r: VN[r["arm"]]), ("Metric", lambda r: r["metric"]), ("Stands", lambda r: int(r["n"])),
  ("Mean observed", lambda r: num(r["mean_obs"], 2)), ("Mean predicted", lambda r: num(r["mean_pred"], 2)), ("Bias (%)", lambda r: num(r["bias_pct"], 2)),
  ("Bias lower 95%", lambda r: num(r["bias_lo"], 2)), ("Bias upper 95%", lambda r: num(r["bias_hi"], 2)), ("RMSE (%)", lambda r: num(r["rmse_pct"], 2)), ("R^2", lambda r: num(r["r2"], 3)),
  ("Obs minus pred mean", lambda r: num(r["dint"], 3)), ("Lower 90%", lambda r: num(r["dint_lo90"], 3)), ("Upper 90%", lambda r: num(r["dint_hi90"], 3)), ("Intercept region (+/-)", lambda r: num(r["int_region"], 3)),
  ("Slope", lambda r: num(r["slope"], 3)), ("Slope lower 90%", lambda r: num(r["slope_lo90"], 3)), ("Slope upper 90%", lambda r: num(r["slope_hi90"], 3)),
  ("Intercept equivalent", lambda r: r["int_equiv"]), ("Slope equivalent", lambda r: r["slope_equiv"]), ("Equivalent", lambda r: r["equiv"])], S)
sheet(wb, "Bridge_bench141", [("Set", lambda r: r["set"]), ("Version", lambda r: VN.get(r["arm"], r["arm"])), ("Metric", lambda r: r["metric"]), ("Stands, rescored", lambda r: int(r["n_new"])),
  ("Stands, frozen", lambda r: r["n_frozen"]), ("Bias rescored (%)", lambda r: num(r["bias_new"], 3)), ("Bias frozen (%)", lambda r: num(r["bias_frozen"], 3)), ("Difference", lambda r: num(r["diff"], 4))], rd("acdx_bridge_bench141_DATA.csv"))
HTL = {"light": "Light", "intermediate": "Intermediate", "heavy": "Heavy", "low_volume": "Low volume"}
sheet(wb, "PostHarvest_by_type", [("Harvest type", lambda r: HTL.get(r["htype"], r["htype"])), ("Version", lambda r: VN[r["arm"]]), ("Stands", lambda r: int(r["n"])),
  ("AGB t1 (Mg ha^-1)", lambda r: num(r["t1"], 1)), ("Observed AGB t2 (Mg ha^-1)", lambda r: num(r["mean_obs"], 1)), ("Predicted AGB t2 (Mg ha^-1)", lambda r: num(r["mean_pred"], 1)),
  ("Bias (%)", lambda r: num(r["bias_pct"], 2)), ("Observed change (Mg ha^-1 yr^-1)", lambda r: num(r["rec_obs"], 3)), ("Predicted change (Mg ha^-1 yr^-1)", lambda r: num(r["rec_pred"], 3)),
  ("Predicted minus observed (Mg ha^-1 yr^-1)", lambda r: num(r["gap"], 3)), ("Lower 95%", lambda r: num(r["gap_lo"], 3)), ("Upper 95%", lambda r: num(r["gap_hi"], 3)),
  ("Intercept equivalent", lambda r: r["int_equiv"]), ("Slope equivalent", lambda r: r["slope_equiv"])], rd("acdx_postharvest_by_type_DATA.csv"))
sheet(wb, "Long200_vs_curves", [("Version", lambda r: VN[r["arm"]]), ("Forest type", lambda r: r["ftg"]), ("Projection year", lambda r: int(r["yr"])), ("Stands", lambda r: int(r["n"])),
  ("Median ratio, projected / curve", lambda r: num(r["ratio_med"], 3)), ("Lower 95%", lambda r: num(r["ratio_lo"], 3)), ("Upper 95%", lambda r: num(r["ratio_hi"], 3)),
  ("Share inside curve 95% band", lambda r: num(r["in_band"], 3))], rd("acdx_long200_vs_curves_DATA.csv"))
sheet(wb, "Long200_peak_decline", [("Forest type", lambda r: r["ftg"]), ("Version", lambda r: VN[r["arm"]]), ("Stands", lambda r: int(r["n"])), ("Share declining", lambda r: num(r["share_declining"], 3)),
  ("Lower 95%", lambda r: num(r["dec_lo"], 3)), ("Upper 95%", lambda r: num(r["dec_hi"], 3)), ("Median peak year", lambda r: num(r["peak_yr_med"], 0)), ("Median peak age (yr)", lambda r: num(r["peak_age_med"], 0)),
  ("Median B(200)/max", lambda r: num(r["r200_med"], 3)), ("Curve P(peak before 250 yr)", lambda r: num(r["curve_p_peak_before_250"], 3)), ("Curve median peak age (yr)", lambda r: num(r["curve_peak_q50"], 0))], rd("acdx_long200_peak_decline_DATA.csv"))
sheet(wb, "Long200_netchange", [("Forest type", lambda r: r["ftg"]), ("Age class (yr)", lambda r: r["ageclass"]), ("Version", lambda r: VN[r["arm"]]), ("Stands", lambda r: int(r["n_stands"])),
  ("Projected (Mg ha^-1 yr^-1)", lambda r: num(r["dB_pred"], 3)), ("Projected lower 95%", lambda r: num(r["pred_lo"], 3)), ("Projected upper 95%", lambda r: num(r["pred_hi"], 3)),
  ("Observed FIA (Mg ha^-1 yr^-1)", lambda r: num(r["dB_obs"], 3)), ("Observed lower 95%", lambda r: num(r["obs_lo"], 3)), ("Observed upper 95%", lambda r: num(r["obs_hi"], 3)), ("Observed plots", lambda r: r["obs_plots"])], rd("acdx_long200_netchange_by_age_DATA.csv"))
sheet(wb, "Long200_bakuzis", [("Version", lambda r: VN[r["arm"]]), ("Forest type", lambda r: r["ftg"]), ("Relation", lambda r: r["relation"]), ("Value", lambda r: num(r["rho"], 3)),
  ("Lower 95%", lambda r: num(r["lo"], 3)), ("Upper 95%", lambda r: num(r["hi"], 3)), ("Stands", lambda r: int(float(r["n"])))], rd("acdx_long200_bakuzis_DATA.csv"), {3: 70})
sheet(wb, "Completion", [("Version", lambda r: VN[r["arm"]]), ("Stands projected 200 yr", lambda r: int(r["n"])), ("Completed", lambda r: int(r["ok"]))], rd("acdx_long200_completion_DATA.csv"))
for ws in wb.worksheets:
    ws.page_setup.orientation = "landscape"; ws.page_setup.fitToWidth = 1; ws.sheet_properties.pageSetUpPr.fitToPage = True; ws.page_setup.fitToHeight = 0
wb.save(out); print("wrote", out)
