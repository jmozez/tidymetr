# Effect size tibbles

`new_meta_es()` is the low-level constructor for the `<meta_es>` class,
a tibble subclass that stores study level effect sizes (`.yi`), sampling
variances (`.vi`) and standard errors (`.sei`) together with the effect
size metric. `as_meta_es()` turns a data frame that already holds effect
sizes into a `<meta_es>`. `is_meta_es()` tests for the class.

## Usage

``` r
new_meta_es(
  x = list(.yi = double(), .vi = double(), .sei = double()),
  measure = "GEN",
  study = NULL
)

as_meta_es(.data, yi, vi = NULL, sei = NULL, measure = "GEN", study = NULL)

is_meta_es(x)
```

## Arguments

- x:

  A list or data frame of columns that includes `.yi`, `.vi` and `.sei`.

- measure:

  A string naming the effect size metric, for example `"SMD"` or `"OR"`.

- study:

  For `new_meta_es()`, the name of the column holding study labels, or
  `NULL`. For `as_meta_es()`, a
  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  expression selecting that column.

- .data:

  A data frame.

- yi, vi, sei:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding effect sizes and either sampling variances (`vi`) or
  standard errors (`sei`).

## Value

`new_meta_es()` and `as_meta_es()` return a `<meta_es>` tibble.
`is_meta_es()` returns a single logical value.

## Details

The class survives `dplyr` verbs such as
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and
[`dplyr::arrange()`](https://dplyr.tidyverse.org/reference/arrange.html).
If an operation removes `.yi` or `.vi`, the result falls back to a plain
tibble.

## Examples

``` r
dat <- data.frame(id = 1:3, g = c(0.2, 0.5, 0.1), v = c(0.04, 0.02, 0.05))
es <- as_meta_es(dat, yi = g, vi = v, study = id)
es
#> # A meta_es: 3 rows x 6 columns
#> # Measure:   generic effect size
#>      id     g     v   .yi   .vi  .sei
#>   <int> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1     1   0.2  0.04   0.2  0.04 0.2  
#> 2     2   0.5  0.02   0.5  0.02 0.141
#> 3     3   0.1  0.05   0.1  0.05 0.224
is_meta_es(es)
#> [1] TRUE
```
