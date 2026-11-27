# Impute missing standard deviations

`step_meta_impute_sd()` creates a *specification* of a recipe step that
fills in missing standard deviations, a common problem when extracting
continuous outcomes for meta-analysis. The imputation values are learned
from the studies that do report them (in the training set):

## Usage

``` r
step_meta_impute_sd(
  recipe,
  ...,
  method = c("median", "pooled", "cv"),
  n = NULL,
  means = NULL,
  role = NA,
  trained = FALSE,
  columns = NULL,
  pairs = NULL,
  values = NULL,
  skip = FALSE,
  id = recipes::rand_id("meta_impute_sd")
)

# S3 method for class 'step_meta_impute_sd'
tidy(x, ...)
```

## Arguments

- recipe:

  A recipe object. The step will be added to the sequence of operations
  for this recipe.

- ...:

  One or more selector functions to choose the standard deviation
  columns. See
  [`recipes::selections()`](https://recipes.tidymodels.org/reference/selections.html).

- method:

  `"median"`, `"pooled"` or `"cv"`.

- n, means:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Sample size or mean columns paired, in order, with the selected
  standard deviation columns. Needed for `method = "pooled"` and
  `method = "cv"`.

- role:

  Not used by this step since no new variables are created.

- trained:

  A logical to indicate if the quantities for preprocessing have been
  estimated.

- columns, pairs, values:

  Learned by
  [`recipes::prep()`](https://recipes.tidymodels.org/reference/prep.html):
  the selected columns, their paired columns and the imputation values.

- skip:

  A logical. Should the step be skipped when the recipe is baked by
  [`recipes::bake()`](https://recipes.tidymodels.org/reference/bake.html)?

- id:

  A character string that is unique to this step to identify it.

- x:

  A `step_meta_impute_sd` object.

## Value

An updated version of `recipe` with the new step added.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns a
tibble with columns `terms`, `method`, `value` and `id`.

## Details

- `"median"` uses the median of the reported standard deviations
  (Furukawa et al., 2006).

- `"pooled"` uses the pooled standard deviation \\\sqrt{\sum (n_i - 1)
  s_i^2 / \sum (n_i - 1)}\\; supply the sample size columns in `n`, in
  the same order as the selected columns.

- `"cv"` multiplies the absolute mean of each study by the median
  coefficient of variation; supply the mean columns in `means`.

## References

Furukawa, T. A., Barbui, C., Cipriani, A., Brambilla, P. and Watanabe,
N. (2006). Imputing missing standard deviations in meta-analyses can
provide accurate results. *Journal of Clinical Epidemiology*, 59(1),
7-10.
[doi:10.1016/j.jclinepi.2005.06.006](https://doi.org/10.1016/j.jclinepi.2005.06.006)

## See also

Other recipe steps:
[`step_meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/step_meta_effect_size.md),
[`step_meta_precision()`](https://tidymetr.in4metrix.dev/reference/step_meta_precision.md)

## Examples

``` r
library(recipes)
dat <- stroke_los
dat$sd1[c(2, 5)] <- NA
rec <- recipe(~., data = dat) |>
  step_meta_impute_sd(sd1, method = "pooled", n = n1)
bake(prep(rec), new_data = NULL)
#> # A tibble: 9 × 8
#>   study source                n1    m1   sd1    n2    m2   sd2
#>   <int> <fct>              <int> <dbl> <dbl> <int> <dbl> <dbl>
#> 1     1 Edinburgh            155    55  47     156    75    64
#> 2     2 Orpington-Mild        31    27  31.8    32    29     4
#> 3     3 Orpington-Moderate    75    64  17      71   119    29
#> 4     4 Orpington-Severe      18    66  20      18   137    48
#> 5     5 Montreal-Home          8    14  31.8    13    18    11
#> 6     6 Montreal-Transfer     57    19   7      52    18     4
#> 7     7 Newcastle             34    52  45      33    41    34
#> 8     8 Umea                 110    21  16     183    31    27
#> 9     9 Uppsala               60    30  27      52    23    20
```
