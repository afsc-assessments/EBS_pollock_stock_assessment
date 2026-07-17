# Workflow scripts

`validate_manifests.R` checks the compact example using base R. A production
repository should also provide ordered entry points for:

1. retrieving and validating annual deliveries;
2. constructing model-ready inputs;
3. building the assessment executable;
4. running bridge, base, and approved alternatives;
5. running convergence, profile, retrospective, and MCMC diagnostics;
6. exporting the terminal state to projections;
7. independently checking OFL and ABC calculations;
8. rendering and reconciling the SAFE;
9. packaging the accepted annual release.

Those entry points should fail on missing inputs instead of silently using files
from another assessment year.

