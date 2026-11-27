# Cumulative meta-analysis

`meta_cumulative()` adds studies one at a time, in the order given by
`order` (for example publication year), and reports the pooled estimate
after each addition.

## Usage

``` r
meta_cumulative(
  .data,
  order = NULL,
  yi = .yi,
  vi = .vi,
  method = "REML",
  test = "z",
  level = 0.95,
  decreasing = FALSE
)
```

## Arguments

- .data:

  A
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
  from
  [`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md)
  (its estimator and test are reused), a
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  or a data frame.

- order:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  A variable that defines the order in which studies are added.
  Evaluated in the data used to fit the model. Defaults to the row
  order.

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding the effect sizes and sampling variances. Default to
  `.yi` and `.vi`.

- method, test:

  Used only when `.data` is not a `<meta_fit>`.

- level:

  Confidence level for intervals.

- decreasing:

  Add studies in decreasing order of `order`?

## Value

A tibble with one row per step: the study added, the number of studies
so far (`k`), `estimate`, `std.error`, `statistic`, `p.value`,
`conf.low`, `conf.high`, `tau2` and `I2`.

## References

Lau, J., Antman, E. M., Jimenez-Silva, J., Kupelnick, B., Mosteller, F.
and Chalmers, T. C. (1992). Cumulative meta-analysis of therapeutic
trials for myocardial infarction. *New England Journal of Medicine*,
327(4), 248-254.
[doi:10.1056/NEJM199207233270406](https://doi.org/10.1056/NEJM199207233270406)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
  study = author
)
meta_pool(bcg) |> meta_cumulative(order = year)
#> # A tibble: 13 × 10
#>    study        k estimate std.error statistic p.value conf.low conf.high   tau2
#>    <chr>    <int>    <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>  <dbl>
#>  1 Aronson      1   -0.889     0.571     -1.56 1.19e-1    -2.01     0.229 0     
#>  2 Ferguso…     2   -1.33      0.349     -3.80 1.47e-4    -2.01    -0.641 0     
#>  3 Stein &…     3   -0.972     0.245     -3.96 7.49e-5    -1.45    -0.491 0.0872
#>  4 Rosenth…     4   -1.00      0.222     -4.50 6.68e-6    -1.44    -0.565 0.0763
#>  5 Rosenth…     5   -1.10      0.200     -5.52 3.46e-8    -1.49    -0.710 0.0858
#>  6 Coetzee…     6   -0.973     0.188     -5.19 2.13e-7    -1.34    -0.606 0.105 
#>  7 Comstoc…     7   -0.901     0.191     -4.73 2.30e-6    -1.28    -0.527 0.120 
#>  8 Frimodt…     8   -0.789     0.197     -4.00 6.23e-5    -1.17    -0.403 0.178 
#>  9 Vandivi…     9   -0.866     0.196     -4.41 1.03e-5    -1.25    -0.481 0.202 
#> 10 Comstoc…    10   -0.785     0.180     -4.36 1.31e-5    -1.14    -0.432 0.201 
#> 11 Comstoc…    11   -0.708     0.178     -3.97 7.18e-5    -1.06    -0.359 0.228 
#> 12 Hart & …    12   -0.795     0.180     -4.42 9.94e-6    -1.15    -0.442 0.273 
#> 13 TPT Mad…    13   -0.715     0.180     -3.97 7.05e-5    -1.07    -0.362 0.313 
#> # ℹ 1 more variable: I2 <dbl>
```
