# Back-transform effect sizes

Converts pooled or study level estimates back to their natural scale:
exponentiation for log ratios, the inverse Fisher transformation for
`"ZCOR"` and the inverse logit for `"PLO"`. Other measures are returned
unchanged.

## Usage

``` r
meta_transform(
  .data,
  measure = NULL,
  cols = c("estimate", "conf.low", "conf.high")
)
```

## Arguments

- .data:

  A
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
  or a data frame.

- measure:

  The effect size measure. Taken from the fit when `.data` is a
  `<meta_fit>`.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Columns to transform. Defaults to `estimate`, `conf.low` and
  `conf.high`.

## Value

`.data` with the selected columns back-transformed, as a plain tibble.

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_pool(bcg) |> meta_transform()
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic   p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
#> 1 overall    0.489     0.180     -3.97 0.0000705    0.344     0.696
```
