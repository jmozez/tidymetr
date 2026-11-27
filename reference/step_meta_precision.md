# Precision features for meta-analytic models

`step_meta_precision()` creates a *specification* of a recipe step that
turns sampling variances (or standard errors) into precision features:
the standard error (`"sei"`), the precision \\1/SE\\ (`"precision"`) or
the inverse variance weight \\1/(v + \tau^2)\\ (`"weight"`). Standard
errors and variances are the predictors of Egger and PET-PEESE type
models of small-study effects.

## Usage

``` r
step_meta_precision(
  recipe,
  ...,
  input = c("vi", "sei"),
  output = "sei",
  tau2 = 0,
  role = "predictor",
  trained = FALSE,
  columns = NULL,
  keep_original_cols = TRUE,
  skip = FALSE,
  id = recipes::rand_id("meta_precision")
)

# S3 method for class 'step_meta_precision'
tidy(x, ...)
```

## Arguments

- recipe:

  A recipe object. The step will be added to the sequence of operations
  for this recipe.

- ...:

  One or more selector functions to choose the variance (or standard
  error) columns. See
  [`recipes::selections()`](https://recipes.tidymodels.org/reference/selections.html).

- input:

  Are the selected columns sampling variances (`"vi"`) or standard
  errors (`"sei"`)?

- output:

  One or more of `"sei"`, `"precision"` and `"weight"`.

- tau2:

  Between-study variance added to the variances for `"weight"`. Use 0
  for common-effect weights.

- role:

  The role of the new columns. Defaults to `"predictor"`; use
  [`recipes::update_role()`](https://recipes.tidymodels.org/reference/roles.html)
  to make the effect size an outcome.

- trained:

  A logical to indicate if the quantities for preprocessing have been
  estimated.

- columns:

  A character vector of the selected columns. This is `NULL` until the
  step is trained by
  [`recipes::prep()`](https://recipes.tidymodels.org/reference/prep.html).

- keep_original_cols:

  Keep the input columns?

- skip:

  A logical. Should the step be skipped when the recipe is baked by
  [`recipes::bake()`](https://recipes.tidymodels.org/reference/bake.html)?

- id:

  A character string that is unique to this step to identify it.

- x:

  A `step_meta_precision` object.

## Value

An updated version of `recipe` with the new step added. The new columns
are named `<column>_<output>`.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns a
tibble with columns `terms`, `output` and `id`.

## See also

Other recipe steps:
[`step_meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/step_meta_effect_size.md),
[`step_meta_impute_sd()`](https://tidymetr.in4metrix.dev/reference/step_meta_impute_sd.md)

## Examples

``` r
library(recipes)
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
rec <- recipe(.yi ~ .vi + ablat, data = bcg) |>
  step_meta_precision(.vi, output = c("sei", "weight"))
bake(prep(rec), new_data = NULL)
#> # A tibble: 13 × 5
#>        .vi ablat     .yi .vi_sei .vi_weight
#>      <dbl> <int>   <dbl>   <dbl>      <dbl>
#>  1 0.326      44 -0.889   0.571        3.07
#>  2 0.195      55 -1.59    0.441        5.14
#>  3 0.415      42 -1.35    0.644        2.41
#>  4 0.0200     52 -1.44    0.141       50.0 
#>  5 0.0512     13 -0.218   0.226       19.5 
#>  6 0.00691    44 -0.786   0.0831     145.  
#>  7 0.223      19 -1.62    0.472        4.48
#>  8 0.00396    13  0.0120  0.0629     252.  
#>  9 0.0564     27 -0.469   0.238       17.7 
#> 10 0.0730     42 -1.37    0.270       13.7 
#> 11 0.0124     18 -0.339   0.111       80.6 
#> 12 0.533      33  0.446   0.730        1.88
#> 13 0.0714     33 -0.0173  0.267       14.0 
```
