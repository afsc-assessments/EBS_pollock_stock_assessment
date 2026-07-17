# Assessment-year organization

Each annual assessment belongs in `assessment-years/<year>/`. The directory is
a metadata and workflow layer: large, restricted, or already authoritative files
may remain in their owning systems when the manifests provide stable identifiers,
versions, access instructions, and validation evidence.

## Required annual files

- `assessment.yml`: assessment identity, source commit, software environment,
  entry points, diagnostic criteria, and release status.
- `data-manifest.csv`: each annual delivery and model-ready product, including
  provider, owner, access class, redistribution status, provenance status, and a
  stable source or archive location.
- `run-manifest.csv`: bridge, base, alternative, sensitivity, profile,
  retrospective, MCMC, and projection relationships.
- `review-decisions.csv`: author, Plan Team, SSC, and final disposition with
  dates and evidence links.
- `deliverables.csv`: SAFE source/render, model inputs and outputs, projections,
  diagnostics, review records, validation, and archive status.

## Status vocabulary

Use explicit states rather than relying on directory names:

- `planned`: defined but not started;
- `generated`: produced but not independently checked;
- `validated`: passed its documented checks;
- `author_recommended`: selected by assessment authors;
- `plan_team_recommended`: recommended by the Plan Team;
- `ssc_accepted`: accepted or recommended by the SSC;
- `final`: incorporated in the published assessment or specification;
- `superseded`: retained for history but no longer current;
- `missing`: expected but absent from the identified archive;
- `incomplete`: metadata or review evidence still needs completion.

## Annual release rule

An assessment year should not be tagged as final until:

1. required manifests pass structural validation;
2. all final SAFE values trace to machine-readable model or projection output;
3. diagnostic exceptions are documented;
4. review decisions and their evidence are linked;
5. confidential and large-file locations are recorded without exposing protected
   information;
6. the report renders in the recorded software environment;
7. the release commit and archive checksums are recorded.

Multiple milestones in one year should use descriptive tags such as
`2024-author`, `2024-plan-team`, and `2024-final`, with correction tags such as
`2024-final.1` when needed.

