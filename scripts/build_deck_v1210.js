// FVS-ACD vs OSM Hennigar Aug 2026 deck, v12.10.1 (robust management-modifier re-fit). pptxgenjs from scratch. CRSF forest palette.
const pptxgen = require("pptxgenjs");
const p = new pptxgen();
p.defineLayout({ name: "W", width: 13.33, height: 7.5 });
p.layout = "W";

const FIG = process.argv[2] || ".";
const OUT = process.argv[3] || "FVS-ACD_Hennigar_Aug2026.pptx";

const GREEN = "1A3D28", MOSS = "5E8C61", MOSS2 = "97BC62", GOLD = "C5A55A";
const OSMc = "C5773A", INK = "22302A", GREY = "5A6B60", CREAM = "F4F6F2", WHITE = "FFFFFF";
const HSERIF = "Cambria", BODY = "Calibri";

function titleBar(s, t, kicker) {
  if (kicker) s.addText(kicker.toUpperCase(), { x:0.6, y:0.42, w:12.1, h:0.3, fontFace:BODY, fontSize:12, color:MOSS, bold:true, charSpacing:2 });
  s.addText(t, { x:0.6, y:0.66, w:12.1, h:0.85, fontFace:HSERIF, fontSize:30, color:GREEN, bold:true });
}
function fig(s, f, opts) { s.addImage(Object.assign({ path:`${FIG}/${f}` }, opts)); }
function caption(s, t, y) { s.addText(t, { x:0.6, y:y||6.75, w:12.1, h:0.55, fontFace:BODY, fontSize:11.5, italic:true, color:GREY }); }

// ---------- 1 TITLE ----------
let s = p.addSlide(); s.background = { color: GREEN };
s.addText("FVS-ACD vs OSM", { x:0.8, y:1.9, w:11.7, h:1.0, fontFace:HSERIF, fontSize:52, color:WHITE, bold:true });
s.addText("An independent re-derivation, and a Chapter-11 lever to close the operational gap",
  { x:0.8, y:3.0, w:11.4, h:0.8, fontFace:BODY, fontSize:22, color:MOSS2 });
s.addText([
  { text:"Acadian Growth & Yield Meeting  |  18 August 2026\n", options:{ fontSize:16, color:"D8E3D6" } },
  { text:"Aaron Weiskittel  |  Center for Research on Sustainable Forests, University of Maine", options:{ fontSize:14, color:"AFC4AB" } }
], { x:0.8, y:4.6, w:11.4, h:1.0, fontFace:BODY });
s.addText("Honest read: on the operational domain OSM and FVS-ACD are close and OSM is strong. FVS-ACD's edge is biological realism, long horizon, QMD, and transparency.",
  { x:0.8, y:6.2, w:11.7, h:0.8, fontFace:BODY, fontSize:13, italic:true, color:"AFC4AB" });

// ---------- 2 WHY REVISIT ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Why revisit the 2018 benchmark", "Context");
s.addText([
  { text:"2018 (Hennigar & Weiskittel, ECANUSA). ", options:{ bold:true } },
  { text:"OSM trailed only slightly behind FVS-ACD, and beat it on merchantable volume-increment bias and RMSE in ME, NB, and NS. That result set the FVS-ACD to-do list.\n\n" },
  { text:"2026. ", options:{ bold:true } },
  { text:"Independent re-derivation on fresh data with a common FIA NSVB currency. If OSM's 2018 edge does not replicate, say so with evidence. It largely does not." }
], { x:0.6, y:1.7, w:6.0, h:3.4, fontFace:BODY, fontSize:15, color:INK, lineSpacingMultiple:1.1, valign:"top" });
const topics = [["Site productivity","ESI holds; height edge is extrapolation"],
  ["Data harmonization","MagPlot + FIA on one NSVB currency"],
  ["New calibration approaches","Multi-dimensional scorecard; Ch 11 modifiers"],
  ["Integrating climate","Current and 2030 ESI as a scenario"],
  ["AI and productivity","Accelerated the work, caught our own error"]];
