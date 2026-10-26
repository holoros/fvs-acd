# Zenodo 1.9.0 publication, 26 October 2026

Host firebreather. Aaron's standing go of 11 October 2026 for 1.9.0 as staged in `~/jobs/gh_v142/zenodo_upload_p38p45b/`.
`probe.py` read the live record and the account's open drafts first (no open 14.2 draft; 1.8.0 latest). `check_deposit.py`
ended GATES PASS. `zen_newversion_190.py` created draft 23665173 as a new version of record 23168366; `zen_upload_190.py`
replaced the 100 inherited files with the 100 manifest files (0 md5 mismatches) and set the metadata; `zen_publish_190.py`
re-read the draft (unsubmitted, 100 files, version 1.9.0) and published it: DOI 10.5281/zenodo.23665173, concept DOI
10.5281/zenodo.22996790. The DOI was then written into the staged CITATION.cff and README.md (prior copies kept with a
_PREV_20261026 suffix) and the gates rerun (GATES PASS). The scripts are the 1.8.0 drivers with state file, staging folder,
manifest and version changed; the token is read from the standing file and never printed. No em dashes.
