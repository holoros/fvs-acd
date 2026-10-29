"""Add v13.1 pass 3-6 findings to the Hennigar deck.
Iterative discipline: builds on the 42-slide version, adds only, no silent removal.
Clones slide 41's numbered-list grammar so new slides match exactly.
"""
import copy, sys
from pptx import Presentation
from pptx.util import Emu

SRC = "FVS-ACD_Hennigar_Aug2026.pptx"
prs = Presentation(SRC)
TEMPLATE_IDX = 40                      # slide 41, VERDICT, the numbered-list grammar
tmpl = prs.slides[TEMPLATE_IDX]

def clone_after(template, layout):
    new = prs.slides.add_slide(layout)
    # nuke any placeholders the layout injected
    for sh in list(new.shapes):
        sh._element.getparent().remove(sh._element)
    # background
    bg = template._element.find('.//{http://schemas.openxmlformats.org/presentationml/2006/main}bg')
    if bg is not None:
        new._element.find('.//{http://schemas.openxmlformats.org/presentationml/2006/main}cSld').insert(0, copy.deepcopy(bg))
    spTree = new._element.find('.//{http://schemas.openxmlformats.org/presentationml/2006/main}spTree')
    tsp = template._element.find('.//{http://schemas.openxmlformats.org/presentationml/2006/main}spTree')
    for el in list(tsp):
        if el.tag.endswith('}sp') or el.tag.endswith('}pic') or el.tag.endswith('}graphicFrame'):
            spTree.append(copy.deepcopy(el))
    return new

def textshapes(slide):
    return [sh for sh in slide.shapes if sh.has_text_frame and sh.text_frame.text.strip()]

def setrun(shape, text):
    tf = shape.text_frame
    p0 = tf.paragraphs[0]
    if not p0.runs:
        return
    p0.runs[0].text = text
    for r in p0.runs[1:]:
        r.text = ""
    for extra in tf.paragraphs[1:]:
        for r in extra.runs:
            r.text = ""

def build(slide, kicker, title, items, notes):
    ts = textshapes(slide)
    setrun(ts[0], kicker)
    setrun(ts[1], title)
    for i, sh in enumerate(ts[2:]):
        setrun(sh, items[i] if i < len(items) else "")
    slide.notes_slide.notes_text_frame.text = notes

