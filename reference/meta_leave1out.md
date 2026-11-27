# Leave-one-out sensitivity analysis

`meta_leave1out()` refits the meta-analysis `k` times, each time leaving
out one study, to show how much the pooled estimate and the
heterogeneity depend on any single study.

## Usage

``` r
meta_leave1out(
  .data,
  yi = .yi,
  vi = .vi,
  method = "REML",
  test = "z",
  level = 0.95
)
```

## Arguments

- .data:

  A
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
  from
  [`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md)
  (its estimator and test are reused), a
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  or a data frame.

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding the effect sizes and sampling variances. Default to
  `.yi` and `.vi`.

- method, test:

  Used only when `.data` is not a `<meta_fit>`.

- level:

  Confidence level for intervals.

## Value

A tibble with one row per omitted study: `study`, `estimate`,
`std.error`, `statistic`, `p.value`, `conf.low`, `conf.high`, `tau2`,
`I2`, `H2`, `QE` and `p.QE`.

## References

Viechtbauer, W. and Cheung, M. W.-L. (2010). Outlier and influence
diagnostics for meta-analysis. *Research Synthesis Methods*, 1(2),
112-125. [doi:10.1002/jrsm.11](https://doi.org/10.1002/jrsm.11)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
  study = author
)
meta_pool(bcg) |> meta_leave1out()
#> # A tibble: 13 × 12
#>    study     estimate std.error statistic p.value conf.low conf.high  tau2    I2
#>    <chr>        <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl> <dbl> <dbl>
#>  1 Aronson     -0.707     0.190     -3.72 1.97e-4   -1.08     -0.335 0.336  93.2
#>  2 Ferguson…   -0.654     0.181     -3.62 2.95e-4   -1.01     -0.300 0.293  92.3
#>  3 Rosentha…   -0.686     0.186     -3.69 2.23e-4   -1.05     -0.322 0.321  92.9
#>  4 Hart & S…   -0.628     0.177     -3.56 3.74e-4   -0.975    -0.282 0.263  90.4
#>  5 Frimodt-…   -0.764     0.192     -3.98 6.76e-5   -1.14     -0.388 0.328  92.8
#>  6 Stein & …   -0.711     0.200     -3.55 3.85e-4   -1.10     -0.318 0.360  90.9
#>  7 Vandivie…   -0.655     0.180     -3.63 2.83e-4   -1.01     -0.302 0.293  92.3
#>  8 TPT Madr…   -0.795     0.180     -4.42 9.94e-6   -1.15     -0.442 0.273  87.0
#>  9 Coetzee …   -0.741     0.197     -3.77 1.64e-4   -1.13     -0.356 0.349  93.2
#> 10 Rosentha…   -0.653     0.184     -3.54 3.94e-4   -1.01     -0.292 0.299  92.2
#> 11 Comstock…   -0.758     0.196     -3.87 1.08e-4   -1.14     -0.374 0.340  91.8
#> 12 Comstock…   -0.760     0.182     -4.17 3.01e-5   -1.12     -0.403 0.308  92.7
#> 13 Comstock…   -0.778     0.186     -4.19 2.78e-5   -1.14     -0.414 0.304  92.3
#> # ℹ 3 more variables: H2 <dbl>, QE <dbl>, p.QE <dbl>
```
