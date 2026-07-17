# Reusable R functions

Place reusable, tested functions here. The 2024 source assessment instead uses
`R/pm24.R` as an orchestration script and relies on the separate `ebswp` package.
This example does not copy that script because it uses assessment-specific
working-directory state and external files. Its fixed source is:

<https://github.com/afsc-assessments/ebs_pollock_safe/blob/41dc244ade54692282b1ac530b76757d4687fd37/R/pm24.R>

If this directory is intended to support `devtools::load_all()`, the repository
must also include valid `DESCRIPTION` and `NAMESPACE` files. Otherwise, document
an explicit sourcing or pipeline convention.

