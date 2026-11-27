# Egger's regression test for funnel plot asymmetry

`meta_egger()` regresses effect sizes on their standard errors (or
sampling variances) to test for small-study effects. With `model = "lm"`
this is the classical weighted least squares test of Egger et al.
(1997), with a multiplicative dispersion term. With `model = "rma"` the
predictor is added to a mixed-effects meta-regression with additive
heterogeneity (Sterne and Egger, 2005). The intercept is the limit
estimate, the expected effect in a study with infinite precision.

## Usage

``` r
meta_egger(
  .data,
  yi = .yi,
  vi = .vi,
  predictor = c("sei", "vi"),
  model = c("lm", "rma"),
  method = "REML",
  level = 0.95
)
```

## Arguments

- .data:

  A data frame,
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  or
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
  from
  [`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md).

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding the effect sizes and sampling variances. Default to
  `.yi` and `.vi`.

- predictor:

  `"sei"` (standard error, Egger's test) or `"vi"` (sampling variance).

- model:

  `"lm"` or `"rma"`.

- method:

  Estimator of \\\tau^2\\ for `model = "rma"`. Taken from the fit when
  `.data` is a `<meta_fit>`.

- level:

  Confidence level for intervals.

## Value

A one row tibble with the slope test (`estimate`, `std.error`,
`statistic`, `df`, `p.value`) and the limit estimate with its confidence
interval.

## References

Egger, M., Davey Smith, G., Schneider, M. and Minder, C. (1997). Bias in
meta-analysis detected by a simple, graphical test. *BMJ*, 315(7109),
629-634.
[doi:10.1136/bmj.315.7109.629](https://doi.org/10.1136/bmj.315.7109.629)

Sterne, J. A. C. and Egger, M. (2005). Regression methods to detect
publication and other bias in meta-analysis. In H. R. Rothstein, A. J.
Sutton and M. Borenstein (Eds.), *Publication Bias in Meta-Analysis*
(pp. 99-110). Wiley.

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_egger(bcg)
#> # A tibble: 1 × 11
#>   test  predictor model estimate std.error statistic    df p.value
#>   <chr> <chr>     <chr>    <dbl>     <dbl>     <dbl> <int>   <dbl>
#> 1 Egger sei       lm       -2.11      1.51     -1.40    11   0.189
#> # ℹ 3 more variables: limit_estimate <dbl>, limit_conf.low <dbl>,
#> #   limit_conf.high <dbl>
meta_pool(bcg) |> meta_egger(model = "rma")
#> # A tibble: 1 × 11
#>   test  predictor model estimate std.error statistic    df p.value
#>   <chr> <chr>     <chr>    <dbl>     <dbl>     <dbl> <int>   <dbl>
#> 1 Egger sei       rma     -0.763     0.950    -0.803    NA   0.422
#> # ℹ 3 more variables: limit_estimate <dbl>, limit_conf.low <dbl>,
#> #   limit_conf.high <dbl>
```
