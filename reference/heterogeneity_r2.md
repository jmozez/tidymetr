# Proportion of heterogeneity explained by predictions

`heterogeneity_r2()` is a `yardstick` numeric metric that measures how
much of the between-study heterogeneity a model explains. The total
heterogeneity \\\tau^2_0\\ is the DerSimonian-Laird estimate for the
observed effect sizes. The residual heterogeneity is the matching moment
estimate around the predictions, \\\tau^2_r = \max\\0, (Q_r - (k - 1)) /
(\sum w_i - \sum w_i^2 / \sum w_i)\\\\ with \\Q_r = \sum w_i (y_i - \hat
y_i)^2\\ and \\w_i = 1 / v_i\\. Both estimates use the same scaling, so
predicting the weighted mean for every study gives 0 and perfect
predictions give 1. The metric is \\\max(0, 1 - \tau^2_r / \tau^2_0)\\,
the out-of-sample analogue of the pseudo \\R^2\\ of meta-regression
(Raudenbush, 2009). It is `NA` when there is no heterogeneity to
explain.

## Usage

``` r
heterogeneity_r2(data, ...)

# S3 method for class 'data.frame'
heterogeneity_r2(
  data,
  truth,
  estimate,
  variance,
  na_rm = TRUE,
  case_weights = NULL,
  ...
)

heterogeneity_r2_vec(
  truth,
  estimate,
  variance,
  na_rm = TRUE,
  case_weights = NULL,
  ...
)
```

## Arguments

- data:

  A data frame with the columns given in `truth`, `estimate` and
  `variance`.

- ...:

  Not currently used.

- truth:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Observed effect sizes.

- estimate:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Predicted effect sizes.

- variance:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Sampling variances. For the `_vec()` function, a numeric vector.

- na_rm:

  A logical value indicating whether `NA` values should be stripped
  before the computation proceeds.

- case_weights:

  Not supported. Must be `NULL`.

## Value

A tibble with columns `.metric`, `.estimator` and `.estimate`.
`heterogeneity_r2_vec()` returns a single number between 0 and 1.

## See also

Other meta metrics:
[`coverage_prob()`](https://tidymetr.in4metrix.dev/reference/coverage_prob.md),
[`inverse_var_rmse()`](https://tidymetr.in4metrix.dev/reference/inverse_var_rmse.md)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
fit <- meta_regress(bcg, ~ ablat)
bcg$pred <- predict(fit, newdata = bcg)$.pred
heterogeneity_r2(bcg, .yi, pred, variance = .vi)
#> # A tibble: 1 × 3
#>   .metric          .estimator .estimate
#>   <chr>            <chr>          <dbl>
#> 1 heterogeneity_r2 standard       0.832
```
