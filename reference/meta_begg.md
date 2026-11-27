# Begg and Mazumdar rank correlation test

`meta_begg()` tests for funnel plot asymmetry with Kendall's rank
correlation between the standardised effect sizes and their sampling
variances (Begg and Mazumdar, 1994).

## Usage

``` r
meta_begg(.data, yi = .yi, vi = .vi, exact = TRUE)
```

## Arguments

- .data:

  A data frame,
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  or
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
  from
  [`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md).

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding the effect sizes and sampling variances. Default to
  `.yi` and `.vi`.

- exact:

  Use the exact null distribution of Kendall's tau when there are no
  ties? Passed to
  [`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html).

## Value

A one row tibble with Kendall's `tau` (`estimate`), the test `statistic`
and `p.value`.

## References

Begg, C. B. and Mazumdar, M. (1994). Operating characteristics of a rank
correlation test for publication bias. *Biometrics*, 50(4), 1088-1101.
[doi:10.2307/2533446](https://doi.org/10.2307/2533446)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_begg(bcg)
#> # A tibble: 1 × 4
#>   test  estimate statistic p.value
#>   <chr>    <dbl>     <dbl>   <dbl>
#> 1 Begg    0.0256        40   0.952
```
