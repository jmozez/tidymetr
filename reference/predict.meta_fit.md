# Predictions from meta-analytic models

Predicted (average) effects with confidence or prediction intervals. For
models with moderators, `newdata` supplies the moderator values; for
models without moderators the pooled estimate is returned. Prediction
intervals add the between-study variance to the variance of the
prediction.

## Usage

``` r
# S3 method for class 'meta_fit'
predict(
  object,
  newdata = NULL,
  interval = c("confidence", "prediction", "none"),
  level = NULL,
  ...
)
```

## Arguments

- object:

  A
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md).

- newdata:

  Optional data frame of moderator values (or, for
  [`meta_subgroup()`](https://tidymetr.in4metrix.dev/reference/meta_subgroup.md)
  fits, of the grouping variable).

- interval:

  `"confidence"`, `"prediction"` or `"none"`.

- level:

  Confidence level. Defaults to the level of the fit.

- ...:

  Not used.

## Value

A tibble with `.pred`, `.se` and, unless `interval = "none"`,
`.pred_lower` and `.pred_upper`. Without `newdata`, models with
moderators return one row per study and models without moderators a
single row.

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
fit <- meta_regress(bcg, ~ ablat)
predict(fit, newdata = data.frame(ablat = c(10, 50)),
        interval = "prediction")
#> # A tibble: 2 × 4
#>     .pred   .se .pred_lower .pred_upper
#>     <dbl> <dbl>       <dbl>       <dbl>
#> 1 -0.0395 0.187      -0.693       0.614
#> 2 -1.20   0.172      -1.84       -0.566
```
