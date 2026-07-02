// FVS-ACD vs OSM Acadian re-derivation deck for the Aug 18 2026 Hennigar meeting.
// Corrected story: OSM is accurate/precise short-term; FVS edge is long-horizon realism,
// QMD, transparency, climate-readiness. Forest & Moss palette. No em dashes, no hyphens as dashes.
const pptxgen = require("pptxgenjs");
const path = require("path");
const ROOT = "/sessions/nice-eloquent-cannon/mnt/fvs-acd-site-update";
const FIG = path.join(ROOT, "figures");
const P = new pptxgen();
P.layout = "LAYOUT_WIDE"; // 13.3 x 7.5
P.author = "Aaron Weiskittel";
P.title = "FVS-ACD vs OSM: Acadian re-derivation";

const FOREST="2C5F2D", MOSS="97BC62", CREAM="F5F5F5", DARK="1E2B1E", INK="222222",
      OSMC="B85042", GREY="6E6E6E", LTMOSS="E7EFDD", WHITE="FFFFFF";
const HEAD="Cambria", BODY="Calibri";
const sh = () => ({ type:"outer", color:"000000", blur:7, offset:2, angle:45, opacity:0.14 });

function titleBar(slide, kicker, title){
  slide.background = { color: WHITE };
  slide.addText(kicker, {x:0.6,y:0.34,w:12,h:0.3,fontFace:BODY,fontSize:12,bold:true,color:MOSS,charSpacing:2,margin:0});
  slide.addText(title, {x:0.6,y:0.6,w:12.1,h:0.75,fontFace:HEAD,fontSize:26,bold:true,color:FOREST,margin:0});
}
function foot(slide, n){
  slide.addText("FVS-ACD Acadian G&Y  |  independent re-derivation  |  18 Aug 2026", {x:0.6,y:7.12,w:9,h:0.3,fontFace:BODY,fontSize:9,color:GREY,margin:0});
  slide.addText(String(n), {x:12.5,y:7.12,w:0.5,h:0.3,fontFace:BODY,fontSize:9,color:GREY,align:"right",margin:0});
}
function card(slide,x,y,w,h,fill){ slide.addShape(P.shapes.ROUNDED_RECTANGLE,{x,y,w,h,fill:{color:fill||CREAM},rectRadius:0.08,shadow:sh()}); }

// ---------- 1 TITLE ----------
let s = P.addSlide(); s.background={color:DARK};
s.addShape(P.shapes.OVAL,{x:10.4,y:-1.6,w:5,h:5,fill:{color:FOREST,transparency:35}});
s.addShape(P.shapes.OVAL,{x:11.6,y:4.2,w:3.4,h:3.4,fill:{color:MOSS,transparency:55}});
s.addText("ACADIAN GROWTH AND YIELD  |  NRCan CFS, FREDERICTON", {x:0.7,y:1.5,w:11,h:0.4,fontFace:BODY,fontSize:13,bold:true,color:MOSS,charSpacing:2,margin:0});
s.addText("FVS-ACD versus OSM", {x:0.7,y:2.0,w:12,h:0.9,fontFace:HEAD,fontSize:44,bold:true,color:WHITE,margin:0});
s.addText("An independent re-derivation on harmonized Acadian data", {x:0.7,y:3.0,w:12,h:0.6,fontFace:HEAD,fontSize:22,italic:true,color:CREAM,margin:0});
s.addText([
  {text:"Multi-dimensional scorecard: bias, precision, equivalence, forest type, biological realism\n",options:{breakLine:true}},
  {text:"Operational version FVS-ACD v12.9.x  |  all volume and biomass on FIA NSVB",options:{}}
], {x:0.7,y:3.9,w:11.5,h:1.0,fontFace:BODY,fontSize:15,color:CREAM,margin:0,lineSpacingMultiple:1.15});
s.addText("Aaron Weiskittel, University of Maine  |  for Chris Hennigar and the Acadian G&Y group", {x:0.7,y:6.3,w:12,h:0.4,fontFace:BODY,fontSize:13,color:MOSS,margin:0});

