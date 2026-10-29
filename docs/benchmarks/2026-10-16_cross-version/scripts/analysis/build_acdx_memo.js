// CRSF technical memo: FVS-ACD across versions on Maine FIA plots. Reads the acdx analysis CSVs and figures; writes docx.
// Usage: node build_acdx_memo.js <analysis_dir> <out.docx>
const fs = require("fs"), path = require("path");
const d = require("docx");
const { Document, Packer, Paragraph, TextRun, ImageRun, Table, TableRow, TableCell, WidthType, AlignmentType, BorderStyle,
        HeadingLevel, VerticalAlign, Footer, PageNumber } = d;
const R = process.argv[2], OUT = process.argv[3];
const splitCsv = l => { const o = []; let cur = "", q = false; for (const ch of l) { if (ch === '"') q = !q; else if (ch === "," && !q) { o.push(cur); cur = ""; } else cur += ch; } o.push(cur); return o; };
const csv = f => { const L = fs.readFileSync(path.join(R, f), "utf8").trim().split(/\r?\n/); const h = splitCsv(L[0]);
  return L.slice(1).map(l => { const v = splitCsv(l); const o = {}; h.forEach((k, i) => o[k] = v[i]); return o; }); };
const FT = { SF: "Spruce-fir", MBB: "Maple-beech-birch", AB: "Aspen-birch", WRPH: "White-red pine-hemlock", OAK: "Oak and oak-pine", EAC: "Elm-ash-cottonwood" };
const ORDER = ["SF", "MBB", "AB", "WRPH", "OAK", "EAC"];
const VN = { v131h: "13.1h", v141off: "14.0.4 L2", v141LT: "14.1" }, ARMS = ["v131h", "v141off", "v141LT"];
const FONT = "Calibri", SZ = 22, TS = " ", MINUS = "−";
function runs(s, base = {}) {
  const out = []; const re = /(\*\*[^*]+\*\*|\*[^*]+\*|\^\{[^}]+\}|_\{[^}]+\})/g; let last = 0, m;
  while ((m = re.exec(s))) { if (m.index > last) out.push(new TextRun({ text: s.slice(last, m.index), font: FONT, size: SZ, ...base }));
    const t = m[0];
    if (t.startsWith("**")) out.push(new TextRun({ text: t.slice(2, -2), bold: true, font: FONT, size: SZ, ...base }));
    else if (t.startsWith("*")) out.push(new TextRun({ text: t.slice(1, -1), italics: true, font: FONT, size: SZ, ...base }));
    else if (t.startsWith("^")) out.push(new TextRun({ text: t.slice(2, -1).replace(/-/g, MINUS), superScript: true, font: FONT, size: SZ, ...base }));
    else out.push(new TextRun({ text: t.slice(2, -1), subScript: true, font: FONT, size: SZ, ...base }));
    last = m.index + t.length; }
  if (last < s.length) out.push(new TextRun({ text: s.slice(last), font: FONT, size: SZ, ...base }));
  return out; }
const P = (s, o = {}) => new Paragraph({ children: runs(s), spacing: { after: 140, line: 276 }, alignment: AlignmentType.JUSTIFIED, ...o });
const H = s => new Paragraph({ children: [new TextRun({ text: s, bold: true, font: FONT, size: 26, color: "1F3864" })], spacing: { before: 220, after: 100 }, heading: HeadingLevel.HEADING_1 });
const U = "Mg" + TS + "ha^{-1}", UY = "Mg" + TS + "ha^{-1}" + TS + "yr^{-1}";
const sg = (x, k = 1) => { const v = (+x).toFixed(k); return (+v > 0 ? "+" : "") + v.replace("-", MINUS); };
const nf = (x, k = 1) => (+x).toFixed(k).replace("-", MINUS);
const pct = x => Math.round(100 * +x) + "%";
function pngDims(b) { return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) }; }
function fig(file, wIn, cap) { const buf = fs.readFileSync(path.join(R, file)); const dm = pngDims(buf); const w = wIn * 96, h = w * dm.h / dm.w;
  return [new Paragraph({ children: [new ImageRun({ data: buf, type: "png", transformation: { width: w, height: h } })], alignment: AlignmentType.CENTER, spacing: { before: 120, after: 60 }, keepNext: true }),
          new Paragraph({ children: runs(cap, { size: 20 }), spacing: { after: 200 }, alignment: AlignmentType.JUSTIFIED })]; }
