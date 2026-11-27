# Fail-safe N

`meta_failsafe()` computes the number of unpublished null studies needed
to overturn a conclusion. `type = "rosenthal"` uses Stouffer's method
(Rosenthal, 1979) with a one-sided level `alpha`; `"orwin"` finds the
number of studies with effect zero that would shrink the inverse
variance weighted mean to `target` (Orwin, 1983); `"rosenberg"` finds
the number that would make the common-effect estimate non-significant at
two-sided level `alpha` (Rosenberg, 2005).

## Usage

``` r
meta_failsafe(
  .data,
  yi = .yi,
  vi = .vi,
  type = c("rosenthal", "orwin", "rosenberg"),
  alpha = 0.05,
  target = NULL
)
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

- type:

  `"rosenthal"`, `"orwin"` or `"rosenberg"`.

- alpha:

  Significance level.

- target:

  Target effect for `type = "orwin"`. Defaults to half the observed
  mean.

## Value

A one row tibble with the method, the fail-safe number (`fail_safe_n`),
the observed `estimate` (for Orwin and Rosenberg), `target`, `alpha` and
the `p.value` of the observed evidence.

## References

Rosenthal, R. (1979). The file drawer problem and tolerance for null
results. *Psychological Bulletin*, 86(3), 638-641.
[doi:10.1037/0033-2909.86.3.638](https://doi.org/10.1037/0033-2909.86.3.638)

Orwin, R. G. (1983). A fail-safe N for effect size in meta-analysis.
*Journal of Educational Statistics*, 8(2), 157-159.
[doi:10.3102/10769986008002157](https://doi.org/10.3102/10769986008002157)

Rosenberg, M. S. (2005). The file-drawer problem revisited: a general
weighted method for calculating fail-safe numbers in meta-analysis.
*Evolution*, 59(2), 464-468.
[doi:10.1111/j.0014-3820.2005.tb01004.x](https://doi.org/10.1111/j.0014-3820.2005.tb01004.x)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_failsafe(bcg)
#> # A tibble: 1 × 6
#>   type      fail_safe_n estimate target alpha  p.value
#>   <chr>           <dbl>    <dbl>  <dbl> <dbl>    <dbl>
#> 1 rosenthal         598       NA     NA  0.05 8.81e-30
meta_failsafe(bcg, type = "orwin", target = log(0.9))
#> # A tibble: 1 × 6
#>   type  fail_safe_n estimate target alpha p.value
#>   <chr>       <dbl>    <dbl>  <dbl> <dbl>   <dbl>
#> 1 orwin          41   -0.430 -0.105  0.05      NA
```