// ---------- 2 AGENDA MAP ----------
s = P.addSlide(); titleBar(s,"WHERE THIS WORK MAPS","Chris's five agenda topics");
const agenda = [
 ["1  Site productivity","ESI vs BGI vs CPSI bake-off; the dominant-height diagnostic (ESI runs high at the edge)"],
 ["2  Data harmonization","FIA, MagPlot QC and NB, PSP and SILC pooled on FIA NSVB volume and biomass as a common currency"],
 ["3  Calibrating models","Multi-dimensional scorecard: bias, precision, equivalence testing, composition-aware self-thinning"],
 ["4  Climate in G&Y","ESI current and 2030 as an explicit forward site scenario; the v13 climate driver"],
 ["5  AI for productivity","The Cowork-driven workflow that produced this benchmark, end to end"]
];
let yy=1.55;
agenda.forEach((a,i)=>{
  card(s,0.6,yy,12.1,0.94,i%2? LTMOSS:CREAM);
  s.addShape(P.shapes.OVAL,{x:0.85,y:yy+0.19,w:0.56,h:0.56,fill:{color:FOREST}});
  s.addText(String(i+1),{x:0.85,y:yy+0.19,w:0.56,h:0.56,align:"center",valign:"middle",fontFace:HEAD,fontSize:20,bold:true,color:WHITE,margin:0});
  s.addText(a[0].replace(/^\d+\s+/,""),{x:1.65,y:yy+0.12,w:3.5,h:0.7,fontFace:HEAD,fontSize:16,bold:true,color:FOREST,valign:"middle",margin:0});
  s.addText(a[1],{x:5.2,y:yy+0.08,w:7.35,h:0.78,fontFace:BODY,fontSize:12.5,color:INK,valign:"middle",margin:0});
  yy+=1.05;
});
foot(s,2);

// ---------- 3 QUESTION & DATA ----------
s = P.addSlide(); titleBar(s,"THE QUESTION AND THE DATA","One harmonized benchmark, five models");
s.addText([
 {text:"Aaron was never fully confident in the 2018 ECANUSA benchmark. This is an independent re-derivation, not a reproduction: if OSM's 2018 edge does not replicate on fresh, independent, in-domain data, we say so with evidence.",options:{}}
],{x:0.6,y:1.5,w:12.1,h:0.9,fontFace:BODY,fontSize:13.5,italic:true,color:INK,margin:0,lineSpacingMultiple:1.12});
const facts=[
 ["Independent data","MagPlot NB and QC remeasurement pairs (n=705 in-domain, NB 355, QC 350); recent Maine FIA (n=788, out of time from training)"],
 ["Common currency","Every volume and biomass metric on FIA NSVB; identical metric code applied to every model"],
 ["Five models","FVS-ACD v12.5.0 (incumbent), v12.7.0, v12.7.1, v12.9.x (operational), OSM v2.26.1"],
 ["Scorecard","Nine metrics: BA, SDI, QMD, top height, total and merch and sawlog volume, biomass, value. Level and increment, by jurisdiction and forest type."]
];
let fy=2.55;
facts.forEach((f,i)=>{
  const x = i%2? 6.75:0.6; if(i%2===0 && i>0) fy+=2.0; const yb= i<2? 2.55 : 4.6;
  const xb= i%2? 6.75:0.6;
  card(s,xb,yb,5.95,1.85);
  s.addText(f[0],{x:xb+0.3,y:yb+0.2,w:5.4,h:0.4,fontFace:HEAD,fontSize:16,bold:true,color:FOREST,margin:0});
  s.addText(f[1],{x:xb+0.3,y:yb+0.68,w:5.4,h:1.05,fontFace:BODY,fontSize:12.5,color:INK,margin:0,lineSpacingMultiple:1.1});
});
foot(s,3);

