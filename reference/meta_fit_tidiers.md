# Tidy, glance and augment meta-analytic fits

`broom` style tidiers for
[`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
objects. [`tidy()`](https://generics.r-lib.org/reference/tidy.html)
returns the coefficient table,
[`glance()`](https://generics.r-lib.org/reference/glance.html) a one row
summary of heterogeneity and fit statistics, and
[`augment()`](https://generics.r-lib.org/reference/augment.html) the
study level data with fitted values, residuals and diagnostics.

## Usage

``` r
# S3 method for class 'meta_fit'
tidy(x, exponentiate = FALSE, ...)

# S3 method for class 'meta_fit'
glance(x, ...)

# S3 method for class 'meta_fit'
augment(x, data = NULL, ...)
```

## Arguments

- x:

  A `<meta_fit>`.

- exponentiate:

  Exponentiate the estimates and confidence limits? Useful for log risk,
  odds and rate ratios.

- ...:

  Not used.

- data:

  Optional data to augment. Defaults to the data used in the fit (with
  the filled studies for
  [`meta_trimfill()`](https://tidymetr.in4metrix.dev/reference/meta_trimfill.md)).

## Value

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
[`augment()`](https://generics.r-lib.org/reference/augment.html) return
tibbles. [`glance()`](https://generics.r-lib.org/reference/glance.html)
returns a one row tibble with `nobs`, `method`, `test`, `tau2`, its
Q-profile confidence limits (`tau2.low`, `tau2.high`), `tau`, `I2`,
`H2`, `R2`, `QE`, `df.residual`, `p.QE`, `QM`, `p.QM`, the prediction
interval (`pred.low`, `pred.high`), `logLik`, `AIC` and `BIC`, plus
model specific columns (subgroup tests, variance components or the
number of filled studies).
[`augment()`](https://generics.r-lib.org/reference/augment.html) adds
`.study`, `.yi`, `.vi`, `.fitted`, `.resid`, `.std_resid`, `.hat`,
`.weight` (in percent) and `.blup` (the empirical Bayes estimate of each
study's true effect).

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
fit <- meta_pool(bcg)
tidy(fit, exponentiate = TRUE)
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic   p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
#> 1 overall    0.489     0.180     -3.97 0.0000705    0.344     0.696
glance(fit)
#> # A tibble: 1 × 21
#>   model_type  nobs method test   tau2 tau2.low tau2.high   tau    I2    H2    R2
#>   <chr>      <int> <chr>  <chr> <dbl>    <dbl>     <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 pool          13 REML   z     0.313    0.120      1.11 0.560  92.2  12.9    NA
#> # ℹ 10 more variables: QE <dbl>, df.residual <int>, p.QE <dbl>, QM <dbl>,
#> #   p.QM <dbl>, pred.low <dbl>, pred.high <dbl>, logLik <dbl>, AIC <dbl>,
#> #   BIC <dbl>
augment(fit)
#> # A tibble: 13 × 19
#>    trial author  year  tpos  tneg  cpos  cneg ablat alloc     .yi     .vi   .sei
#>    <int> <chr>  <int> <int> <int> <int> <int> <int> <chr>   <dbl>   <dbl>  <dbl>
#>  1     1 Arons…  1948     4   119    11   128    44 rand… -0.889  0.326   0.571 
#>  2     2 Fergu…  1949     6   300    29   274    55 rand… -1.59   0.195   0.441 
#>  3     3 Rosen…  1960     3   228    11   209    42 rand… -1.35   0.415   0.644 
#>  4     4 Hart …  1977    62 13536   248 12619    52 rand… -1.44   0.0200  0.141 
#>  5     5 Frimo…  1973    33  5036    47  5761    13 alte… -0.218  0.0512  0.226 
#>  6     6 Stein…  1953   180  1361   372  1079    44 alte… -0.786  0.00691 0.0831
#>  7     7 Vandi…  1973     8  2537    10   619    19 rand… -1.62   0.223   0.472 
#>  8     8 TPT M…  1980   505 87886   499 87892    13 rand…  0.0120 0.00396 0.0629
#>  9     9 Coetz…  1968    29  7470    45  7232    27 rand… -0.469  0.0564  0.238 
#> 10    10 Rosen…  1961    17  1699    65  1600    42 syst… -1.37   0.0730  0.270 
#> 11    11 Comst…  1974   186 50448   141 27197    18 syst… -0.339  0.0124  0.111 
#> 12    12 Comst…  1969     5  2493     3  2338    33 syst…  0.446  0.533   0.730 
#> 13    13 Comst…  1976    27 16886    29 17825    33 syst… -0.0173 0.0714  0.267 
#> # ℹ 7 more variables: .study <chr>, .fitted <dbl>, .resid <dbl>,
#> #   .std_resid <dbl>, .hat <dbl>, .weight <dbl>, .blup <dbl>
```