const NONE = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" }, RULE = { style: BorderStyle.SINGLE, size: 8, color: "000000" };
function table(cap, header, rows, widths) {
  const W = widths.reduce((a, b) => a + b, 0);
  const cell = (s, i, o) => new TableCell({ width: { size: widths[i], type: WidthType.DXA }, verticalAlign: VerticalAlign.CENTER,
    margins: { top: 40, bottom: 40, left: 60, right: 60 }, borders: { left: NONE, right: NONE, top: o.top ? RULE : NONE, bottom: o.bottom ? RULE : NONE },
    children: [new Paragraph({ children: runs(String(s), { size: 18, bold: !!o.bold }), alignment: AlignmentType.CENTER })] });
  const tr = [new TableRow({ tableHeader: true, cantSplit: true, children: header.map((h, i) => cell(h, i, { top: true, bottom: true, bold: true })) })];
  rows.forEach((r, k) => tr.push(new TableRow({ cantSplit: true, children: r.map((v, i) => cell(v, i, { bottom: k === rows.length - 1 })) })));
  return [new Paragraph({ children: runs(cap, { size: 20 }), spacing: { before: 160, after: 80 }, keepNext: true }),
          new Table({ width: { size: W, type: WidthType.DXA }, columnWidths: widths, borders: { top: NONE, bottom: NONE, left: NONE, right: NONE, insideHorizontal: NONE, insideVertical: NONE }, rows: tr }),
          new Paragraph({ children: [], spacing: { after: 160 } })]; }

// ---- data
const S = csv("acdx_hindcast_scores_DATA.csv"), N = csv("acdx_hindcast_n_DATA.csv"), BR = csv("acdx_bridge_bench141_DATA.csv");
const PH = csv("acdx_postharvest_by_type_DATA.csv"), VC = csv("acdx_long200_vs_curves_DATA.csv"), PKD = csv("acdx_long200_peak_decline_DATA.csv");
const NC = csv("acdx_long200_netchange_by_age_DATA.csv"), BK = csv("acdx_long200_bakuzis_DATA.csv"), CP = csv("acdx_long200_completion_DATA.csv");
const s = (set, arm, m) => S.find(x => x.set === set && x.arm === arm && x.metric === m);
const bci = r => `${sg(r.bias_pct)} (${nf(r.bias_lo)} to ${nf(r.bias_hi)})${r.equiv === "TRUE" ? "" : "‡"}`;
const sets19 = [...new Set(S.filter(x => x.set !== "mefia_ph_c").map(x => x.set))];
const nStands19 = N.filter(x => x.set !== "mefia_ph_c" && x.arm === "v141LT").reduce((a, x) => a + +x.N, 0);
const med = a => { const b = [...a].sort((p, q) => p - q); const n = b.length; return n % 2 ? b[(n - 1) / 2] : (b[n / 2 - 1] + b[n / 2]) / 2; };
const medAbs = (arm, m) => med(S.filter(x => x.set !== "mefia_ph_c" && x.arm === arm && x.metric === m).map(x => Math.abs(+x.bias_pct)));
const eqN = (arm, m) => S.filter(x => x.set !== "mefia_ph_c" && x.arm === arm && x.metric === m && x.equiv === "TRUE").length;
const brEq = BR.filter(x => x.n_new === x.n_frozen), brMax = Math.max(...brEq.map(x => Math.abs(+x.diff)));
const ph = (t, a) => PH.find(x => x.htype === t && x.arm === a);
const vc = (a, f, y) => VC.find(x => x.arm === a && x.ftg === f && +x.yr === y);
const pk = (a, f) => PKD.find(x => x.arm === a && x.ftg === f);
const nc = (a, f, c) => NC.find(x => x.arm === a && x.ftg === f && x.ageclass === c);
const bk = (a, f, rel) => BK.find(x => x.arm === a && x.ftg === f && x.relation.startsWith(rel));
const L = (k) => s("mefia_l_c", "v131h", k), MF = "mefia_l_c", PHS = "mefia_ph_c";
const declRange = a => { const v = ORDER.map(f => +pk(a, f).share_declining); return [Math.min(...v), Math.max(...v)]; };
const pkAge = a => { const v = ORDER.map(f => +pk(a, f).peak_age_med); return [Math.min(...v), Math.max(...v)]; };
const old = (a, f) => nc(a, f, "[120,250)");

