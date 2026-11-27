# Fitted meta-analysis tibbles

`new_meta_fit()` is the low-level constructor for `<meta_fit>`, the
class returned by
[`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md),
[`meta_regress()`](https://tidymetr.in4metrix.dev/reference/meta_regress.md),
[`meta_subgroup()`](https://tidymetr.in4metrix.dev/reference/meta_subgroup.md),
[`meta_multilevel()`](https://tidymetr.in4metrix.dev/reference/meta_multilevel.md)
and
[`meta_trimfill()`](https://tidymetr.in4metrix.dev/reference/meta_trimfill.md).
It is a tibble subclass whose rows are model coefficients (`term`,
`estimate`, `std.error`, `statistic`, `p.value`, `conf.low`,
`conf.high`). The model internals, including the heterogeneity estimates
and the study level inputs, are kept in the `"fit"` attribute and are
read by [`glance()`](https://generics.r-lib.org/reference/glance.html),
[`augment()`](https://generics.r-lib.org/reference/augment.html),
[predict()](https://tidymetr.in4metrix.dev/reference/predict.meta_fit.md)
and
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).

## Usage

``` r
new_meta_fit(x, fit = list())

is_meta_fit(x)
```

## Arguments

- x:

  A data frame of coefficients.

- fit:

  A named list of model internals.

## Value

`new_meta_fit()` returns a `<meta_fit>`. `is_meta_fit()` returns a
single logical value.

## Examples

``` r
fit <- meta_pool(meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
))
is_meta_fit(fit)
#> [1] TRUE
```