# ---------------------------------------------------------------- new slides
NEW = [
("V13.1  WHERE THE BIAS LIVES",
 "The failure is stem transition, not demography",
 ["1  Substituting observed diameters closes bias from -16.53% to -1.09%",
  "2  Substituting observed heights buys only +0.79 points",
  "3  Survivors pile up at 6 to 8 cm (+61%) and 8 to 10 cm (+41%)",
  "4  Classes above 12.7 cm run 17 to 29% short; total stem count unbiased at +1.5%",
  "5  Two demographic levers built, fitted, scored: both null, together worth 0.78 points"],
 "This is the finding that reoriented the whole v13.1 workstream, and it came out of a tree-list "
 "decomposition run on a predicted t2 list that is byte identical to the base run at 0.000e+00 across "
 "all 35 numeric columns. The counterfactual ladder is the evidence: predicted diameters with an "
 "observed height curve moves 137.34 to 137.74 cubic metres per hectare, while observed diameters with "
 "a predicted height curve moves 137.34 to 162.74 against an observed 164.54. The diameter distribution "
 "outweighs height roughly twenty to one. I want to be careful about one thing here. An earlier statement "
 "of this localization claimed a general diameter increment failure on the evidence that predicted QMD "
 "increment was 43 percent of observed. Our own red team broke that claim, because QMD is exactly the "
 "square root of BA over TPH over pi over forty thousand, verified to seven times ten to the minus "
 "fifteen centimetres across all 918 plots, so it is one fact stated twice and carries no information "
 "beyond basal area and stem count. We dropped it. What survives is independent of that identity: forcing "
 "predicted basal area to equal observed by rescaling every expansion factor still leaves volume 7.44 "
 "percent short, and the basal-area-weighted median diameter is 2.66 centimetres short. Above 25 "
 "centimetres, where stems cannot have arrived by ingrowth inside the interval, the model delivers 46 "
 "percent of observed accretion."),

("V13.1  THE BIAS BUDGET",
 "Four pieces, and the largest was never on our list",
 ["1  Ceiling is 15.44 points: observed diameter distribution closes -16.53% to -1.09%",
  "2  Convexity, the second moment: 3.87 points, 25% of the ceiling",
  "3  Chapter 10 basal area constraint: 1.22 points",
  "4  Diameter increment reshaping: 1.13 points",
  "5  Residual, demographic and still open: 9.23 points, 60% of the ceiling"],
 "The convexity piece is the one nobody had scoped, and it is the largest single item we found. The model "
 "propagates one deterministic trajectory per tree record and then scores a convex function of the "
 "accumulated diameter. Volume goes roughly as diameter to the two and a half and basal area as diameter "
 "squared, so the expectation of the volume exceeds the volume of the expectation by an amount set by the "
 "within-cell variance. The model computes the volume of the mean; the benchmark observes the mean of the "
 "volume. No recalibration of the increment coefficients on a conditional mean can remove that, because "
 "the defect is in the second moment rather than the first. We were worried the correction would mostly be "
 "fitting measurement error, so we decomposed the variance: total within-cell standard deviation of the "
 "20.5 year increment is 2.589 centimetres against a measurement error standard deviation of 0.298, so "
 "measurement error is 1.3 percent of the variance and the haircut costs only 0.11 points. The correction "
 "and the increment reshaping are almost exactly additive, predicted -11.535 against realised -11.586. "
 "Caveat worth stating out loud: a smearing correction on a convex function always raises predicted "
 "volume, so it improves nine of our eleven sources by construction. That is not evidence it is right, and "
 "it makes Baxter worse by 0.82 points, which is the honest cost."),

("V13.1  DEMOGRAPHY",
 "The model under recruits, and fixing it closes basal area",
 ["1  Model recruits 0.032 m² ha⁻¹ yr⁻¹ against observed 0.079, a factor of 2.5 low",
  "2  Raising ingrowth 3.9x: basal area bias -9.82% to -5.21%",
  "3  Adding a self thinning retune: basal area -1.56%, volume -9.33%",
  "4  Volume gap survives a nearly closed basal area gap",
  "5  So the residual is size distribution, not stem count"],
 "This inverts what we told ourselves two passes ago, and the correction is worth being explicit about "
 "because it changes the direction of the fix. Every ingrowth counterfactual this project had ever run "
 "moved downward, at multipliers of zero, a third, and three quarters. Nobody had run it upward, because "
 "we believed the model was over recruiting. It is not. Separating genuine recruitment from FIA subplot "
 "frame ingrowth is what settles it: of 23,689 t2 stems with no t1 antecedent, 17,051 sit at or above "
 "12.7 centimetres and are not recruitment at all, they are stems that were between 2.54 and 12.7 "
 "centimetres at t1, outside the 6.8 foot microplot, never censused, and entered the 24 foot subplot "
 "frame by crossing 12.7 centimetres. The area budget is decisive: the t1 microplot pool scales to 65,261 "
 "subplot equivalent stems and the 17,051 arrivals are 26 percent of it, where genuine recruitment above "
 "12.7 centimetres would have required a fraction above one. The last line is the one I would put weight "
 "on for this group. When we push basal area from minus 9.8 to minus 1.6 and volume only moves to minus "
 "9.3, that is direct evidence that the residual is stems sitting in the wrong diameter classes rather "
 "than too few stems, which is the same conclusion the tree list decomposition reached from the other "
 "direction. One caveat: the two cells that were supposed to combine raised ingrowth with the refitted "
 "increment silently did not apply the new coefficients, so that combination is untested."),

("V13.1  SELF CORRECTION",
 "Three numbers withdrawn under our own review",
 ["1  QMD increment, 43% of observed: an identity, no information beyond BA and TPH",
  "2  Ingrowth 0.377 m² ha⁻¹ yr⁻¹: a units error, ING_p is stems per hectare",
  "3  Drain split 41/59: residual attribution, direct instrumentation gives 73/27",
  "4  Observed drain undervalued: dead stems valued at t1 diameter, growth fraction 0.275",
  "5  Corrected, model drain is 12% high, not 140%"],
 "I am putting this slide in deliberately, because the review process is the part of this work I would "
 "most want another modelling group to copy, and because two of these three errors were mine. The QMD "
 "claim was broken by an internal red team pass before it ever left the group. The ingrowth number is the "
 "instructive one: ING_p in our results files is stems per hectare, not basal area, and the figure 0.377 "
 "is exactly the sum of ING_p over the sum of the interval lengths, so it is a stems per year rate that I "
 "labelled as basal area and then carried into a handoff and into three separate analysis briefs before "
 "two independent tracks caught it. The true value is 0.015, a factor of 25 smaller, and every statement "
 "about excess ingrowth that rested on it is void. The drain split was attributed by residual, assigning "
 "everything one component did not explain to the other; direct instrumentation of the stand loop, with "
 "the balance closing at gross 0.7899 equals net 0.3551 plus drain 0.4348 and the instrumented state "
 "reproducing scored output to six ten-thousandths, reverses which component is larger. Finally, valuing "
 "dead and removed stems at their t1 diameter understated observed drain by about 20 percent; the basal "
 "area weighted realised growth fraction is 0.275. Corrected, the model over drains by 12 percent, which "
 "is a tuning problem, not the structural failure we had been describing."),
]

