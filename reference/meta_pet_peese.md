# PET-PEESE bias adjusted estimates

`meta_pet_peese()` fits the precision-effect test (PET, a weighted
regression of effect sizes on standard errors) and the precision-effect
estimate with standard error (PEESE, a regression on sampling variances)
of Stanley and Doucouliagos (2014). Following their conditional
procedure, the PEESE intercept is preferred when the PET intercept
differs from zero at level `alpha`, and the PET intercept otherwise.

## Usage

``` r
meta_pet_peese(.data, yi = .yi, vi = .vi, alpha = 0.05, level = 0.95)
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

- alpha:

  Significance level of the PET test that selects between the PET and
  PEESE estimates (two-sided).

- level:

  Confidence level for intervals.

## Value

A two row tibble (PET and PEESE) with the intercept (the bias adjusted
effect), its standard error, test statistic, degrees of freedom, p-value
and confidence interval, the slope, and a logical `selected` column
marking the conditional estimate.

## References

Stanley, T. D. and Doucouliagos, H. (2014). Meta-regression
approximations to reduce publication selection bias. *Research Synthesis
Methods*, 5(1), 60-78.
[doi:10.1002/jrsm.1095](https://doi.org/10.1002/jrsm.1095)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
meta_pet_peese(bcg)
#> # A tibble: 2 × 10
#>   model estimate std.error statistic    df p.value conf.low conf.high slope
#>   <chr>    <dbl>     <dbl>     <dbl> <int>   <dbl>    <dbl>     <dbl> <dbl>
#> 1 PET     -0.191     0.220    -0.868    11  0.404    -0.675    0.293  -2.11
#> 2 PEESE   -0.380     0.157    -2.42     11  0.0342   -0.726   -0.0338 -2.36
#> # ℹ 1 more variable: selected <lgl>
```
