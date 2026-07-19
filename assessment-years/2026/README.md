# 2026 EBS pollock assessment workspace

This is the active workspace for the 2026 assessment. There was no operational
assessment in 2025, so 2025 must not be represented as an accepted assessment
model or management-advice year.

The `dashboard.qmd` page reads the annual CSV files at render time. Update the
manifests rather than editing dashboard values manually.

The local data-entry app provides a safer interface for those updates:

```sh
Rscript tools/data-entry/run.R
```

It validates records before saving and creates ignored local backups. The app
does not run on GitHub Pages; only the rendered, read-only dashboard is
published.

## Bridge sequence

1. Reproduce the accepted 2024 Model 23 assessment from its frozen inputs.
2. Reconstruct the September 2025 post-CIE development configuration and list
   each methodological change relative to 2024.
3. Apply confirmed new data to the unchanged 2024 configuration to isolate the
   data effect.
4. Add accepted 2025 development changes one at a time to establish the 2026
   candidate base model.
5. Run diagnostics, projections, and approved alternatives only after the bridge
   sequence is reconciled.

The exact September 2025 source document and configuration still require
confirmation. Candidate local workspaces are recorded in `run-manifest.csv`.
The `ebs_pollock_safe2024/doc/sept.qmd` file inspected during setup identifies
itself as September 2024 and therefore is not used as the 2025 bridge source.

Paths beginning with `$POLLOCK_ROOT` refer to the local umbrella workspace
containing this repository and its companion assessment projects.

## Review schedule

- Early September 2026: draft assessment review; exact date to be confirmed.
- November 2026: final assessment review; exact date to be confirmed.

The September draft may use clearly labeled preliminary data. The November
version must record every replacement delivery and rerun affected models,
diagnostics, projections, tables, and figures.

## Working rule for unavailable data

Do not copy forward a prior-year value without labeling it. Each unavailable
component must be identified as pending, temporarily carried forward for a
specific test, or excluded. The data inventory records which version is used in
each review milestone.