// ---- tables
const t1 = [
  ["13.1h", "AcadianGY 13.1 with hierarchical ingrowth and mortality posteriors", "Seven Islands long horizon configuration", "Run"],
  ["14.0.4 L2", "Linked three stage mortality (L2); 14.1 overlay sourced with both gates off", "Last release before 14.1", "Run"],
  ["14.1", "14.0.4 L2 plus large stem diameter growth (L) and thinning response (T)", "Current release; equals the 14.2 reference arm qc141 on Maine plots", "Run"],
  ["14.2 p38_fit, qc_rh", "Frozen 14.2 candidate arms (Quebec height path only)", "Engine copies on firebreather only", "Not run"]];
const t2 = [];
[["Maine FIA, unmanaged", MF], ["Maine FIA, post-harvest", PHS], ["Seven Islands CFI", "silc_l_c"]].forEach(([lab, set]) => {
  ARMS.forEach((a, i) => t2.push([i === 0 ? `${lab} (n = ${s(set, a, "BA").n})` : "", VN[a], bci(s(set, a, "BA")), bci(s(set, a, "TOTVOL")), bci(s(set, a, "BIOMASS"))])); });
const HT = [["light", "Light"], ["intermediate", "Intermediate"], ["heavy", "Heavy"], ["low_volume", "Low volume"]];
const t3 = HT.map(([k, lab]) => { const o = ph(k, "v131h");
  return [lab, o.n, nf(o.t1, 0), nf(o.rec_obs, 2)].concat(ARMS.map(a => { const r = ph(k, a); return `${sg(r.gap, 2)} (${nf(r.gap_lo, 2)} to ${nf(r.gap_hi, 2)})`; })); });
const t4 = ORDER.map(f => [FT[f], pk("v141LT", f).n, nf(pk("v141LT", f).curve_p_peak_before_250, 2),
  pct(pk("v131h", f).share_declining), pct(pk("v141LT", f).share_declining), nf(pk("v141LT", f).peak_age_med, 0),
  nf(vc("v131h", f, 100).ratio_med, 2), nf(vc("v141LT", f, 100).ratio_med, 2), pct(bk("v131h", f, "magnitude").rho)]);

// ---- text
const body = [];
body.push(new Paragraph({ children: [new TextRun({ text: "FVS-ACD across versions: ten year accuracy, recovery after harvest and 200 year behavior on Maine FIA plots", bold: true, font: FONT, size: 32, color: "1F3864" })], spacing: { after: 120 } }));
body.push(new Paragraph({ children: runs("CRSF technical memo  |  Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine  |  October 16, 2026  |  DRAFT", { size: 20, color: "595959" }), spacing: { after: 240 } }));

body.push(H("Bottom line"));
body.push(P(`FVS-ACD now carries two multi-model efforts that ask more of it than its ten year benchmark. In FCCL-II the FVS side projects about 3,000 Maine FIA plots through nine silvicultural systems for 100 years, and in the NCASI multi-model evaluation it is the FVS pathway for Maine, New Hampshire and Vermont. I compared three versions on the same plots and found that none of them reproduces both short term growth and long term behavior. Version 14.1 is the best ten year model across ${sets19.length} benchmark sets, but it overstates biomass recovery after heavy removals by about 1.4 ${UY}, double the observed rate, and like 14.0.4 it projects a plateau and decline in most stands of every forest type. Version 13.1h tracks recovery after harvest most closely, yet it never declines and drives maple-beech-birch, oak and elm-ash-cottonwood stands past the observed 99.9th percentile of biomass. For 100 year projections the version and its switches matter as much as the silviculture being compared.`));