let yy = 1.7;
topics.forEach((t,i)=>{
  s.addShape(p.ShapeType.ellipse, { x:6.95, y:yy+0.02, w:0.42, h:0.42, fill:{color:GREEN} });
  s.addText(String(i+1), { x:6.95, y:yy+0.02, w:0.42, h:0.42, align:"center", valign:"middle", color:WHITE, bold:true, fontSize:15, fontFace:BODY });
  s.addText([{text:t[0]+"  ", options:{bold:true, color:GREEN, fontSize:15}}, {text:t[1], options:{color:GREY, fontSize:12.5}}],
    { x:7.5, y:yy, w:5.2, h:0.5, fontFace:BODY, valign:"middle" });
  yy += 0.72;
});
s.addText("His five agenda topics, and what we bring to each", { x:6.95, y:yy+0.05, w:5.7, h:0.4, fontFace:BODY, fontSize:12, italic:true, color:GREY });

// ---------- 3 DATA ----------
s = p.addSlide(); s.background = { color: CREAM };
titleBar(s, "Data harmonized onto one currency", "Data harmonization");
const stats = [["705","ESI-covered in-domain stands for the\nmanaged breakdown (733 pooled scorecard)"],
  ["NSVB","FIA volume and biomass as the\ncommon currency for every model"],
  ["ESI v8","30 m climate-and-terrain site\ndriver, cross-border coverage"],
  ["5","models scored head to head\nv12.5.0, v12.7.0, v12.9.x, v12.10.1, OSM"]];
stats.forEach((c,i)=>{
  const x = 0.6 + i*3.05;
  s.addShape(p.ShapeType.roundRect, { x, y:1.9, w:2.8, h:2.7, fill:{color:WHITE}, line:{color:"E0E6DD",width:1}, rectRadius:0.08, shadow:{type:"outer",blur:6,offset:2,color:"D5DDD3",opacity:0.5} });
  s.addText(c[0], { x, y:2.15, w:2.8, h:1.1, align:"center", fontFace:HSERIF, fontSize:44, bold:true, color:GREEN });
  s.addText(c[1], { x:x+0.15, y:3.35, w:2.5, h:1.1, align:"center", fontFace:BODY, fontSize:12.5, color:INK });
});
s.addText("Also: recent post-2010 Maine FIA (independent in time from the 1999 to 2005 training FIA), and SILC Seven Islands for the long horizon. Coordinates stay on Cardinal; aggregates only.",
  { x:0.6, y:5.0, w:12.1, h:0.8, fontFace:BODY, fontSize:13.5, color:INK });

// ---------- 4 SCORECARD ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Five-way accuracy scorecard", "New calibration approaches");
fig(s, "F1_scorecard_heatmap.png", { x:0.5, y:1.6, w:8.1, h:5.5 });
s.addText([
  { text:"Corrected merge. ", options:{bold:true,color:GREEN} },
  { text:"An index-join artifact had made OSM look imprecise. With a single keyed merge OSM's modeling efficiency is positive (0.70 to 0.75) and it is the most accurate model on the pooled domain.\n\n" },
  { text:"OSM and v12.9.x are close. ", options:{bold:true,color:GREEN} },
  { text:"v12.7.0 and v12.9.x roughly halve the incumbent v12.5.0 over-prediction.\n\n" },
  { text:"QMD is a durable FVS advantage ", options:{bold:true,color:GREEN} },
  { text:"(about +1 to +2 percent vs OSM +11)." }
], { x:8.9, y:1.75, w:3.9, h:5.0, fontFace:BODY, fontSize:13, color:INK, valign:"top", lineSpacingMultiple:1.05 });

// ---------- 5 FOREST TYPE ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Accuracy by forest type", "New calibration approaches");
fig(s, "F6_forest_type.png", { x:0.7, y:1.7, w:11.9, h:5.0 });
caption(s, "Softwood is equivalent for every model. Hardwood is the shared frontier: all models over-predict, even OSM (+15). v12.9.x roughly halves the v12.5.0 hardwood bias.");

