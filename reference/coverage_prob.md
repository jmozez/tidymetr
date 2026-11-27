# Coverage probability of interval predictions

`coverage_prob()` is a `yardstick` numeric metric giving the share of
observed values that fall inside Wald intervals \\\hat y \pm z\_{(1 +
level)/2} SE\\. Use the prediction standard error, \\\sqrt{SE^2 +
\tau^2 + v_i}\\, to check the calibration of prediction intervals for
new studies. A well calibrated model has coverage close to `level`.

## Usage

``` r
coverage_prob(data, ...)

# S3 method for class 'data.frame'
coverage_prob(
  data,
  truth,
  estimate,
  std_error,
  level = 0.95,
  na_rm = TRUE,
  case_weights = NULL,
  ...
)

coverage_prob_vec(
  truth,
  estimate,
  std_error,
  level = 0.95,
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

- std_error:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Standard errors of the predictions. For the `_vec()` function, a
  numeric vector.

- level:

  The nominal level of the intervals.

- na_rm:

  A logical value indicating whether `NA` values should be stripped
  before the computation proceeds.

- case_weights:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Optional case weights, used when `variance` is `NULL`.

## Value

A tibble with columns `.metric`, `.estimator` and `.estimate`.
`coverage_prob_vec()` returns a single number between 0 and 1.

## See also

Other meta metrics:
[`heterogeneity_r2()`](https://tidymetr.in4metrix.dev/reference/heterogeneity_r2.md),
[`inverse_var_rmse()`](https://tidymetr.in4metrix.dev/reference/inverse_var_rmse.md)

## Examples

``` r
df <- data.frame(obs = c(0.1, 0.4, -0.2, 0.9), pred = c(0.2, 0.3, 0, 0.1),
                 se = c(0.1, 0.2, 0.15, 0.2))
coverage_prob(df, obs, pred, std_error = se)
#> # A tibble: 1 × 3
#>   .metric       .estimator .estimate
#>   <chr>         <chr>          <dbl>
#> 1 coverage_prob standard        0.75
```