// ---------- 4 HEATMAP ----------
s = P.addSlide(); titleBar(s,"THE SCORECARD","Level bias across nine metrics and five models");
s.addImage({path:path.join(FIG,"hennigar_scorecard_heatmap.png"),x:0.55,y:1.55,w:9.6,h:3.66});
card(s,10.35,1.7,2.5,3.5,LTMOSS);
s.addText([
 {text:"Read\n",options:{bold:true,color:FOREST,fontSize:14,breakLine:true}},
 {text:"Green is near zero. Over-prediction (red) shrinks as the model matures.\n\n",options:{breakLine:true}},
 {text:"v12.9.x more than halves the incumbent v12.5.0 bias on every integrator.\n\n",options:{breakLine:true}},
 {text:"OSM has the lowest pooled bias but over-predicts QMD (+11%).",options:{}}
],{x:10.55,y:1.9,w:2.15,h:3.2,fontFace:BODY,fontSize:11.5,color:INK,margin:0,lineSpacingMultiple:1.05});
s.addText("Pooled in-domain, predicted vs observed. Composition drives the residual (see forest-type slide).",{x:0.6,y:5.35,w:12,h:0.4,fontFace:BODY,fontSize:11,italic:true,color:GREY,margin:0});
foot(s,4);

// ---------- 5 PRECISION / RADAR + honest OSM note ----------
s = P.addSlide(); titleBar(s,"PRECISION, NOT JUST BIAS","Modeling efficiency separates the models");
s.addImage({path:path.join(FIG,"hennigar_scorecard_radar.png"),x:0.5,y:1.5,w:6.4,h:5.3});
card(s,7.2,1.65,5.55,2.35);
s.addText("What precision adds",{x:7.45,y:1.82,w:5.1,h:0.4,fontFace:HEAD,fontSize:16,bold:true,color:FOREST,margin:0});
s.addText([
 {text:"Bias can cancel across stands. Nash-Sutcliffe efficiency (NSE) measures per-stand skill out of sample.",options:{breakLine:true}},
 {text:"All five models are precise: pooled NSE 0.67 to 0.75. OSM 0.75, v12.9.x 0.71 are the tightest.",options:{}}
],{x:7.45,y:2.28,w:5.1,h:1.6,fontFace:BODY,fontSize:12.5,color:INK,margin:0,lineSpacingMultiple:1.12});
card(s,7.2,4.2,5.55,2.55,LTMOSS);
s.addText("Correction to the prior read",{x:7.45,y:4.37,w:5.1,h:0.4,fontFace:HEAD,fontSize:15,bold:true,color:OSMC,margin:0});
s.addText([
 {text:"An earlier scorecard reported OSM with negative NSE. On a clean, aligned merge that is a data-join artifact: OSM's true NSE is positive (0.70 to 0.75) and its short-interval accuracy is genuine.",options:{breakLine:true}},
 {text:"The FVS advantage is not precision. It is biological realism, QMD, transparency, and a climate-ready site driver.",options:{bold:true}}
],{x:7.45,y:4.83,w:5.1,h:1.8,fontFace:BODY,fontSize:12,color:INK,margin:0,lineSpacingMultiple:1.1});
foot(s,5);

// ---------- 6 EQUIVALENCE ----------
s = P.addSlide(); titleBar(s,"EQUIVALENCE TESTING (TOST)","Is predicted statistically equivalent to observed?");
s.addImage({path:path.join(FIG,"hennigar_equivalence_plot.png"),x:0.55,y:1.6,w:9.4,h:3.95});
card(s,10.15,1.7,2.7,3.9,CREAM);
s.addText([
 {text:"Why TOST\n",options:{bold:true,color:FOREST,fontSize:14,breakLine:true}},
 {text:"A non-significant bias test does not prove adequacy. Two one-sided tests (Robinson and Froese 2004) ask the right question: does the 90% CI sit inside the equivalence region (level ±10%, increment ±25%)?\n\n",options:{breakLine:true}},
 {text:"Level equivalence passes (of 9): OSM 8, v12.9.x 6, v12.7.1 6, v12.7.0 3, v12.5.0 3.",options:{bold:true}}
],{x:10.35,y:1.9,w:2.35,h:3.6,fontFace:BODY,fontSize:11,color:INK,margin:0,lineSpacingMultiple:1.05});
s.addText("Shaded band is the equivalence region. A point with its whole interval inside the band is statistically equivalent.",{x:0.6,y:5.75,w:12,h:0.4,fontFace:BODY,fontSize:11,italic:true,color:GREY,margin:0});
foot(s,6);

