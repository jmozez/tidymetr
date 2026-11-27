# Network meta-analysis tibbles

`new_meta_nma()` is the low-level constructor for `<meta_nma>`, the
class returned by
[`meta_network()`](https://tidymetr.in4metrix.dev/reference/meta_network.md).
Each row is a treatment, with its effect relative to the reference
treatment and its P-score. The full network (all pairwise comparisons,
heterogeneity, inconsistency and the direct and indirect evidence split)
is kept in the `"nma"` attribute and is returned by
[tidy()](https://tidymetr.in4metrix.dev/reference/meta_nma_tidiers.md)
and
[glance()](https://tidymetr.in4metrix.dev/reference/meta_nma_tidiers.md).

## Usage

``` r
new_meta_nma(x, nma = list())

is_meta_nma(x)
```

## Arguments

- x:

  A data frame of treatment effects.

- nma:

  A named list of network internals.

## Value

`new_meta_nma()` returns a `<meta_nma>`. `is_meta_nma()` returns a
single logical value.

## Examples

``` r
pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
  measure = "OR", event = xi, n = ni)
nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2)
is_meta_nma(nma)
#> [1] TRUE
```
