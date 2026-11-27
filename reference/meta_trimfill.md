# Trim-and-fill adjustment for funnel plot asymmetry

`meta_trimfill()` implements the non-parametric trim-and-fill method of
Duval and Tweedie (2000). Studies on the more extreme side of the funnel
are iteratively trimmed until the remaining studies are symmetric; the
trimmed studies are then mirrored around the adjusted centre to impute
the studies that appear to be missing, and the meta-analysis is
refitted. The side of the funnel with missing studies is estimated from
the sign of Egger's slope unless `side` is given.

## Usage

``` r
meta_trimfill(
  .data,
  yi = .yi,
  vi = .vi,
  side = NULL,
  estimator = c("L0", "R0"),
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

- side:

  `"left"` or `"right"`, the side with missing studies. Estimated when
  `NULL`.

- estimator:

  `"L0"` or `"R0"` estimator of the number of missing studies.

- method:

  Estimator of \\\tau^2\\, taken from the fit when `.data` is a
  `<meta_fit>`.

- level:

  Confidence level for intervals.

## Value

A
[`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
fitted to the observed and filled studies.
[`glance()`](https://generics.r-lib.org/reference/glance.html) reports
the number of filled studies (`k0`) and the side, and
[`augment()`](https://generics.r-lib.org/reference/augment.html) flags
the filled studies.

## Details

Trim-and-fill is a sensitivity analysis: the filled studies are not real
and the adjusted estimate should be interpreted with caution.

## References

Duval, S. and Tweedie, R. (2000). Trim and fill: a simple
funnel-plot-based method of testing and adjusting for publication bias
in meta-analysis. *Biometrics*, 56(2), 455-463.
[doi:10.1111/j.0006-341x.2000.00455.x](https://doi.org/10.1111/j.0006-341x.2000.00455.x)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_pool(bcg) |> meta_trimfill()
#> # Trim-and-fill adjusted meta-analysis <meta_fit>
#> # Model: random effects, restricted maximum likelihood
#> # Measure: log risk ratio; k = 14
#> # tau^2 = 0.3313; I^2 = 92.14%; H^2 = 12.72
#> # Q(13) = 154.68, p < 0.0001
#> # Studies filled on the right side: 1
#> # 95% prediction interval: [-1.8382, 0.5240]
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic  p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
#> 1 overall   -0.657     0.179     -3.68 0.000233    -1.01    -0.307
```