// ---------- 7 FOREST TYPE ----------
s = P.addSlide(); titleBar(s,"PERFORMANCE BY FOREST TYPE","The bias is composition-driven");
s.addImage({path:path.join(FIG,"hennigar_perf_by_fortype.png"),x:0.5,y:1.55,w:8.7,h:4.15});
card(s,9.45,1.7,3.4,4.3,LTMOSS);
s.addText("The composition story",{x:9.7,y:1.9,w:3.0,h:0.4,fontFace:HEAD,fontSize:16,bold:true,color:FOREST,margin:0});
s.addText([
 {text:"Softwood: every model is near zero and equivalent.\n\n",options:{breakLine:true}},
 {text:"Mixedwood: v12.9.x (+3%) and OSM equivalent.\n\n",options:{breakLine:true}},
 {text:"Hardwood: where all models struggle. v12.9.x cuts the over-prediction from +42% (v12.5.0) to +25%; even OSM is +15%.\n\n",options:{breakLine:true}},
 {text:"This is the shared frontier for the group, and it is where a composition-aware refit pays off.",options:{bold:true,color:FOREST}}
],{x:9.7,y:2.35,w:3.0,h:3.5,fontFace:BODY,fontSize:11.5,color:INK,margin:0,lineSpacingMultiple:1.05});
foot(s,7);

// ---------- 8 BAKUZIS ----------
s = P.addSlide(); titleBar(s,"BIOLOGICAL REALISM","Explicit Bakuzis relations, per model");
const bkHead=[{text:"Relation",options:{bold:true,color:WHITE,fill:{color:FOREST}}},
  {text:"v12.5.0",options:{bold:true,color:WHITE,fill:{color:FOREST}}},
  {text:"v12.7.0",options:{bold:true,color:WHITE,fill:{color:FOREST}}},
  {text:"v12.7.1",options:{bold:true,color:WHITE,fill:{color:FOREST}}},
  {text:"v12.9.x",options:{bold:true,color:WHITE,fill:{color:FOREST}}},
  {text:"OSM",options:{bold:true,color:WHITE,fill:{color:FOREST}}}];
function cell(t,pass){return {text:t,options:{color: pass==="P"?"1B5E20":(pass==="F"?"B23A2E":INK), bold: pass!=null, align:"center"}};}
const bkRows=[
 ["Eichhorn (V ~ f height)","P","P","P","P","P"],
 ["Reineke slope (~ -1.6)","F","P","P","P","F"],
 ["Site ordering (no overtaking)","P","P","P","P","P"],
 ["Yield-density / plateau","F","P","P","P","F"],
 ["Sukachev (size vs density)","F","P","P","P","F"]
];
const bkNote=["","","","","",""];
const tbl=[bkHead];
bkRows.forEach(r=>{
  tbl.push([{text:r[0],options:{fontSize:12.5,color:INK}},
    cell(r[1]==="P"?"PASS":"FLAG",r[1]),cell(r[2]==="P"?"PASS":"FLAG",r[2]),
    cell(r[3]==="P"?"PASS":"FLAG",r[3]),cell(r[4]==="P"?"PASS":"FLAG",r[4]),cell(r[5]==="P"?"PASS":"FLAG",r[5])]);
});
s.addTable(tbl,{x:0.6,y:1.65,w:8.7,colW:[3.3,1.08,1.08,1.08,1.08,1.08],rowH:0.62,
  border:{pt:0.5,color:"CCCCCC"},fontFace:BODY,fontSize:12,valign:"middle",fill:{color:WHITE}});
