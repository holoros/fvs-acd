# fvs-acd documentation update, 26 October 2026. Applies asserted string edits to the files fetched from the tip of
# v143-prereg1-run-20261019 (60220b5) and writes them to out/. Result sentences come from results.json, which is written
# from the RESULT files, so no number is typed here. No em dashes.
import json, os, sys, shutil
B, O = sys.argv[1], sys.argv[2]
R = json.load(open(sys.argv[3]))
os.makedirs(O, exist_ok=True)
def load(p): return open(os.path.join(B, p), encoding="utf8").read()
def save(p, t):
    d = os.path.join(O, p); os.makedirs(os.path.dirname(d) or O, exist_ok=True)
    assert "—" not in t, p; open(d, "w", encoding="utf8").write(t)
def one(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:80]); return t.replace(a, b)

# README.md
t = load("README.md")
t = one(t, "## Status (October 17, 2026)", "## Status (October 26, 2026)")
t = one(t, "| 14.2 | refinement in progress; no engine file, coefficient or default of 14.1 changed so far | record in `scripts/v14.2dev/`, release notes revision e |",
        "| 14.2 | refinement in progress; no engine file, coefficient or default of 14.1 changed so far | record in `scripts/v14.2dev/` (PREREG46 and the PREREG47 reading in `scripts/v14.2dev/2026-10-26/`), release notes revision e |")
t = one(t, "| 14.3 | planned; pre-registration 1 (the 14.1 thinning response limited to partial removals) registered October 18, 2026 after five red team rounds, not yet run | `docs/v14.3/` |",
        "| 14.3 | in study; pre-registration 1 (the 14.1 thinning response limited to partial removals) ran October 18 to 19, 2026: no eligibility rule adopted, and large residual trees after removals grow about two thirds of what 14.1 predicts; pre-registration 2 (re-estimating the form of T) is drafted, not registered | [`docs/v14.3/`](docs/v14.3/), result in [`docs/v14.3/run_v143p1/result/`](docs/v14.3/run_v143p1/result/) |")
t = one(t, """Open work waits on firebreather, the host of the 14.2 runs, which has been unreachable since
October 11, 2026: the PREREG46 run and the PREREG47 reading, the 14.2 arms p38_fit and qc_rh on the
Maine sets, and Zenodo version 1.9.0 and the version after it, which will carry the cross-version benchmark.""",
"""October 26, 2026. Firebreather, the host of the 14.2 runs, refused connections from October 11 to at least October 19
and is reachable again; the work queued on it ran:

- Zenodo version 1.9.0 was published (10.5281/zenodo.23665173). Version 1.10.0, which adds the cross-version
  benchmark and the records below, is staged and not published.
- """ + R["p46_readme"] + """
- """ + R["p47_readme"] + """
- The 14.2 arms p38_fit and qc_rh reproduce 14.1 exactly on the three Maine frames of the cross-version benchmark
  (ten year hindcast, post-harvest set, 200 yr projections): every compared value differs by 0. Both arms change only
  the Quebec height path, so this was the expected identity, now measured
  (`scripts/v14.2dev/2026-10-26/acdx_arms/`).""")
t = one(t, "| `VERSION_HISTORY.md` | every engine version, nine eras, from 12.3.6 to 14.1 |", "| [`VERSION_HISTORY.md`](VERSION_HISTORY.md) | every engine version from 12.3.6 to 14.1 in nine eras, and the 14.3 studies in a tenth |")
t = one(t, "| `docs/preregistrations.md` | index of the 14.2 pre-registrations and results |", "| [`docs/preregistrations.md`](docs/preregistrations.md) | index of the 14.2 and 14.3 pre-registrations and results |")
t = one(t, "| `docs/index.md` | documentation map, including the branch map |", "| [`docs/index.md`](docs/index.md) | documentation map, including the branch map |")
t = one(t, "(1.8.0, 10.5281/zenodo.23168366, as of this writing)", "(1.9.0, 10.5281/zenodo.23665173, published October 26, 2026, as of this writing)")
save("README.md", t)

# CITATION.cff
t = load("CITATION.cff")
t = one(t, 'doi: "10.5281/zenodo.22996790"\n', 'doi: "10.5281/zenodo.22996790"\nversion: "1.9.0"\ndate-released: "2026-10-26"\nidentifiers:\n  - type: doi\n    value: "10.5281/zenodo.22996790"\n    description: "Concept DOI, all versions of the Zenodo deposit"\n  - type: doi\n    value: "10.5281/zenodo.23665173"\n    description: "Zenodo deposit version 1.9.0"\n')
save("CITATION.cff", t)

# docs/index.md
t = load("docs/index.md")
t = one(t, "| `v14.3/` | 14.3 pre-registration 1 (registered October 18, 2026, md5 7f3e67c2), its registration log, change log and the five red team reviews |",
        "| [`v14.3/`](v14.3/) | 14.3 pre-registration 1 (registered October 18, 2026, md5 7f3e67c2), its registration log, change log and the five red team reviews in `review/`; the run of October 18 to 19 in `run_v143p1/` (`result/` holds the RESULT, deviations and tables; `explore/` the post hoc stress test); the unregistered PREREG2 draft in `prereg2_draft/` |")