body.push(H("Versions, data and scoring"));
body.push(P(`Table 1 lists the versions. On Maine plots 14.1 equals the 14.2 reference arm qc141, because the Quebec height anchor that defines 14.2 acts only on Quebec stands. The frozen 14.2 candidate arms p38_fit and qc_rh change only the Quebec height path, so they should also equal qc141 on Maine plots, but their engine copies live on firebreather, which has been unreachable since October 11, and they were not run. Every projection used the frozen benchmark runner on OSC Cardinal with arm settings copied verbatim from the 14.1 benchmark and the Seven Islands 13.1h runs.`));
body.push(...table("**Table 1.** FVS-ACD versions compared.", ["Label", "Engine and settings", "Role", "Status"], t1, [1500, 3700, 2900, 1000]));
body.push(P(`The ten year hindcast covers the ${sets19.length} frozen benchmark sets (${nStands19.toLocaleString("en-US")} paired stands), with emphasis on the 918 unmanaged Maine FIA stands (intervals of 4 to 25 years) and the 120 stand Seven Islands CFI frame. I added a post-harvest Maine FIA set of 827 stands on 781 plots where a harvest was recorded at the previous visit, classified with the FCCL common practice rules into light (less than 35% of merchantable volume removed), heavy (more than 65%), intermediate and low volume (less than 1,200 ft^{3} ac^{-1} before harvest) types. Biomass is NSVB aboveground dry biomass of trees at least 5 cm dbh. For each version and set I report bias as 100 (mean predicted / mean observed ${MINUS} 1) with a 95% stand bootstrap interval (1,000 resamples) and a bootstrap equivalence test of observed on predicted, with the intercept region at ±25% of the observed mean and the slope region at 1 ± 0.25, both fixed before any new output was read. Rescoring the frozen 14.x runs reproduces the published per set biases to within ${brMax.toFixed(4)} percentage points wherever the stand sets match.`));

body.push(H("Ten year accuracy"));
body.push(P(`On unmanaged Maine FIA plots all three versions underpredict growth (Table 2, Figure 1). Biomass bias runs from ${nf(s(MF, "v131h", "BIOMASS").bias_pct)}% for 13.1h to ${nf(s(MF, "v141off", "BIOMASS").bias_pct)}% for 14.0.4, while top height is nearly unbiased (${sg(s(MF, "v141LT", "TOPHT").bias_pct)} to ${sg(s(MF, "v131h", "TOPHT").bias_pct)}%) and quadratic mean diameter is low by ${nf(-s(MF, "v131h", "QMD").bias_pct)} to ${nf(-s(MF, "v141off", "QMD").bias_pct)}%, which places the shortfall in diameter growth and survival of larger stems rather than height. All three pass the equivalence test there because the region is wide. Across the ${sets19.length} sets, 14.1 has the smallest median absolute bias for total volume (${medAbs("v141LT", "TOTVOL").toFixed(1)}%) and biomass (${medAbs("v141LT", "BIOMASS").toFixed(1)}%) against ${medAbs("v131h", "TOTVOL").toFixed(1)}% and ${medAbs("v131h", "BIOMASS").toFixed(1)}% for 13.1h, and it passes equivalence on biomass in ${eqN("v141LT", "BIOMASS")} sets against ${eqN("v131h", "BIOMASS")} for 13.1h. On the Seven Islands frame the intervals are wide and no version passes, as the slope of observed on predicted biomass is only ${nf(Math.min(...ARMS.map(a => +s("silc_l_c", a, "BIOMASS").slope)), 2)} to ${nf(Math.max(...ARMS.map(a => +s("silc_l_c", a, "BIOMASS").slope)), 2)} (Figure 2).`));
body.push(...table("**Table 2.** Ten year hindcast bias (%) with 95% stand bootstrap interval for basal area (BA), total volume (VOL) and aboveground biomass (AGB). ‡ fails the bootstrap equivalence test of observed on predicted.",
  ["Set", "Version", "BA", "VOL", "AGB"], t2, [2700, 1100, 1800, 1800, 1800]));
body.push(...fig("fig/acdx_fig1_hindcast_bias.png", 6.3, "**Figure 1.** Ten year hindcast bias by version for three Maine sets, with 95% stand bootstrap intervals."));
body.push(...fig("fig/acdx_fig2_equivalence_agb.png", 6.3, "**Figure 2.** Bootstrap equivalence test for aboveground biomass. The grey box is the region of equivalence (intercept ±25% of the observed mean, slope 1 ± 0.25); bars are 90% bootstrap intervals."));