card(s,9.5,1.65,3.3,4.65,LTMOSS);
s.addText("The long-horizon edge",{x:9.75,y:1.85,w:2.9,h:0.4,fontFace:HEAD,fontSize:15,bold:true,color:FOREST,margin:0});
s.addText([
 {text:"v12.7.1 and v12.9.x pass all five relations: Reineke slope -1.59 (target -1.6), basal area plateaus at the realistic Acadian maximum.\n\n",options:{breakLine:true}},
 {text:"v12.5.0 never self-thins: basal area runs to 65 m2/ha with thousands of stems alive.\n\n",options:{breakLine:true}},
 {text:"OSM does not plateau either (Seven Islands: 32 to 42 m2/ha over 60 yr, no self-thinning).",options:{}}
],{x:9.75,y:2.3,w:2.9,h:3.9,fontFace:BODY,fontSize:11,color:INK,margin:0,lineSpacingMultiple:1.05});
s.addText("From seeded 160-yr projections across an ESI gradient (softwood-baseline stand). OSM from the finalized Seven Islands benchmark.",{x:0.6,y:6.45,w:8.7,h:0.5,fontFace:BODY,fontSize:10,italic:true,color:GREY,margin:0});
foot(s,8);

// ---------- 9 SITE PRODUCTIVITY ----------
s = P.addSlide(); titleBar(s,"AGENDA 1: SITE PRODUCTIVITY","ESI wins the bake-off; the anchor runs high at the edge");
s.addImage({path:path.join(FIG,"hennigar_site_productivity.png"),x:0.5,y:1.6,w:9.3,h:3.9});
card(s,10.0,1.7,2.85,3.9,CREAM);
s.addText([
 {text:"Finding\n",options:{bold:true,color:FOREST,fontSize:14,breakLine:true}},
 {text:"ESI wins the dominant-height anchor out of sample (EF 0.335) and tracks measured site index best (cor 0.667). BGI and CPSI carry no height signal.\n\n",options:{breakLine:true}},
 {text:"Diameter growth is insensitive to the metric (all four within 0.01 EF).\n\n",options:{breakLine:true}},
 {text:"The ESI anchor over-predicts height at the QC edge (6.4x increment). This is an extrapolation fix (v13), not a metric swap.",options:{bold:true}}
],{x:10.2,y:1.9,w:2.5,h:3.6,fontFace:BODY,fontSize:10.5,color:INK,margin:0,lineSpacingMultiple:1.03});
foot(s,9);

// ---------- 10 HARMONIZATION ----------
s = P.addSlide(); titleBar(s,"AGENDA 2: DATA HARMONIZATION","FIA NSVB as the common currency");
const hz=[
 ["Sources pooled","Recent Maine FIA, MagPlot QC and NB, NB and NS PSP, SILC Seven Islands, all reduced to one comparable frame"],
 ["One volume system","Every model's tree list scored with the same FIA NSVB emulator (log(y) ~ log(D^2 H) per species group, Duan smearing; R2 gross vol 0.99, biomass 0.99)"],
 ["Identical metric code","BA, SDI, QMD, top height, NSVB total and merch and sawlog volume, biomass, and value computed by one function for observed and every model"],
 ["Result","Differences are model differences, not volume-equation or data-schema differences. This benchmark is itself a harmonization exercise."]
];
let hy=1.6;
hz.forEach((h,i)=>{
  card(s,0.6,hy,12.2,1.18,i%2?LTMOSS:CREAM);
  s.addShape(P.shapes.OVAL,{x:0.85,y:hy+0.34,w:0.5,h:0.5,fill:{color:MOSS}});
  s.addText(String(i+1),{x:0.85,y:hy+0.34,w:0.5,h:0.5,align:"center",valign:"middle",fontFace:HEAD,fontSize:17,bold:true,color:WHITE,margin:0});
  s.addText(h[0],{x:1.55,y:hy+0.16,w:3.3,h:0.85,fontFace:HEAD,fontSize:15,bold:true,color:FOREST,valign:"middle",margin:0});
  s.addText(h[1],{x:4.95,y:hy+0.12,w:7.6,h:0.95,fontFace:BODY,fontSize:12,color:INK,valign:"middle",margin:0,lineSpacingMultiple:1.05});
  hy+=1.28;
});
foot(s,10);

