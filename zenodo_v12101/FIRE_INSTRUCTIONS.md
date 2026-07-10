# Fire instructions: FVS-ACD v12.10.1 Zenodo deposit

This package is staged and ready. The publish call to Zenodo cannot originate from the Cowork environment by design, so you run the one command below from wherever your `~/.zenodo_token` lives (Cardinal or your laptop). Nothing has been uploaded yet.

## One-time setup (if not already done)

Create a Zenodo personal access token at https://zenodo.org with scopes `deposit:write` and `deposit:actions`, and save it to a private file:

```
printf '%s' 'YOUR_TOKEN_HERE' > ~/.zenodo_token && chmod 600 ~/.zenodo_token
```

Install the one dependency:

```
pip install --user requests
```

## The one command (creates a reviewable DRAFT)

From inside this package folder (`zenodo_v12101/`):

```
python upload_to_zenodo.py --token-file ~/.zenodo_token --metadata zenodo_metadata.json --files-list files_to_upload.txt
```

This creates the deposition, uploads every file listed in `files_to_upload.txt` (the graphical abstract first, so it becomes the default preview), and stops. It does NOT publish. The output prints the deposition edit URL and the reserved DOI. Open the edit URL, review the draft in the Zenodo web form, then publish from the browser or rerun with `--publish`.

## When you are ready to mint

Add `--publish` to the same command to publish and mint the version DOI:

```
python upload_to_zenodo.py --token-file ~/.zenodo_token --metadata zenodo_metadata.json --files-list files_to_upload.txt --publish
```

To rehearse against the Zenodo test instance first, add `--sandbox` (uses sandbox.zenodo.org; a separate sandbox token is required).

## Concept DOI convention

Zenodo mints two DOIs: a version DOI for v12.10.1 specifically and a concept DOI that always resolves to the latest version. Cite the concept DOI in the manuscript, the GTR, and the README (currently marked [to be minted]), so the citation follows future releases. The reserved DOI printed on the draft is the version DOI and is safe to place in the manuscript before publishing; it becomes live only when you publish.

## What is in the deposit

Only shareable artifacts: the frozen R model source, the full benchmark report, the variant overview GTR draft, the six summary figures, the aggregate five-way scorecard with its data dictionary, and the README and CITATION. No per-stand results, no plot coordinates, no FIA true coordinates, and no proprietary provincial per-stand data are staged or uploaded.
