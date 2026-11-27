# Compute effect sizes in a recipe

`step_meta_effect_size()` creates a *specification* of a recipe step
that computes an effect size and its sampling variance from summary
statistics, using the same formulas as
[`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md).
The inputs are given as named selections, for example
`m1 = mean_t, sd1 = sd_t, n1 = n_t`, so the names say which role each
column plays.

## Usage

``` r
step_meta_effect_size(
  recipe,
  ...,
  measure = "SMD",
  role = "predictor",
  trained = FALSE,
  yi_name = ".yi",
  vi_name = ".vi",
  add = 0.5,
  to = "only0",
  columns = NULL,
  keep_original_cols = TRUE,
  skip = FALSE,
  id = recipes::rand_id("meta_effect_size")
)

# S3 method for class 'step_meta_effect_size'
tidy(x, ...)
```

## Arguments

- recipe:

  A recipe object. The step will be added to the sequence of operations
  for this recipe.

- ...:

  Named
  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  selections of single columns. The names must be the inputs required by
  `measure` (see
  [`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md)),
  for example `event1`, `n1`, `event2` and `n2` for `"OR"`.

- measure:

  The effect size measure.

- role:

  The role of the new columns. Defaults to `"predictor"`; use
  [`recipes::update_role()`](https://recipes.tidymodels.org/reference/roles.html)
  to make the effect size an outcome.

- trained:

  A logical to indicate if the quantities for preprocessing have been
  estimated.

- yi_name, vi_name:

  Names of the new effect size and variance columns.

- add, to:

  Zero cell correction, see
  [`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md).

- columns:

  A named character vector of the selected columns. This is `NULL` until
  the step is trained by
  [`recipes::prep()`](https://recipes.tidymodels.org/reference/prep.html).

- keep_original_cols:

  Keep the input columns?

- skip:

  A logical. Should the step be skipped when the recipe is baked by
  [`recipes::bake()`](https://recipes.tidymodels.org/reference/bake.html)?

- id:

  A character string that is unique to this step to identify it.

- x:

  A `step_meta_effect_size` object.

## Value

An updated version of `recipe` with the new step added to the sequence
of any existing operations.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns a
tibble with columns `terms`, `argument`, `measure` and `id`.

## See also

Other recipe steps:
[`step_meta_impute_sd()`](https://tidymetr.in4metrix.dev/reference/step_meta_impute_sd.md),
[`step_meta_precision()`](https://tidymetr.in4metrix.dev/reference/step_meta_precision.md)

## Examples

``` r
library(recipes)
#> Loading required package: dplyr
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
#> 
#> Attaching package: ‘recipes’
#> The following object is masked from ‘package:stats’:
#> 
#>     step
rec <- recipe(~., data = bcg_trials) |>
  step_mutate(n_t = tpos + tneg, n_c = cpos + cneg) |>
  step_meta_effect_size(event1 = tpos, n1 = n_t, event2 = cpos,
                        n2 = n_c, measure = "RR")
prepped <- prep(rec)
bake(prepped, new_data = NULL)
#> # A tibble: 13 × 13
#>    trial author     year  tpos  tneg  cpos  cneg ablat alloc   n_t   n_c     .yi
#>    <int> <fct>     <int> <int> <int> <int> <int> <int> <fct> <int> <int>   <dbl>
#>  1     1 Aronson    1948     4   119    11   128    44 rand…   123   139 -0.889 
#>  2     2 Ferguson…  1949     6   300    29   274    55 rand…   306   303 -1.59  
#>  3     3 Rosentha…  1960     3   228    11   209    42 rand…   231   220 -1.35  
#>  4     4 Hart & S…  1977    62 13536   248 12619    52 rand… 13598 12867 -1.44  
#>  5     5 Frimodt-…  1973    33  5036    47  5761    13 alte…  5069  5808 -0.218 
#>  6     6 Stein & …  1953   180  1361   372  1079    44 alte…  1541  1451 -0.786 
#>  7     7 Vandivie…  1973     8  2537    10   619    19 rand…  2545   629 -1.62  
#>  8     8 TPT Madr…  1980   505 87886   499 87892    13 rand… 88391 88391  0.0120
#>  9     9 Coetzee …  1968    29  7470    45  7232    27 rand…  7499  7277 -0.469 
#> 10    10 Rosentha…  1961    17  1699    65  1600    42 syst…  1716  1665 -1.37  
#> 11    11 Comstock…  1974   186 50448   141 27197    18 syst… 50634 27338 -0.339 
#> 12    12 Comstock…  1969     5  2493     3  2338    33 syst…  2498  2341  0.446 
#> 13    13 Comstock…  1976    27 16886    29 17825    33 syst… 16913 17854 -0.0173
#> # ℹ 1 more variable: .vi <dbl>
tidy(prepped, number = 2)
#> # A tibble: 4 × 4
#>   terms argument measure id                    
#>   <chr> <chr>    <chr>   <chr>                 
#> 1 tpos  event1   RR      meta_effect_size_GuuP1
#> 2 n_t   n1       RR      meta_effect_size_GuuP1
#> 3 cpos  event2   RR      meta_effect_size_GuuP1
#> 4 n_c   n2       RR      meta_effect_size_GuuP1
```
