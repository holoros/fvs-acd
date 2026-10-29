# Track G scoping: the Chapter 10 1.22 pp bias-budget entry has no recoverable derivation

Written 13 August 2026, pass 13. Scoping only, per the pass 12 recommendation; this is not a
re-derivation and no number changes as a result of this note. No em dashes.

## What the search this pass adds to pass 9's finding

Pass 9 Track F already established that `p5cvx/c4_adversarial.R` line 99 carries the entry as a
bare literal, `pp=c(mv$cvx_on_base_pp, 1.22, mv$r2_alone_pp)`, labeled `"Chapter 10 plot BA
constraint (prior track)"`, alongside two neighboring terms that are genuinely computed from
variables. The "(prior track)" label implies the number came from pass 3 or pass 4 work, since
`p6sdi/NOTES.md` line 5 (5 August) already cites it as inherited: "Passes 3-5 took convexity 3.87,
Ch10 constraint 1.22, increment reshape 1.13."

This pass ran a broader search than pass 9's: every `.md` and `.R` file under `verify/` for
"Chapter 10", "plot BA constraint", or "ch10" in any case, not just a `p5con/` directory check.
Eleven files matched, and every one of them dates 5 August 2026 or later. Nothing from pass 3 or
pass 4 (which would predate 5 August by one to two weeks, based on the file-date pattern
elsewhere in this repo) mentions the term at all, correctly capitalized or not. The 3.87 entry's
own six-link provenance chain, by contrast, bottoms out in a dated log file
(`p5cvx/syn_13323842.out`, 5 August 2026 14:06) that computes its number from data. No equivalent
bottom exists for 1.22 anywhere the chain has been searched.

Every downstream restatement of 1.22 (`p6sdi/NOTES.md`, `p9r2rec/p9_track_d_r2_reconciliation.md`,
`p9conv2/p9_track_f_convexity_rederivation.md`) is a direct copy of the same three-decimal figure,
never a second, independently computed value. There is no case where 1.22 and 1.220 disagree, or
where a script derives something close but not identical, the pattern that would indicate a real
if lightly documented computation somewhere. The evidence is consistent with the number never
having been computed inside a script that still exists on Cardinal under `verify/`.

## What a Track G pass would need to do, in order

1. **Ask first, search second.** Unlike the 3.87 entry, where Track F's job was to trace an
   existing chain, there may be no chain to trace. Track G's first and cheapest step should be
   asking Aaron directly whether 1.22 came from a source outside this Cardinal workspace: an
   earlier working paper, a slide, an email exchange, or a session that predates the `verify/`
   directory's own history. If he confirms an external source, the source document should be
   uploaded and Track G becomes a verification task, not a search task. This step costs nothing
   and should happen before any compute time is spent.
2. **If no external source exists, search beyond `verify/`.** Pass 3 and pass 4 work may have run
   in a different working directory, or under a login-node interactive session whose commands were
   never saved to a script. Check shell history files if any survive (`~/.bash_history`,
   `~/.Rhistory`), check for any `.RData` or `.rds` workspace snapshots from the relevant date
   range, and check whether any directory outside `verify/` (for example a `p3*` or `p4*` sibling
   to the current `p5*`/`p6*`/`p9*` naming pattern) exists anywhere under the home directory.
3. **If a candidate script surfaces, apply the same identity discipline Track F used**: reproduce
   the number from the script as it exists today, not as remembered, and flag any mismatch rather
   than rounding it away.
4. **If nothing surfaces, re-derive from first principles rather than leave the entry unexplained.**
   The label "Chapter 10 plot BA constraint" points at LEVER 3 (form 3b), the same stand-level
   basal-area constraint retune pass 9 Track A used for ship18. A from-scratch derivation would
   isolate LEVER 3b's own contribution to the mefia_l total-volume bias ceiling, analogous to how
   Track F isolated the convexity/second-moment term, and report it as a new measurement rather
   than a recovered one, explicitly labeled as such in the budget.
5. **Either way, update the budget language.** If recovered, cite the source. If re-derived, label
   it "re-derived 13 August 2026, Track G" the way Track F's entry now carries its own provenance
   note, so a future pass does not have to repeat this search a third time.

## What this pass deliberately did not do

Did not attempt step 4 (re-derivation) here, since pass 12 was explicit that doing so under time
pressure risks manufacturing a number the firewall discipline exists to prevent. Did not search
outside `verify/` (step 2) or ask Aaron directly (step 1), since those are Track G's own first
moves, not something to fold into a scoping note. This document's contribution is narrowing the
search: the earlier hypothesis that a `p5con/`-style directory holds the answer is now ruled out
(pass 12 already found `p5con/` is the unrelated Baxter self-thinning k-parameter work), and the
broader eleven-file search this pass ran confirms no file anywhere under `verify/`, in any
directory, predates 5 August 2026 while mentioning the term. The 1.22 pp entry is either external
to this workspace entirely or was computed in a session that left no trace, and Track G should be
scoped around that finding rather than around another `verify/`-wide grep.
