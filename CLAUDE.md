# Instructions for Claude on FVS-ACD

These rules come from Ben Rice (Midgard Natural Resources), who maintains the production model with Aaron Weiskittel. They are collected from his emails of August 11, September 8, September 18, September 27, and November 3, 2026, and they apply to every session that touches this repository, the Midgard fork of the FVS interface, or any FVS variant (ACD, HI). When a request conflicts with them, stop and ask Aaron.

## How FVS-ACD runs

FVS-ACD runs with three files: `AcadianGY.R`, `customRun_fvsRunAcadian.R`, and the FVS-NE shared library (`.dll` on Windows, `.so` on Linux). In R it also needs the `fvsOL` and `rFVS` packages, both built from the FVS interface repository. A short R script that loads the shared library, sets the FVS-ACD options (`runOps`), reads the keyword file, and calls `fvsRunAcadian()` is acceptable as an example. No other files, harnesses, loaders, or external data files may be created to run AcadianGY.

The production files are self-contained. They cannot load external data or other files.

The production code uses annual time steps only.

The production version is the one on the `main` branch of https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface (`fvsOL/inst/extdata/`), currently 12.5.1, with 12.5.2 in pull request #3 (https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/pull/3). Its documentation is `docs/production/AcadianModelOverview.html` in this repository. Pull and read both before proposing any change.

## Changing the code

1. Make only substantive changes. Do not refactor to match training data or personal preference.
2. Every change follows the existing production coding style.
3. Long commentary belongs in the changelog. Production code carries short comments only.
4. New components sit behind a switch in `ops` so users can mix older and newer components.
5. Final tests of full model behavior run only through the production workflow, meaning `customRun_fvsRunAcadian.R` inside FVS.
6. Development and test files are expected while working. When Aaron asks to finalize or to request review, the proposed changes must appear in the production files themselves.

## Git and GitHub

1. Use git for version control as intended. Do not create a new file name for a new version of a file, and do not create extra branches.
2. Do not create files unless a person asks for them.
3. Put review work on one clean branch, free of test files and intermediate steps.
4. Keep parameter updates and equation changes in separate commits, so either can be reverted alone.
5. Never open pull requests, push, or comment on the USDA Forest Service repositories (https://github.com/USDAForestService/ForestVegetationSimulator-Interface and https://github.com/USDAForestService/ForestVegetationSimulator). Only people touch those.

## Writing for people

1. Readers cannot see your context. Define every term you use, such as "default" or "screened", in plain words the first time it appears.
2. Do not put internal labels in output. Session version numbers, study codes, gate codes, and phrases like "built on the v27 source as floor" mean nothing to a reader.
3. Every reference to a file, record, commit, or DOI carries a URL.
4. Check all output for jargon and padding, and fix it before it goes out.
5. Choose the file type a reviewer can use. Tables meant for review go in a SQLite file or an interactive HTML page, since a long PDF of tables cannot be reviewed.
6. A changelog entry is brief and technical, written for a reader who knows the codebase. It states what changed, why, what was tried since the previous production version, how it was validated, and what is left.