// ---------- 11 VERDICT ----------
s = P.addSlide(); titleBar(s,"HEAD TO HEAD","Where each model wins");
card(s,0.6,1.6,3.95,4.9,LTMOSS);
s.addText("OSM v2.26.1",{x:0.85,y:1.8,w:3.5,h:0.45,fontFace:HEAD,fontSize:18,bold:true,color:OSMC,margin:0});
s.addText([
 {text:"Lowest pooled bias (mean 3.2%), highest NSE (0.75), 8 of 9 metrics equivalent.",options:{bullet:true,breakLine:true,paraSpaceAfter:10}},
 {text:"Genuinely accurate and precise at inventory-cycle intervals.",options:{bullet:true,breakLine:true,paraSpaceAfter:10}},
 {text:"Over-predicts QMD +11% (grows diameter too fast, under-recruits).",options:{bullet:true,breakLine:true,paraSpaceAfter:10}},
 {text:"No long-horizon plateau: basal area runs away (Bakuzis flags).",options:{bullet:true}}
],{x:0.85,y:2.35,w:3.5,h:4.0,fontFace:BODY,fontSize:12,color:INK,margin:0});
card(s,4.7,1.6,3.95,4.9,CREAM);
s.addText("FVS-ACD v12.9.x",{x:4.95,y:1.8,w:3.5,h:0.45,fontFace:HEAD,fontSize:18,bold:true,color:FOREST,margin:0});
s.addText([
 {text:"Near OSM on volume, biomass, value; beats OSM on the NB core integrators.",options:{bullet:true,breakLine:true,paraSpaceAfter:10}},
 {text:"Much better QMD (~+1% vs +11%) and passes all five Bakuzis relations.",options:{bullet:true,breakLine:true,paraSpaceAfter:10}},
 {text:"Plateaus at the realistic Acadian maximum; transparent R, FIA NSVB, climate-ready ESI.",options:{bullet:true,breakLine:true,paraSpaceAfter:10}},
 {text:"Cost: under-predicts BA on growing stands (-6 to -9%); top height still +9%.",options:{bullet:true}}
],{x:4.95,y:2.35,w:3.5,h:4.0,fontFace:BODY,fontSize:12,color:INK,margin:0});
card(s,8.8,1.6,4.0,4.9,DARK);
s.addText("The honest verdict",{x:9.05,y:1.8,w:3.55,h:0.45,fontFace:HEAD,fontSize:18,bold:true,color:MOSS,margin:0});
s.addText([
 {text:"On the operational domain the two are close. The 2018 conclusion that OSM clearly beats FVS-ACD does not replicate on independent in-domain data.\n\n",options:{breakLine:true}},
 {text:"Pick by use: OSM or v12.7.0 for short-rotation inventory accuracy; v12.9.x for long-horizon carbon, old growth, and climate work, where biological realism and a validated site driver matter.",options:{}}
],{x:9.05,y:2.35,w:3.55,h:4.0,fontFace:BODY,fontSize:12,color:CREAM,margin:0,lineSpacingMultiple:1.1});
foot(s,11);

