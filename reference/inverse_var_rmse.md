# Inverse variance weighted root mean squared error

`inverse_var_rmse()` is a `yardstick` numeric metric for predictions of
study level effect sizes. Each squared error is weighted by the inverse
of the study's sampling variance, so precise studies count for more,
exactly as they do in the meta-analytic model. Weights come from the
`variance` column, or from `case_weights` (for example
`hardhat::importance_weights(1 / vi)`) when `variance` is not given.

## Usage

``` r
inverse_var_rmse(data, ...)

# S3 method for class 'data.frame'
inverse_var_rmse(
  data,
  truth,
  estimate,
  variance = NULL,
  na_rm = TRUE,
  case_weights = NULL,
  ...
)

inverse_var_rmse_vec(
  truth,
  estimate,
  variance = NULL,
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

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Optional case weights, used when `variance` is `NULL`.

## Value

A tibble with columns `.metric`, `.estimator` and `.estimate` (one row
per group for grouped data). `inverse_var_rmse_vec()` returns a single
number.

## See also

Other meta metrics:
[`coverage_prob()`](https://tidymetr.in4metrix.dev/reference/coverage_prob.md),
[`heterogeneity_r2()`](https://tidymetr.in4metrix.dev/reference/heterogeneity_r2.md)

## Examples

``` r
df <- data.frame(obs = c(0.1, 0.4, -0.2), pred = c(0.2, 0.3, 0),
                 v = c(0.01, 0.04, 0.02))
inverse_var_rmse(df, obs, pred, variance = v)
#> # A tibble: 1 × 3
#>   .metric          .estimator .estimate
#>   <chr>            <chr>          <dbl>
#> 1 inverse_var_rmse standard       0.136
inverse_var_rmse_vec(df$obs, df$pred, variance = df$v)
#> [1] 0.136277
```