layout = tmpl.slide_layout
made = []
for kicker, title, items, notes in NEW:
    s = clone_after(tmpl, layout)
    build(s, kicker, title, items, notes)
    made.append(s)

# ------------------------------------------------- reorder: place after ROADMAP (slide 39, idx 38)
sldIdLst = prs.slides._sldIdLst
ids = list(sldIdLst)
newids = [e for e in ids[-len(made):]]
for e in newids:
    sldIdLst.remove(e)
rest = list(sldIdLst)
anchor = 39  # insert starting at position 40 (0-based 39), right after ROADMAP
for off, e in enumerate(newids):
    sldIdLst.insert(anchor + off, e)

# ------------------------------------------------- refresh the two stale slides
def find_slide(pred):
    for s in prs.slides:
        ts = textshapes(s)
        if ts and pred(ts[0].text_frame.text.strip()):
            return s
    return None

road = find_slide(lambda t: t.startswith("ROADMAP"))
if road:
    for sh in textshapes(road):
        t = sh.text_frame.text.strip()
        if t.startswith("Gated and running"):
            setrun(sh, "Six passes done: bias localized, budget built, 60% still open")
        elif t.startswith("v13.1"):
            setrun(sh, "v13.1  Diameter distribution and demography")
    n = road.notes_slide.notes_text_frame
    n.text = (n.text + "\n\nUpdate as of 5 August 2026. v13.1 has now run six passes. The headline moved twice "
              "under internal review and landed on the diameter distribution rather than on demography. The "
              "hierarchical mortality and ingrowth posteriors are scientifically sound and reportable but are "
              "not bias fixes; together they are worth 0.78 points against a 15.44 point ceiling. What is "
              "carried forward into the fall is the bias budget on the following slides, and the open 9.2 "
              "point residual.").strip()

verdict = find_slide(lambda t: t.startswith("VERDICT"))
if verdict:
    for sh in textshapes(verdict):
        if sh.text_frame.text.strip().startswith("5  v13.1 gated"):
            setrun(sh, "5  v13.1: bias localized to diameter distribution, 60% of the gap still open")
    n = verdict.notes_slide.notes_text_frame
    n.text = (n.text + "\n\nUpdated 5 August 2026. Point five previously read that v13.1 was gated and running. "
              "It has now run six passes and the honest statement is that we know where the developing plot "
              "bias lives and we have accounted for about 40 percent of it. Nothing in the v12.11 scorecard "
              "changes; the v13.1 work sits downstream of it.").strip()

prs.save(SRC)
print("saved %s, %d slides" % (SRC, len(prs.slides._sldIdLst)))