// ---------- 12 CLIMATE ----------
s = P.addSlide(); titleBar(s,"AGENDA 4: CLIMATE IN G&Y","ESI as an explicit forward site scenario");
card(s,0.6,1.6,6.0,4.85,CREAM);
s.addText("The approach",{x:0.85,y:1.8,w:5.5,h:0.4,fontFace:HEAD,fontSize:16,bold:true,color:FOREST,margin:0});
s.addText([
 {text:"Validate on current ESI (trees grew under current climate); use 2030 and later ESI only for forward scenarios, never for validation.",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"A parametric climate-sensitivity ratio (GAM of measured SI on DD5, MCMT, CMD, MAP) scales the validated ESI level; smooth, monotone, correct sign for a cold-limited forest.",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Acadian direction: modest height gain driven mainly by warmer winters (MCMT); RCP4.5 is the defensible signal.",options:{bullet:true}}
],{x:0.85,y:2.3,w:5.5,h:4.0,fontFace:BODY,fontSize:12.5,color:INK,margin:0});
card(s,6.8,1.6,6.0,4.85,LTMOSS);
s.addText("Open for the group",{x:7.05,y:1.8,w:5.5,h:0.4,fontFace:HEAD,fontSize:16,bold:true,color:FOREST,margin:0});
s.addText([
 {text:"How should climate enter the site metric without breaking the validated base?",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Random forest surfaces extrapolate poorly outside the training climate envelope; a parametric, climate-sensitive dominant-height form is the credible path.",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Can the provinces share climate layers and plots to fit a shared regional site driver?",options:{bullet:true}}
],{x:7.05,y:2.3,w:5.5,h:4.0,fontFace:BODY,fontSize:12.5,color:INK,margin:0});
foot(s,12);

// ---------- 13 AI WORKFLOW ----------
s = P.addSlide(); titleBar(s,"AGENDA 5: AI FOR PRODUCTIVITY","How this benchmark was produced");
const ai=[
 ["Agentic analysis loop","An AI assistant (Cowork) drives HPC jobs on the OSC Cardinal cluster: builds harnesses, runs the models, scores, and drafts figures and reports, with a human in the loop for every decision."],
 ["Reproducible and audited","Every result is a committed script plus a versioned model file; an adversarial review pass caught a data-join artifact that had inverted the OSM precision reading."],
 ["Guardrails","Plot coordinates never leave the cluster; only aggregates appear in any deliverable. Numbers are verified programmatically, not asserted."],
 ["What it changes","Weeks of benchmarking compressed to days, with more scenarios tested and a full audit trail. The scientist sets direction and judges; the assistant executes."]
];
let ay=1.6;
ai.forEach((a,i)=>{
  card(s,0.6,ay,12.2,1.18,i%2?LTMOSS:CREAM);
  s.addText(a[0],{x:0.9,y:ay+0.14,w:3.5,h:0.9,fontFace:HEAD,fontSize:15,bold:true,color:FOREST,valign:"middle",margin:0});
  s.addText(a[1],{x:4.5,y:ay+0.12,w:8.05,h:0.95,fontFace:BODY,fontSize:12,color:INK,valign:"middle",margin:0,lineSpacingMultiple:1.05});
  ay+=1.28;
});
foot(s,13);

// ---------- 14 OPEN QUESTIONS ----------
s = P.addSlide(); s.background={color:DARK};
s.addShape(P.shapes.OVAL,{x:-1.4,y:4.6,w:4.6,h:4.6,fill:{color:FOREST,transparency:40}});
s.addText("FOR THE GROUP",{x:0.7,y:0.7,w:11,h:0.4,fontFace:BODY,fontSize:13,bold:true,color:MOSS,charSpacing:2,margin:0});
s.addText("Open questions and next steps",{x:0.7,y:1.15,w:12,h:0.7,fontFace:HEAD,fontSize:30,bold:true,color:WHITE,margin:0});
s.addText([
 {text:"Site metric: is a shared regional site driver (ESI, BGI, or CPSI) feasible, and can the provinces share layers and plots to fit it?",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Harmonization: can MagPlot, the provincial PSPs, and FIA be pooled under one schema with NSVB volume and biomass as the common currency?",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Calibration standard: would the group adopt a multi-dimensional scorecard (bias, precision, equivalence, Bakuzis) for comparing OSM, FVS-ACD, and CFS national models?",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Domain and the QC edge: report the non-Acadian-core QC edge as out of domain, as the 2018 benchmark did?",options:{bullet:true,breakLine:true,paraSpaceAfter:12}},
 {text:"Next for FVS-ACD: a regional, composition-aware mortality refit to win both the growing and mature tails, and an increment-consistent ESI anchor recalibration.",options:{bullet:true}}
],{x:0.7,y:2.1,w:11.9,h:4.7,fontFace:BODY,fontSize:14.5,color:CREAM,margin:0});

const OUT = path.join(ROOT,"FVS-ACD_Hennigar_Aug2026.pptx");
P.writeFile({fileName:OUT}).then(()=>console.log("WROTE "+OUT));
