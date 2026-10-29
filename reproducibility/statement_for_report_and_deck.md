# Reproducibility statement (for benchmark report and deck speaker notes)

AcadianGY, referred to as FVS-ACD throughout this project's documents, is a fully open R
reimplementation of the Acadian growth-and-yield model, distinct from the compiled Fortran FVS
Acadian variant maintained separately by Ben Rice at Midgard Natural Resources. Its source has been
openly readable throughout development, in contrast to OSM-ACD, the competing benchmark model,
which is closed, compiled .NET software. As of August 2026, the scored production versions of
AcadianGY are git-tagged at the exact commit containing each version's engine file: v12.6.1
(`v12.6.1-candidate`), v12.7.0 (`v12.7.0-operational`), v12.10.1, the current frozen operational
baseline (`v12.10.1-frozen-aug2026`), and v12.11, the current candidate carried into this meeting
(`v12.11-candidate-aug2026`). Each tag has been audited against the repository history and confirmed
to point at a commit whose engine file is byte-identical to the version actually scored in the
corresponding benchmark report, with the scoring harness and datasets documented alongside it in
`reproducibility/README.md`. Running AcadianGY today still requires OSC Cardinal, where the
project's tree-list, plot-manifest, and coordinate data reside and where the pinned R 4.5.2
environment lives; a fully portable, laptop-runnable package does not yet exist, and this statement
does not claim otherwise. v13.1, the in-progress hierarchical mortality and management refit, is
excluded from this reproducible set and is marked DRAFT; it has not converged to a scored release.
What changes with this bundle is that a technical peer, given Cardinal access, now has an exact,
documented path from a named version to its engine file, its harness, and the datasets it was
scored against, rather than an untracked working file scattered across dated filenames.