// ---------- 6 BAKUZIS ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Biological realism: Bakuzis relations", "New calibration approaches");
fig(s, "F5_bakuzis_matrix.png", { x:1.3, y:1.7, w:8.4, h:5.0 });
s.addText([
  { text:"The self-thinning FVS-ACD versions pass all five relations.\n\n", options:{bold:true,color:GREEN,fontSize:14} },
  { text:"v12.5.0 never self-thins (basal area runs to 65 with thousands of stems alive), failing yield-density, Reineke, and Sukachev.\n\n", options:{fontSize:13} },
  { text:"OSM flags the plateau and Reineke: it does not self-thin on the long horizon.", options:{fontSize:13} }
], { x:9.9, y:1.9, w:2.9, h:4.6, fontFace:BODY, color:INK, valign:"top", lineSpacingMultiple:1.05 });

// ---------- 7 LONG HORIZON ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Long horizon: FVS-ACD self-thins, OSM does not", "New calibration approaches");
fig(s, "F4_longhorizon.png", { x:0.9, y:1.7, w:11.5, h:5.0 });
caption(s, "The operational short-interval domain agreement hides a long-horizon divergence driven by self-thinning. This is why FVS-ACD is the choice for carbon, old-growth, and climate work.");

// ---------- 8 SITE PRODUCTIVITY ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Site productivity: keep ESI", "Site productivity");
fig(s, "hennigar_site_productivity.png", { x:0.6, y:1.7, w:7.7, h:5.0 });
s.addText([
  { text:"Bake-off settled. ", options:{bold:true,color:GREEN} },
  { text:"ESI vs BGI vs CPSI vs legacy CSI, out of sample with spatially blocked CV. ESI wins the dominant-height anchor and ties for diameter growth. BGI and CPSI carry no height signal and lack cross-border coverage.\n\n" },
  { text:"The height over-prediction is edge extrapolation, ", options:{bold:true,color:GREEN} },
  { text:"not a metric fault: no alternative metric fixes it. The fix is domain restriction plus an increment-consistent anchor recalibration (v13 Pillar 2)." }
], { x:8.5, y:1.8, w:4.3, h:5.0, fontFace:BODY, fontSize:13.5, color:INK, valign:"top", lineSpacingMultiple:1.1 });

// ---------- 9 COMPONENT COMPARISON (SOURCE VERIFIED) ----------
s = p.addSlide(); s.background = { color: CREAM };
titleBar(s, "Component comparison, source-verified", "New calibration approaches");
const rows = [
  ["Component","FVS-ACD v12","OSM v2.26.1"],
  ["Diameter growth","Parametric Kuehne 2022","Random Forest table"],
  ["Management term","None (verified)","IsManaged column (verified)"],
  ["Site in DG","Continuous ESI","Binary IsGoodSite"],
  ["Height calibration","None in base","Local-observation routine"],
  ["Self-thinning","Composition-aware SDImax","No long-horizon plateau"]];
const trows = rows.map((r,ri)=> r.map(c=>({ text:c, options:{
  bold: ri===0, color: ri===0?WHITE:INK, fill:{color: ri===0?GREEN:(ri%2?WHITE:"EDF1EA")},
  fontSize: ri===0?13:12.5, align: ci=>0, valign:"middle", fontFace:BODY } })));
s.addTable(trows, { x:0.6, y:1.8, w:7.4, colW:[2.0,2.7,2.7], rowH:0.62, border:{type:"solid",color:"DDE3DA",pt:1} });
s.addShape(p.ShapeType.roundRect, { x:8.3, y:1.8, w:4.5, h:4.3, fill:{color:GREEN}, rectRadius:0.08 });
s.addText([
  { text:"The verified difference\n", options:{bold:true, fontSize:17, color:MOSS2} },
  { text:"OSM's diameter-growth table literally carries an ", options:{fontSize:14, color:WHITE} },
  { text:"IsManaged", options:{fontSize:14, color:GOLD, bold:true} },
  { text:" column. FVS-ACD v12 has no management term anywhere.\n\nThat is the specific, source-level reason OSM is competitive on the heavily managed benchmark, and exactly what v12.10.1 targets.", options:{fontSize:14, color:WHITE} }
], { x:8.6, y:2.05, w:3.9, h:3.9, fontFace:BODY, valign:"top", lineSpacingMultiple:1.1 });
caption(s, "OSM ships as a compiled binary; the exposed diameter-growth RF table verifies the management covariate. Mortality and ingrowth management terms are documented, not source-exposed.");

