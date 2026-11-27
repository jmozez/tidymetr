# Meta-regression model specification for parsnip

`meta_linear()` defines a mixed-effects meta-regression for use with
`parsnip`, `workflows` and `tune`. The outcome is the effect size and
the predictors are study level moderators. The inverse sampling
variances enter as case weights, for example with
`hardhat::importance_weights(1 / vi)`; if no case weights are given, a
column named `.vi` in the training data is used.

## Usage

``` r
meta_linear(mode = "regression", engine = "reml")
```

## Arguments

- mode:

  A single character string for the model mode. Only `"regression"` is
  available.

- engine:

  A single character string for the engine: `"reml"`, `"dl"` or `"fe"`.

## Value

A `meta_linear` model specification.

## Engines

- `"reml"`:

  Random effects with \\\tau^2\\ estimated by restricted maximum
  likelihood (the default).

- `"dl"`:

  Random effects with the DerSimonian-Laird estimator.

- `"fe"`:

  Common effect (fixed effect) meta-regression.

## Examples

``` r
library(parsnip)
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
spec <- meta_linear(engine = "reml")
spec
#> Meta-regression model specification (regression)
#> 
#> Computational engine: reml
fitted <- fit(spec, .yi ~ ablat, data = bcg)
predict(fitted, new_data = data.frame(ablat = c(10, 40)))
#> # A tibble: 2 × 1
#>     .pred
#>     <dbl>
#> 1 -0.0395
#> 2 -0.913 
```