body.push(H("Recovery after harvest"));
const hv = k => ph("heavy", k), lt = k => ph("light", k);
body.push(P(`The post-harvest set separates the versions most clearly (Table 3, Figure 3). After heavy removals the observed stands gained ${nf(hv("v131h").rec_obs, 2)} ${UY} over about five years, and 14.1 predicted ${nf(hv("v141LT").rec_pred, 2)}, an overstatement of ${nf(hv("v141LT").gap, 2)} (${nf(hv("v141LT").gap_lo, 2)} to ${nf(hv("v141LT").gap_hi, 2)}). It overstates intermediate removals by the same margin. Version 14.0.4 L2, which differs from 14.1 by the L and T terms, comes closest after heavy removals (${sg(hv("v141off").gap, 2)}) but understates recovery after light removals by ${nf(-lt("v141off").gap, 2)}. Version 13.1h has the smallest overall biomass bias on this set (${sg(s(PHS, "v131h", "BIOMASS").bias_pct)}%) and fits low volume stands well, but it also understates recovery after light removals (${sg(lt("v131h").gap, 2)}) and overstates it after heavy removals (${sg(hv("v131h").gap, 2)}). The pattern implicates the 14.1 thinning response, which was fitted to commercial thinning and appears to treat an overstory removal as a thinning, so a residual stand of saplings and poles receives a release meant for a thinned pole or sawtimber stand.`));
body.push(...table("**Table 3.** Biomass recovery on the 827 post-harvest Maine FIA stands by FCCL harvest type. AGB t1 is the mean biomass at the first post-harvest visit (" + U + "); observed is the mean annual AGB change (" + UY + "); version columns give predicted minus observed annual change with 95% stand bootstrap intervals.",
  ["Harvest type", "Stands", "AGB t1", "Observed", "13.1h", "14.0.4 L2", "14.1"], t3, [1400, 800, 900, 1000, 1700, 1700, 1700]));
body.push(...fig("fig/acdx_fig3_postharvest_recovery.png", 5.6, "**Figure 3.** Predicted minus observed annual biomass change after harvest by FCCL harvest type, with 95% stand bootstrap intervals."));

body.push(H("Behavior over 200 years"));
const [d14lo, d14hi] = declRange("v141LT"), [p14lo, p14hi] = pkAge("v141LT");
body.push(P(`Growing the 918 unmanaged stands for 200 years without harvest shows two opposite failures (Table 4, Figures 4 and 5). Version 13.1h does not decline in any forest type. Its stands still gain ${nf(Math.min(...ORDER.map(f => +old("v131h", f).dB_pred)))} to ${nf(Math.max(...ORDER.map(f => +old("v131h", f).dB_pred)))} ${UY} on average beyond age 120, depending on forest type, and its maximum biomass exceeds the observed 99.9th percentile in ${pct(bk("v131h", "MBB", "magnitude").rho)} of maple-beech-birch, ${pct(bk("v131h", "OAK", "magnitude").rho)} of oak and ${pct(bk("v131h", "EAC", "magnitude").rho)} of elm-ash-cottonwood stands. In spruce-fir, the one type where the FIA curves show a peak (near ${nf(pk("v141LT", "SF").curve_peak_q50, 0)} years, bootstrap probability ${nf(pk("v141LT", "SF").curve_p_peak_before_250, 2)}), 13.1h ends at ${nf(vc("v131h", "SF", 200).ratio_med, 1)} times the curve. The 14.x versions instead plateau and decline in ${pct(d14lo)} to ${pct(d14hi)} of stands in every type, with median peaks at ages ${p14lo} to ${p14hi} under 14.1, so they reproduce the spruce-fir decline but impose one on hardwood and pine types where the FIA record shows none. By 200 years 14.1 sits at ${nf(vc("v141LT", "MBB", 200).ratio_med, 2)} of the maple-beech-birch curve and ${nf(vc("v141LT", "WRPH", 200).ratio_med, 2)} of the white-red pine-hemlock curve.`));
body.push(P(`Net change by age class gives the same reading from the observed side (Figure 5). Every version projects less net gain than FIA observes in nearly every age class, consistent with the hindcast. For stands older than 120 years the FIA record shows positive net change of ${nf(old("v141LT", "SF").dB_obs, 2)} ${UY} in spruce-fir and ${nf(old("v141LT", "MBB").dB_obs, 2)} in maple-beech-birch, against ${nf(old("v141LT", "SF").dB_pred, 2)} and ${nf(old("v141LT", "MBB").dB_pred, 2)} for 14.1. The projections carry no disturbance, so projected gain should exceed the observed mean rather than fall below it. The empirical Bakuzis checks are mixed. No version pushes any stand past the observed 99.9th percentile of SDI, the Eichhorn ratio of volume to top height slopes between high and low site terciles is ${nf(bk("v131h", "ALL", "Eichhorn").rho, 2)} to ${nf(bk("v141LT", "ALL", "Eichhorn").rho, 2)}, and initial density has no relation to biomass at 100 years under 14.x (Spearman ${nf(bk("v141LT", "ALL", "yield").rho, 2)}) but a negative one under 13.1h (${nf(bk("v131h", "ALL", "yield").rho, 2)}). Site ordering is weak in every version and inverted for 13.1h in spruce-fir (Spearman ${nf(bk("v131h", "SF", "site").rho, 2)}, 95% interval ${nf(bk("v131h", "SF", "site").lo, 2)} to ${nf(bk("v131h", "SF", "site").hi, 2)}).`));
body.push(...table("**Table 4.** Long term behavior of the 918 unmanaged Maine FIA stands projected 200 years without harvest. P(peak) is the curve bootstrap probability of a peak before 250 years. Declining is the share of stands whose biomass at year 200 is below 95% of its maximum. Ratio is the median of projected biomass over the curve at the same age, 100 years into the projection. Over 99.9th is the share of 13.1h stands whose maximum exceeds the observed 99.9th percentile.",
  ["Forest type", "Stands", "Curve P(peak)", "Declining, 13.1h", "Declining, 14.1", "Peak age, 14.1", "Ratio, 13.1h", "Ratio, 14.1", "Over 99.9th, 13.1h"], t4, [1600, 700, 900, 1000, 1000, 900, 900, 900, 1100]));