// ---------- 10 MANAGEMENT MODIFIERS CENTERPIECE ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "The Chapter-11 lever: management modifiers", "New calibration approaches");
fig(s, "F2_mgmt_centerpiece.png", { x:0.5, y:1.65, w:8.3, h:5.2 });
s.addText([
  { text:"Direct effect only (Ch 11).\n", options:{bold:true, color:GREEN, fontSize:15} },
  { text:"The base equations already carry the indirect structural effect. The modifier isolates the direct effect by the multi-step method (Wang 1990).\n\n", options:{fontSize:12.5} },
  { text:"Planted = Type 2, sustained.\nPCT = Type 1, transient, decaying.\n\n", options:{bold:true, color:GREEN, fontSize:13.5} },
  { text:"Result: robust re-fit. The direct effect is a fitted additive release (planted +3.8, PCT +2.4 m2/ha BA), not a clamped ratio, so its fold coefficients move with the data. v12.10.1 clearly beats OSM on planted and edges OSM on managed out of sample. The effect is larger than the old 1.6 clamp allowed, which is why the capped version still under-predicted planted.", options:{fontSize:12.5} }
], { x:9.0, y:1.8, w:3.8, h:5.0, fontFace:BODY, color:INK, valign:"top", lineSpacingMultiple:1.05 });

// ---------- 11 MODIFIER FORM + GAP ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "Modifier form and gap closure", "New calibration approaches");
fig(s, "F3_mgmt_concept_gap.png", { x:0.7, y:1.75, w:11.9, h:4.7 });
caption(s, "Robust additive direct-effect release (planted +3.8, PCT +2.4 m2/ha BA), clamp removed; engine carries a sustained (planted) or decaying (PCT) diameter-growth effect bounded by self-thinning. In-sample managed mean absolute bias across nine metrics: v12.9.x 10.2 to v12.10.1 1.3 (OSM 8.3). Cross-validated on the next slide. Gated, default off, so unmanaged stands are untouched.");

// ---------- 11b CROSS-VALIDATION (red-team robustness) ----------
s = p.addSlide(); s.background = { color: CREAM };
titleBar(s, "Does the lever hold out of sample?", "New calibration approaches");
const cvhead = ["Test","Planted","PCT","Managed","OSM (managed)"];
const cvrows = [
  ["In sample (robust)","4.0","3.0","1.3","8.3"],
  ["Leave-one-installation-out","3.8","3.1","1.4","8.3"],
  ["Managed split-half (200x)","--","--","5.6","8.1"],
  ["Leave-one-province-out","5.6","4.1","1.5","8.3"]];
const cvtab = [cvhead.map(c=>({text:c,options:{bold:true,color:WHITE,fill:{color:GREEN},fontSize:13,align:"center",valign:"middle",fontFace:BODY}}))]
  .concat(cvrows.map((r,ri)=> r.map((c,ci)=>({text:c,options:{bold:ci===0,color:INK,fill:{color:ri%2?WHITE:"EDF1EA"},fontSize:12.5,align:ci===0?"left":"center",valign:"middle",fontFace:BODY}}))));
s.addTable(cvtab, { x:0.6, y:1.75, w:7.6, colW:[3.0,1.15,1.15,1.15,1.15], rowH:0.6, border:{type:"solid",color:"DDE3DA",pt:1} });
s.addText("Mean absolute level bias across nine metrics, lower is better", { x:0.6, y:1.5, w:7.6, h:0.25, fontFace:BODY, fontSize:11, italic:true, color:GREY });
s.addShape(p.ShapeType.roundRect, { x:8.5, y:1.75, w:4.3, h:4.6, fill:{color:WHITE}, line:{color:"E0E6DD",width:1}, rectRadius:0.08 });
s.addText([
  { text:"What survives the red team\n", options:{bold:true, fontSize:16, color:GREEN} },
  { text:"Planted is a robust win over OSM in every scheme, and it transfers across the NB to QC border.\n\n", options:{fontSize:13, color:INK} },
  { text:"Managed edges OSM out of sample (1.4 LOIO, 1.5 LOPO, 5.6 split-half vs 8.3).\n\n", options:{fontSize:13, color:INK} },
  { text:"PCT now transfers across the province block too (4.1 vs OSM 3.7, was 7.3 under the clamp), and the PCT basal-area residual closes. Quebec edge still reported as out of domain, conservatively.", options:{fontSize:13, color:OSMc} }
], { x:8.8, y:2.0, w:3.7, h:4.2, fontFace:BODY, valign:"top", lineSpacingMultiple:1.06 });
caption(s, "The robust additive re-fit removed the 1.6 clamp; fold coefficients now move with the data (planted BA release 3.6 to 4.1 across folds) and the out-of-sample numbers hold. In-sample class bias is near zero by construction, so the cross-validated numbers are the evidence.");

