# EBS pollock stock-assessment repository

This repository develops an assessment-year structure for eastern Bering Sea
pollock stock assessments. The initial 2024 worked example shows how the
[`nmfs-ost/region_spp_stock_assessment`](https://github.com/nmfs-ost/region_spp_stock_assessment)
folder concept can be extended for an Alaska groundfish assessment while keeping
annual data, runs, projections, review decisions, and deliverables traceable.

It describes the 2024 eastern Bering Sea pollock assessment using the committed
state of the public assessment repository at commit
[`41dc244`](https://github.com/afsc-assessments/ebs_pollock_safe/commit/41dc244ade54692282b1ac530b76757d4687fd37).
Only the committed source snapshot was used to establish provenance; no
uncommitted working-tree content from the source assessment was incorporated.

## Repository status

This is currently a local development repository and has not been published. The
2024 content is a provenance and organization example, not an authoritative copy
or independently reproduced assessment. Entries marked `TO_CONFIRM`, `missing`,
or `incomplete` identify information that still requires an authoritative source.

## What this example demonstrates

- an assessment-year directory rather than a year in the repository name;
- explicit data, model-run, review, and deliverable manifests;
- separation of a bridge run, updated model, data-withholding runs, diagnostics,
  and projections;
- fixed links to the source repository and assessment commit;
- a validation script that checks the manifests without requiring restricted data;
- a compact Quarto summary suitable for onboarding and annual release notes.

This is a provenance and organization example, not a redistributed assessment.
Model inputs, executables, detailed results, and the full SAFE remain in the
authoritative assessment repository.

## Layout

```text
R/                         reusable assessment functions belong here
data-raw/                  scripts and instructions that construct inputs
data/                      shareable data only; restricted data stay external
assessment-years/             conventions shared by all annual cycles
assessment-years/2024/
  assessment.yml           annual identity, source, software, and entry points
  data-manifest.csv        provenance and access status for annual inputs
  run-manifest.csv         role and status of each model configuration
  review-decisions.csv     author, Plan Team, and SSC decisions
  deliverables.csv         final documents and machine-readable products
index.qmd                  website homepage and compact annual summary
scripts/                   validation and workflow entry points
```

## Quick check

```sh
Rscript scripts/validate_manifests.R
quarto render
```

The first command uses base R only. The report is deliberately static so the
example can render without assessment packages or confidential inputs.

On `main`, GitHub Actions runs the same validation, renders the Quarto project,
and deploys `_site/` to GitHub Pages.

## Reproducing the actual assessment

1. Clone the authoritative assessment repository.
2. Check out commit `41dc244ade54692282b1ac530b76757d4687fd37`.
3. Restore the documented R and ADMB environment.
4. Verify access to the annual input products listed in `data-manifest.csv`.
5. Run or load Model 23 and its comparisons using `R/pm24.R` in the source
   repository.
6. Validate convergence, projections, tables, and figures before rendering the
   SAFE.

The source assessment reports a maximum gradient below `1e-3`, with MCMC
diagnostics of R-hat below 1.01 and effective sample size above 400 for the key
parameters. These claims are recorded here as reported evidence, not rerun
verification.
