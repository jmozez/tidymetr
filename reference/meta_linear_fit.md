# Fit function used by the meta_linear() engines

`meta_linear_fit()` is called by `parsnip` to fit
[`meta_linear()`](https://tidymetr.in4metrix.dev/reference/meta_linear.md)
models. It is exported so `parsnip` can find it; most users will not
call it directly.

## Usage

``` r
meta_linear_fit(
  formula,
  data,
  weights = NULL,
  method = "REML",
  test = "z",
  level = 0.95
)
```

## Arguments

- formula:

  A model formula with the effect size on the left.

- data:

  The training data.

- weights:

  Inverse variance case weights. When `NULL`, the `.vi` column of `data`
  is used.

- method:

  The estimator passed to
  [`meta_regress()`](https://tidymetr.in4metrix.dev/reference/meta_regress.md).

- test:

  `"z"` or `"hksj"`.

- level:

  Confidence level.

## Value

A
[`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md).

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_linear_fit(.yi ~ ablat, data = bcg, weights = 1 / bcg$.vi)
#> # Meta-regression <meta_fit>
#> # Model: random effects, restricted maximum likelihood
#> # Measure: generic effect size; k = 13
#> # tau^2 = 0.0763; I^2 = 68.39%; H^2 = 3.16
#> # Q(11) = 30.73, p = 0.0012
#> # A tibble: 2 × 7
#>   term        estimate std.error statistic   p.value conf.low conf.high
#>   <chr>          <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
#> 1 (Intercept)   0.251    0.249        1.01 0.313      -0.237     0.740 
#> 2 ablat        -0.0291   0.00720     -4.04 0.0000524  -0.0432   -0.0150
```
