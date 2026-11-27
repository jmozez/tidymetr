# Subgroup meta-analysis

`meta_subgroup()` pools effect sizes within the levels of a categorical
variable and tests whether the subgroup estimates differ.

## Usage

``` r
meta_subgroup(
  .data,
  group,
  yi = .yi,
  vi = .vi,
  method = "REML",
  test = "z",
  level = 0.95,
  study = NULL,
  tau2 = c("separate", "common")
)
```

## Arguments

- .data:

  A
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  from
  [`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md)
  or any data frame with effect sizes and sampling variances.

- group:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  The grouping variable.

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding the effect sizes and sampling variances. Default to
  `.yi` and `.vi`.

- method:

  Estimator of the between-study variance: `"REML"`, `"ML"`, `"DL"`,
  `"PM"`, `"SJ"` or `"FE"` (common effect).

- test:

  `"z"` for normal based inference or `"hksj"` for the
  Hartung-Knapp-Sidik-Jonkman adjustment.

- level:

  Confidence level for intervals.

- study:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Optional study labels. Taken from the `<meta_es>` when available.

- tau2:

  `"separate"` or `"common"` between-study variance.

## Value

A
[`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
with one row per subgroup, including the number of studies (`k`), `tau2`
and `I2` of each subgroup. The test of subgroup differences is returned
by [`glance()`](https://generics.r-lib.org/reference/glance.html).

## Details

With `tau2 = "separate"` (the default) each subgroup is pooled on its
own, with its own \\\tau^2\\, and the test of subgroup differences is
the Q statistic of a common-effect meta-analysis of the subgroup
estimates (Borenstein et al., 2009). With `tau2 = "common"` a single
\\\tau^2\\ is assumed and the subgroup means are estimated by a
meta-regression without an intercept; the test of differences is then a
Wald test (or an F test with `test = "hksj"`) that all subgroup means
are equal.

## References

Borenstein, M., Hedges, L. V., Higgins, J. P. T. and Rothstein, H. R.
(2009). *Introduction to Meta-Analysis*, chapter 19. Wiley.

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_subgroup(bcg, alloc)
#> # Subgroup meta-analysis <meta_fit>
#> # Model: random effects, restricted maximum likelihood
#> # Measure: log risk ratio; k = 13
#> # Q(10) = 132.37, p < 0.0001
#> # Test of subgroup differences: Q(2) = 1.86, p = 0.3943
#> # A tibble: 3 × 10
#>   term       estimate std.error statistic p.value conf.low conf.high     k  tau2
#>   <chr>         <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl> <int> <dbl>
#> 1 alternate    -0.541     0.282     -1.92 5.48e-2    -1.09    0.0111     2 0.133
#> 2 random       -0.971     0.276     -3.52 4.34e-4    -1.51   -0.430      7 0.393
#> 3 systematic   -0.424     0.360     -1.18 2.38e-1    -1.13    0.281      4 0.400
#> # ℹ 1 more variable: I2 <dbl>
meta_subgroup(bcg, alloc, tau2 = "common") |> glance()
#> # A tibble: 1 × 25
#>   model_type  nobs method test   tau2 tau2.low tau2.high   tau    I2    H2    R2
#>   <chr>      <int> <chr>  <chr> <dbl>    <dbl>     <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 subgroup      13 REML   z     0.362    0.124      1.19 0.601  88.8  8.91    NA
#> # ℹ 14 more variables: QE <dbl>, df.residual <int>, p.QE <dbl>, QM <dbl>,
#> #   p.QM <dbl>, pred.low <dbl>, pred.high <dbl>, logLik <dbl>, AIC <dbl>,
#> #   BIC <dbl>, Q.between <dbl>, df.between <int>, p.between <dbl>,
#> #   tau2_type <chr>
```
