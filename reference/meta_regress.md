# Meta-regression with study level moderators

`meta_regress()` fits a mixed-effects meta-regression in which study
level covariates (moderators) explain part of the between-study
heterogeneity. The residual heterogeneity \\\tau^2\\ is estimated with
any of the estimators available in
[`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md).
The omnibus test of moderators (`QM`) is a Wald chi-squared test, or an
F test when `test = "hksj"`. The pseudo \\R^2\\ compares \\\tau^2\\ from
the model with that of an intercept only model fitted with the same
estimator.

## Usage

``` r
meta_regress(
  .data,
  mods,
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

- mods:

  A one-sided formula of moderators, for example `~ ablat` or
  `~ factor(alloc) + year`. Use `~ 0 + group` to drop the intercept.

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
with one row per coefficient.

## References

Thompson, S. G. and Higgins, J. P. T. (2002). How should meta-regression
analyses be undertaken and interpreted? *Statistics in Medicine*,
21(11), 1559-1573.
[doi:10.1002/sim.1187](https://doi.org/10.1002/sim.1187)

Raudenbush, S. W. (2009). Analyzing effect sizes: random-effects models.
In H. Cooper, L. V. Hedges and J. C. Valentine (Eds.), *The Handbook of
Research Synthesis and Meta-Analysis* (2nd ed., pp. 295-315). Russell
Sage Foundation.

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
fit <- meta_regress(bcg, ~ ablat)
fit
#> # Meta-regression <meta_fit>
#> # Model: random effects, restricted maximum likelihood
#> # Measure: log risk ratio; k = 13
#> # tau^2 = 0.0763; I^2 = 68.39%; H^2 = 3.16
#> # Q(11) = 30.73, p = 0.0012
#> # A tibble: 2 × 7
#>   term        estimate std.error statistic   p.value conf.low conf.high
#>   <chr>          <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
#> 1 (Intercept)   0.251    0.249        1.01 0.313      -0.237     0.740 
#> 2 ablat        -0.0291   0.00720     -4.04 0.0000524  -0.0432   -0.0150
glance(fit)
#> # A tibble: 1 × 21
#>   model_type  nobs method test    tau2 tau2.low tau2.high   tau    I2    H2
#>   <chr>      <int> <chr>  <chr>  <dbl>    <dbl>     <dbl> <dbl> <dbl> <dbl>
#> 1 regression    13 REML   z     0.0763   0.0167     0.785 0.276  68.4  3.16
#> # ℹ 11 more variables: R2 <dbl>, QE <dbl>, df.residual <int>, p.QE <dbl>,
#> #   QM <dbl>, p.QM <dbl>, pred.low <dbl>, pred.high <dbl>, logLik <dbl>,
#> #   AIC <dbl>, BIC <dbl>
predict(fit, newdata = data.frame(ablat = c(10, 30, 50)))
#> # A tibble: 3 × 4
#>     .pred   .se .pred_lower .pred_upper
#>     <dbl> <dbl>       <dbl>       <dbl>
#> 1 -0.0395 0.187      -0.405       0.326
#> 2 -0.622  0.107      -0.831      -0.412
#> 3 -1.20   0.172      -1.54       -0.867
```
