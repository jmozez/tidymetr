# Pool effect sizes with common-effect or random-effects models

`meta_pool()` combines study level effect sizes into an overall estimate
using inverse variance weights. The between-study variance \\\tau^2\\
can be estimated by restricted maximum likelihood (`"REML"`, the
default), maximum likelihood (`"ML"`), the DerSimonian-Laird method of
moments (`"DL"`), the Paule-Mandel generalised Q estimator (`"PM"`) or
the Sidik-Jonkman estimator (`"SJ"`). `method = "FE"` fits a
common-effect (fixed effect) model.

## Usage

``` r
meta_pool(
  .data,
  yi = .yi,
  vi = .vi,
  method = "REML",
  test = "z",
  level = 0.95,
  study = NULL
)
```

## Arguments

- .data:

  A
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  from
  [`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md)
  or any data frame with effect sizes and sampling variances.

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

## Value

A
[`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
with one row, `term = "overall"`.

## Details

With `test = "hksj"`, the standard error is rescaled by the
Hartung-Knapp-Sidik-Jonkman factor and inference uses a t distribution
with \\k - 1\\ degrees of freedom. A prediction interval for the effect
in a new study, \\\hat\mu \pm c \sqrt{SE^2 + \hat\tau^2}\\, is always
reported, where \\c\\ is the normal or t quantile that matches `test`. A
Q-profile confidence interval for \\\tau^2\\ (Viechtbauer, 2007) is
stored and returned by
[`glance()`](https://generics.r-lib.org/reference/glance.html).

The estimators are implemented directly in base R and match the results
of
[`metafor::rma()`](https://wviechtb.github.io/metafor/reference/rma.uni.html)
to numerical precision.

## References

DerSimonian, R. and Laird, N. (1986). Meta-analysis in clinical trials.
*Controlled Clinical Trials*, 7(3), 177-188.
[doi:10.1016/0197-2456(86)90046-2](https://doi.org/10.1016/0197-2456%2886%2990046-2)

Paule, R. C. and Mandel, J. (1982). Consensus values and weighting
factors. *Journal of Research of the National Bureau of Standards*,
87(5), 377-385.
[doi:10.6028/jres.087.022](https://doi.org/10.6028/jres.087.022)

Sidik, K. and Jonkman, J. N. (2005). Simple heterogeneity variance
estimation for meta-analysis. *Journal of the Royal Statistical Society
Series C*, 54(2), 367-384.
[doi:10.1111/j.1467-9876.2005.00489.x](https://doi.org/10.1111/j.1467-9876.2005.00489.x)

Hartung, J. and Knapp, G. (2001). A refined method for the meta-analysis
of controlled clinical trials with binary outcome. *Statistics in
Medicine*, 20(24), 3875-3889.
[doi:10.1002/sim.1009](https://doi.org/10.1002/sim.1009)

Viechtbauer, W. (2007). Confidence intervals for the amount of
heterogeneity in meta-analysis. *Statistics in Medicine*, 26(1), 37-52.
[doi:10.1002/sim.2514](https://doi.org/10.1002/sim.2514)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg,
  event2 = cpos, n2 = cpos + cneg,
  study = author
)
meta_pool(bcg)
#> # Meta-analysis <meta_fit>
#> # Model: random effects, restricted maximum likelihood
#> # Measure: log risk ratio; k = 13
#> # tau^2 = 0.3132; I^2 = 92.22%; H^2 = 12.86
#> # Q(12) = 152.23, p < 0.0001
#> # 95% prediction interval: [-1.8667, 0.4376]
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic   p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
#> 1 overall   -0.715     0.180     -3.97 0.0000705    -1.07    -0.362
meta_pool(bcg, method = "DL", test = "hksj")
#> # Meta-analysis <meta_fit>
#> # Model: random effects, DerSimonian-Laird
#> # Measure: log risk ratio; k = 13
#> # tau^2 = 0.3088; I^2 = 92.12%; H^2 = 12.69
#> # Q(12) = 152.23, p < 0.0001
#> # 95% prediction interval: [-1.9872, 0.5590]
#> # Inference: Hartung-Knapp-Sidik-Jonkman t tests (df = 12)
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
#> 1 overall   -0.714     0.181     -3.95 0.00192    -1.11    -0.320
meta_pool(bcg, method = "FE") |> glance()
#> # A tibble: 1 × 21
#>   model_type  nobs method test   tau2 tau2.low tau2.high   tau    I2    H2    R2
#>   <chr>      <int> <chr>  <chr> <dbl>    <dbl>     <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 pool          13 FE     z         0       NA        NA     0  92.1  12.7    NA
#> # ℹ 10 more variables: QE <dbl>, df.residual <int>, p.QE <dbl>, QM <dbl>,
#> #   p.QM <dbl>, pred.low <dbl>, pred.high <dbl>, logLik <dbl>, AIC <dbl>,
#> #   BIC <dbl>
```