// ---------- 12 CLIMATE ----------
s = p.addSlide(); s.background = { color: CREAM };
titleBar(s, "Integrating climate", "Integrating climate");
s.addText([
  { text:"A validated base and a separate scenario driver.\n\n", options:{bold:true, color:GREEN, fontSize:16} },
  { text:"ESI v8 gives current and 2030 climate site surfaces. The projected surface is a forward scenario driver, kept separate from the validated base and never benchmarked on.\n\n", options:{fontSize:15} },
  { text:"For a credible forecast the future step uses a parametric climate-sensitive form (a GAM ratio on the dominant-height anchor), not a random-forest extrapolation. RCP4.5 gives a defensible cold-limited signal of +1.9 m (2030s) to +4.3 m (2090s).", options:{fontSize:15} }
], { x:0.6, y:1.75, w:7.7, h:4.6, fontFace:BODY, color:INK, valign:"top", lineSpacingMultiple:1.12 });
s.addShape(p.ShapeType.roundRect, { x:8.7, y:1.9, w:4.1, h:3.9, fill:{color:WHITE}, line:{color:"E0E6DD",width:1}, rectRadius:0.08 });
s.addText([{text:"Rule\n", options:{bold:true, fontSize:16, color:GREEN}},
  {text:"Validate on observed climate.\nProject with a parametric form.\nNever benchmark on the projected surface.", options:{fontSize:14.5, color:INK}}],
  { x:9.0, y:2.15, w:3.6, h:3.3, fontFace:BODY, valign:"top", lineSpacingMultiple:1.2 });

// ---------- 13 AI WORKFLOW ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "AI-assisted workflow", "AI and productivity");
const ai = [["Accelerated","Weeks of benchmarking, scorecards, and figures compressed into days of iteration."],
  ["Kept honest","A human check caught an index-join merge bug that had wrongly made OSM look imprecise; corrected to positive NSE."],
  ["Reproducible","Every number traces to a script and a keyed data file on Cardinal; coordinates never leave the cluster."]];
let ay=1.9;
ai.forEach(c=>{
  s.addShape(p.ShapeType.roundRect, { x:0.6, y:ay, w:12.1, h:1.45, fill:{color:CREAM}, rectRadius:0.06 });
  s.addText(c[0], { x:0.9, y:ay+0.15, w:3.0, h:1.15, fontFace:HSERIF, fontSize:20, bold:true, color:GREEN, valign:"middle" });
  s.addText(c[1], { x:4.0, y:ay+0.15, w:8.4, h:1.15, fontFace:BODY, fontSize:14.5, color:INK, valign:"middle" });
  ay += 1.65;
});

// ---------- 13b V13 FORWARD ----------
s = p.addSlide(); s.background = { color: WHITE };
titleBar(s, "v13 forward: what the data lets us commit to now", "Roadmap");
const v13 = [
  ["Height domain bounded",
   "The domain mask is a go: gate off predictions outside the calibrated ESI range so the anchor never extrapolates. The increment-consistent anchor refit is parked until mature Acadian data arrive, because on US only data the ESI to asymptote mapping is unidentified. Bound the domain now, refit the anchor once the older stands exist."],
  ["Hierarchical management transfers",
   "A Bayesian hierarchical mortality and management fit, with a region random slope on management. The region standard deviation is 1.21 on the log-hazard scale, far larger than the mean management effect, so a single capped constant is the wrong object. Leave one region out transfer beats the capped constant in 5 of 5 held out regions."],
  ["Provincial-data ask",
   "New Brunswick and Nova Scotia PSP treatment histories, the provincial site surfaces, and managed remeasurements. August is the moment to request a harmonized data sharing arrangement, so the managed calibration is fit on the full Acadian record rather than the thin planted and PCT samples we have now."]];
