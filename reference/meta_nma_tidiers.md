# Tidy, glance and augment network meta-analyses

`broom` style tidiers for
[`<meta_nma>`](https://tidymetr.in4metrix.dev/reference/new_meta_nma.md)
objects.

## Usage

``` r
# S3 method for class 'meta_nma'
tidy(
  x,
  type = c("effects", "league", "split", "inconsistency", "designs"),
  exponentiate = FALSE,
  ...
)

# S3 method for class 'meta_nma'
glance(x, ...)

# S3 method for class 'meta_nma'
augment(x, ...)
```

## Arguments

- x:

  A `<meta_nma>`.

- type:

  What to return: `"effects"` (each treatment against the reference,
  with P-scores), `"league"` (every pairwise comparison), `"split"`
  (direct and indirect evidence for each comparison with direct
  evidence), `"inconsistency"` (the decomposition of Q) or `"designs"`
  (the heterogeneity within each design).

- exponentiate:

  Exponentiate estimates and confidence limits?

- ...:

  Not used.

## Value

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns a
tibble whose columns depend on `type`.
[`glance()`](https://generics.r-lib.org/reference/glance.html) returns a
one row summary of the network.
[`augment()`](https://generics.r-lib.org/reference/augment.html) returns
the contrast level data with network estimates (`.fitted`) and residuals
(`.resid`).

## Examples

``` r
pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
  measure = "OR", event = xi, n = ni)
nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
  reference = "no_contact", small_values = "bad")
tidy(nma)
#> # A tibble: 4 × 6
#>   treatment      estimate std.error conf.low conf.high pscore
#>   <chr>             <dbl>     <dbl>    <dbl>     <dbl>  <dbl>
#> 1 no_contact        0        NA       NA         NA    0.0411
#> 2 grp_counseling    0.869     0.372    0.139      1.60 0.847 
#> 3 ind_counseling    0.709     0.195    0.326      1.09 0.716 
#> 4 self_help         0.397     0.329   -0.247      1.04 0.396 
tidy(nma, type = "split")
#> # A tibble: 6 × 11
#>   treat1       treat2 n_contrasts network  direct direct_se indirect indirect_se
#>   <chr>        <chr>        <int>   <dbl>   <dbl>     <dbl>    <dbl>       <dbl>
#> 1 ind_counsel… no_co…          15   0.709  0.722      0.206    0.594       0.622
#> 2 grp_counsel… no_co…           2   0.869  0.811      0.735    0.889       0.431
#> 3 grp_counsel… ind_c…           4   0.160 -0.0754     0.408    0.860       0.705
#> 4 ind_counsel… self_…           2   0.312 -0.0763     0.567    0.528       0.423
#> 5 grp_counsel… self_…           2   0.472  0.617      0.558    0.310       0.590
#> 6 no_contact   self_…           3  -0.397 -0.318      0.429   -0.510       0.511
#> # ℹ 3 more variables: difference <dbl>, difference_se <dbl>, p.value <dbl>
glance(nma)
#> # A tibble: 1 × 15
#>   n_studies n_treatments n_contrasts n_designs method reference   tau2   tau
#>       <int>        <int>       <int>     <int> <chr>  <chr>      <dbl> <dbl>
#> 1        24            4          28         8 REML   no_contact 0.450 0.671
#> # ℹ 7 more variables: Q <dbl>, df <int>, p.value <dbl>, Q_heterogeneity <dbl>,
#> #   p_heterogeneity <dbl>, Q_inconsistency <dbl>, p_inconsistency <dbl>
augment(nma)
#> # A tibble: 28 × 7
#>    study treat1         treat2             yi     vi .fitted .resid
#>    <chr> <chr>          <chr>           <dbl>  <dbl>   <dbl>  <dbl>
#>  1 1     no_contact     ind_counseling -2.20  0.0205  -0.709 -1.49 
#>  2 2     no_contact     ind_counseling -1.05  0.171   -0.709 -0.342
#>  3 2     no_contact     grp_counseling -0.129 0.227   -0.869  0.740
#>  4 2     ind_counseling grp_counseling  0.923 0.160   -0.160  1.08 
#>  5 3     no_contact     ind_counseling -0.870 0.626   -0.709 -0.161
#>  6 4     no_contact     ind_counseling -0.416 0.0243  -0.709  0.293
#>  7 5     no_contact     ind_counseling -2.78  2.16    -0.709 -2.07 
#>  8 6     self_help      ind_counseling  0.152 0.184   -0.312  0.464
#>  9 7     no_contact     ind_counseling -2.71  0.391   -0.709 -2.00 
#> 10 8     no_contact     ind_counseling -2.43  1.09    -0.709 -1.72 
#> # ℹ 18 more rows
```