body.push(...fig("fig/acdx_fig4_long200_vs_curves.png", 6.3, `**Figure 4.** Median biomass of unmanaged Maine FIA stands projected 200 years without harvest, by version and forest type, against the published Maine FIA biomass curve and its 95% band (Weiskittel 2026, 10.5281/zenodo.23406410). Engine biomass was scaled to the FIADB basis by the median ratio at the first visit.`));
body.push(...fig("fig/acdx_fig5_netchange_by_age.png", 6.3, "**Figure 5.** Projected and observed annual net biomass change by age class for the four larger forest types, with 95% bootstrap intervals."));

body.push(H("Implications for FCCL and NCASI"));
body.push(P(`FCCL ranks silvicultural systems against grow only and common practice, and its common practice includes heavy removals of 65% or more. Under 14.1 the thinning response credits heavy removals with roughly twice the observed regrowth, and the version wide decline caps grow only and continuous cover hardwood stands at about 120 to 140 years, so both biases favor heavier cutting in an optimization that maximizes carbon. Under 13.1h the bias runs the other way, with grow only stands accumulating without limit. I recommend that the FCCL modelers confirm which AcadianGY version and switches their FVS-ACD build uses, run heavy removals and overstory removal with the thinning response off (14.0.4 L2 settings), and treat any FVS trajectory beyond about age 120 as an assumption bounded by the FIA curves rather than an estimate. The same caution applies to NCASI, where 14.1 is the right choice for the ten year comparison and the FIA curves are the better long horizon reference for the Maine pathway.`));
body.push(P(`For 14.3 the evidence points to three changes. The thinning response should be limited to partial removals, for example by residual relative density or removal fraction, and the post-harvest set is now a ready benchmark for that. The senescence that produces the decline in 14.x should be conditioned on forest type, since only spruce-fir declines in the FIA record. The diameter growth shortfall on unmanaged FIA stands, about 10% in quadratic mean diameter, is common to all versions and is the largest single source of ten year bias in Maine.`));

body.push(H("Limits"));
body.push(P(`Stand age comes from FIA STDAGE and is ambiguous in multi-cohort stands, which affects the age alignment with the curves but not the hindcast. Engine biomass excludes stems under 5 cm and differs from FIADB by a factor of about 1.07, which I applied before comparing with the curves. Volume is scored under the published convention, which matches measured height scoring on FIA plots but not on Seven Islands, and the Seven Islands figures here use the 120 stand frame rather than the 65 routine plots in the Seven Islands report. The post-harvest set keeps 128 stands with natural disturbance recorded at the second visit. The 14.2 arms remain to be run once firebreather returns.`));
body.push(P(`**Data and code.** Analysis tables, figures and scripts are in the CRSF workspace (outputs/2026-10/fvs-acd-crossversion) and on Cardinal under acdx_20261016. They will be added to the FVS-ACD repository and the next FVS-ACD Zenodo version.`));

const doc = new Document({ styles: { default: { document: { run: { font: FONT, size: SZ } } } },
  sections: [{ properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1300, bottom: 1300, left: 1300, right: 1300 } } },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 18 })] })] }) },
    children: body }] });
Packer.toBuffer(doc).then(b => { fs.writeFileSync(OUT, b); console.log("wrote", OUT); });