let v13y = 1.75;
v13.forEach((c,i)=>{
  s.addShape(p.ShapeType.roundRect, { x:0.6, y:v13y, w:12.1, h:1.5, fill:{color:CREAM}, line:{color:"E0E6DD",width:1}, rectRadius:0.06 });
  s.addShape(p.ShapeType.ellipse, { x:0.85, y:v13y+0.55, w:0.42, h:0.42, fill:{color:GOLD} });
  s.addText(String(i+1), { x:0.85, y:v13y+0.55, w:0.42, h:0.42, align:"center", valign:"middle", color:GREEN, bold:true, fontSize:16, fontFace:BODY });
  s.addText(c[0], { x:1.5, y:v13y+0.12, w:3.2, h:1.25, fontFace:HSERIF, fontSize:17, bold:true, color:GREEN, valign:"middle" });
  s.addText(c[1], { x:4.85, y:v13y+0.12, w:7.65, h:1.25, fontFace:BODY, fontSize:12.5, color:INK, valign:"middle", lineSpacingMultiple:1.02 });
  v13y += 1.62;
});

// ---------- 14 VERDICT ----------
s = p.addSlide(); s.background = { color: GREEN };
s.addText("VERDICT & ROADMAP", { x:0.7, y:0.72, w:12, h:0.4, fontFace:BODY, fontSize:13, color:MOSS2, bold:true, charSpacing:2 });
s.addText("Close on the operational domain, ahead on realism and transparency", { x:0.7, y:1.12, w:12, h:0.9, fontFace:HSERIF, fontSize:28, color:WHITE, bold:true });
const vr = [
  "On the operational inventory domain OSM and FVS-ACD v12.9.x are close, and OSM is strong. The 2018 conclusion does not replicate on independent in-domain data scored with a common NSVB system.",
  "FVS-ACD advantages: biological realism and long-horizon plateau, QMD, a validated climate-ready ESI driver, and full transparency in R.",
  "v12.10.1 (near-term lever): the Chapter-11 direct-effect management modifiers, re-fit as a robust additive release, close the managed-stand gap to OSM out of sample and clearly beat OSM on planted stands. PCT now transfers across the province block. Gated, default off; unmanaged stands untouched.",
  "v13 (structural): keep ESI; domain restriction plus increment-consistent anchor recalibration; a Bayesian hierarchical mortality and ingrowth refit with the management effect embedded; uncertainty carried through."];
let vy=2.2;
vr.forEach((t,i)=>{
  s.addShape(p.ShapeType.ellipse, { x:0.7, y:vy+0.05, w:0.32, h:0.32, fill:{color:GOLD} });
  s.addText(t, { x:1.25, y:vy-0.05, w:11.4, h:1.0, fontFace:BODY, fontSize:14.5, color:"E7EEE4", valign:"top", lineSpacingMultiple:1.03 });
  vy += 1.15;
});

// ---------- 16 QUESTIONS / CLOSE ----------
s = p.addSlide(); s.background = { color: GREEN };
s.addText("Questions / Comments", { x:0.8, y:2.5, w:11.7, h:1.0, fontFace:HSERIF, fontSize:46, color:WHITE, bold:true });
s.addText("Aaron Weiskittel  |  aaron.weiskittel@maine.edu  |  Center for Research on Sustainable Forests, University of Maine",
  { x:0.8, y:3.7, w:11.7, h:0.5, fontFace:BODY, fontSize:15, color:MOSS2 });
s.addText("All results reproducible and openly archived; plot coordinates stay on the analysis cluster, aggregates only.",
  { x:0.8, y:4.35, w:11.7, h:0.5, fontFace:BODY, fontSize:13, italic:true, color:"AFC4AB" });

p.writeFile({ fileName: OUT }).then(f=>console.log("WROTE", f));
