# Provenance of the shipped 14.1 QC height anchor QC_AFAC 0.111: pre-registration 43

5 October 2026, revision 1, firebreather `~/jobs/v142p43/`. Written before the search. Records only: no engine run, no score,
no refit, nothing changed. Follows the QC anchor close out (PREREG42, `v142p42/2026-10-02_v142_qc-anchor_CLOSEOUT.md`). No
coordinates. No em dashes.

## Question

Where was the 14.1 QC height increment multiplier 0.111 set, on what data and tag pairing was it fitted, and did that fit read
the run frames (TREE a row index) or MAGPlot field tags? The answer bears on how the close out describes 0.111: as a value
fitted on wrong pairs, a value fitted on correct pairs that the field tag benchmark contradicts, or a value of unknown origin.

## Search set, fixed now

1. Firebreather: every regular file under `~/jobs`, `~/repos-mirror`, `~/src` and `~/output` with extension .r, .R, .md, .txt,
   .csv, .json, .sh, .py or .log and size at most 5 MB, searched for the literals `0.111`, `QC_AFAC` and `dht.mult` (case
   sensitive), excluding the PREREG38 to 43 job directories, the `gh_v142` staging and push trees, and `_laptop` and
   `_PREV_` copies (they postdate the question). The 14.1 model and runner files named by the 14.1 harness (`AcadianGY_14.1.r`
   0bf27dde, `runner_p28_fb.R` 0a2b2742, the v141 coefficient bundle) are read in full where the literal appears.
2. The holoros/fvs-acd branch history is not fetched (no git on firebreather); `~/repos-mirror` stands in for it.
3. The laptop is not searched by content (no shell there this session); its folder names are listed only.

## Stopping rule and reporting

Each hit is classed as SET (a line that assigns or defaults QC_AFAC or the QC dht.mult to 0.111), FIT (a script or table that
estimates it, with its data source and pairing), USE (reads or passes it on) or MENTION (text). The earliest dated SET and
every FIT are traced to their inputs; for a FIT the frames it read are identified and classed as run frames, field tag frames
or other, by path and md5 against the known frames (run frames init 6fb1ff68; field tag frames init 521d6468). The search stops
when the set is exhausted. Reported: a table of SET and FIT hits with path, line, date, md5 and class; the pairing verdict as
one of row index, field tag, other or not found. Nothing is inferred beyond what the files say; anything not found is said so.

## Verification

A second independent agent repeats the search from this plan alone and its SET and FIT lists are compared with the first.

## Constraints

New directory `~/jobs/v142p43/` only; everything else is read. Nothing sent outside.