t = one(t, "| `preregistrations.md` | index of the 14.2 refinement pre-registrations and results, PREREG13b to PREREG49 |",
        "| [`preregistrations.md`](preregistrations.md) | index of the 14.2 refinement pre-registrations and results, PREREG13b to PREREG49, and of the 14.3 pre-registrations |")
t = one(t, "| `benchmarks/2026-10-16_cross-version/README.md` | 13.1h, 14.0.4 L2 and 14.1 on 19 frozen sets, 827 post-harvest Maine FIA stands and 200 yr projections |",
        "| [`benchmarks/2026-10-16_cross-version/README.md`](benchmarks/2026-10-16_cross-version/README.md) | 13.1h, 14.0.4 L2 and 14.1 on 19 frozen sets, 827 post-harvest Maine FIA stands and 200 yr projections; the 14.2 arms p38_fit and qc_rh on the Maine frames (October 26) are in `../scripts/v14.2dev/2026-10-26/acdx_arms/` |")
t = one(t, "The repository holds several lines of work that have not been merged into `main`. As of October 17,\n2026:",
        "The repository holds several lines of work that have not been merged into `main`. As of October 26,\n2026 (all pull requests listed are drafts; none is merged):")
t = one(t, "| `docs-v142-p46p47-v143-20261017` | PREREG46 and PREREG47 records (October 11 and 15) | stacked on PR #10 |",
        "| `docs-v142-p46p47-v143-20261017` | PREREG46 and PREREG47 records (October 11 and 15) | PR #11, stacked on PR #10 |")
t = one(t, "| `docs-overhaul-20261017` | this documentation set, the user guide and the `scripts/` index | stacked on the branch above |",
        "| `docs-overhaul-20261017` | the documentation set, the user guide and the `scripts/` index | PR #12, stacked on PR #11 |\n"
        "| `v143-prereg1-run-20261019` | the 14.3 PREREG1 run and RESULT, the T form diagnostics and the PREREG2 draft | " + R["pr_v143"] + " |\n"
        "| `engine-frozen-cardinal-20261019` | the frozen Cardinal engine copies with an md5 manifest | " + R["pr_engine"] + " |\n"
        "| `" + R["branch"] + "` | the October 26 runs (PREREG46, the PREREG47 reading, the acdx arms, Zenodo 1.9.0 scripts) and this documentation update | stacked on `v143-prereg1-run-20261019` |")
save("docs/index.md", t)

# docs/preregistrations.md (rows added by hand in the generator's format; rerun build_prereg_index.py to confirm)
t = load("docs/preregistrations.md")
for a, b in R["prereg_rows_after"]:
    t = one(t, a + "\n", a + "\n" + b + "\n")
t = one(t, "14.3 pre-registrations, when they exist, are in `docs/v14.3/`.", "14.3 pre-registrations are listed in the 14.3 section at the end of this page. Rows for the October 26 records were added by hand in the generator's format.")
t = t.rstrip("\n") + "\n\n## 14.3\n\n| No. | Kind | Title | File |\n|:--|:--|:--|:--|\n" + "\n".join(R["v143_rows"]) + "\n"
save("docs/preregistrations.md", t)

# VERSION_HISTORY.md
t = load("VERSION_HISTORY.md")
t = one(t, "record that every 14.x file sources. `docs/reference/running-14.1.md` describes how the layers stack.\n",
        "record that every 14.x file sources. `docs/reference/running-14.1.md` describes how the layers stack.\n\n*Note added October 26, 2026.* Era 10 records the 14.3 studies. The section \"What this document does not cover\" now closes the document.\n")
wc = t[t.index("## What this document does not cover"):t.index("## Era 7:")]
t = t.replace(wc, "", 1)
t = one(t, """PREREG46 and revisions 1 to 5
of PREREG47 are registered but not yet run, because firebreather has been unreachable since October
11, 2026.""", R["p46p47_vh"])
t = one(t, """The 14.2 candidate arms p38_fit and qc_rh
were not run, as their engine copies are on firebreather.""", """The 14.2 candidate arms p38_fit and qc_rh
were run on October 26, 2026 on the three Maine frames and reproduce 14.1 exactly (every compared value differs by 0),
as both change only the Quebec height path (`scripts/v14.2dev/2026-10-26/acdx_arms/`).""")
t = t.rstrip("\n") + "\n\n" + R["era10"] + "\n\n" + wc.rstrip("\n") + "\n"
save("VERSION_HISTORY.md", t)

# scripts/README.md
t = load("scripts/README.md")
t = one(t, "PREREG46 and PREREG47 are registered but not run, because firebreather has been unreachable since October 11, 2026.", R["p46p47_sr"])
for a, b in R["sr_repl"]: t = one(t, a, b)
save("scripts/README.md", t)
print("DOCS_EDIT_DONE")
