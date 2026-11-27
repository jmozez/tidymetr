# Multilevel and phylogenetic meta-analysis

`meta_multilevel()` fits a three-level meta-analytic model for effect
sizes nested in clusters (for example several outcomes per study, or
several studies per research group). The marginal variance of the effect
sizes is \$\$V = \mathrm{diag}(v_i) + \sigma^2\_{(3)} Z R Z^\top +
\sigma^2\_{(2)} I,\$\$ where \\Z\\ maps effect sizes to clusters and
\\R\\ is the identity, or a phylogenetic (or any other known)
correlation matrix supplied with `cor_matrix`. The variance components
are estimated by restricted or full maximum likelihood using bounded
quasi-Newton optimisation, and the fixed effects by generalised least
squares.

## Usage

``` r
meta_multilevel(
  .data,
  cluster,
  yi = .yi,
  vi = .vi,
  within = NULL,
  mods = NULL,
  method = "REML",
  test = "z",
  level = 0.95,
  study = NULL,
  cor_matrix = NULL
)
```

## Arguments

- .data:

  A
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
  from
  [`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md)
  or any data frame with effect sizes and sampling variances.

- cluster:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  The upper level grouping (level 3), such as study, district or
  species.

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns holding the effect sizes and sampling variances. Default to
  `.yi` and `.vi`.

- within:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Optional identifier of the level 2 units nested in `cluster`. Defaults
  to one unit per row (per effect size).

- mods:

  An optional one-sided formula of moderators. Defaults to an intercept
  only model.

- method:

  `"REML"` or `"ML"`.

- test:

  `"z"` or `"t"` (t tests with \\k - p\\ degrees of freedom).

- level:

  Confidence level for intervals.

- study:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Optional study labels. Taken from the `<meta_es>` when available.

- cor_matrix:

  An optional correlation matrix among clusters, with row and column
  names matching the values of `cluster`. Supply a phylogenetic
  correlation matrix (for example from `ape::vcv(tree, corr = TRUE)`)
  for a phylogenetic meta-analysis.

## Value

A
[`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
with one row per coefficient. The variance components are returned by
[`glance()`](https://generics.r-lib.org/reference/glance.html).

## Details

The \\I^2\\ statistics follow Nakagawa and Santos (2012): the share of
the total variance due to each random effect, using the typical sampling
variance of Higgins and Thompson (2002).

## References

Konstantopoulos, S. (2011). Fixed effects and variance components
estimation in three-level meta-analysis. *Research Synthesis Methods*,
2(1), 61-76. [doi:10.1002/jrsm.35](https://doi.org/10.1002/jrsm.35)

Nakagawa, S. and Santos, E. S. A. (2012). Methodological issues and
advances in biological meta-analysis. *Evolutionary Ecology*, 26(5),
1253-1274.
[doi:10.1007/s10682-012-9555-5](https://doi.org/10.1007/s10682-012-9555-5)

Hadfield, J. D. and Nakagawa, S. (2010). General quantitative genetic
methods for comparative biology: phylogenies, taxonomies and multi-trait
models for continuous and categorical characters. *Journal of
Evolutionary Biology*, 23(3), 494-508.
[doi:10.1111/j.1420-9101.2009.01915.x](https://doi.org/10.1111/j.1420-9101.2009.01915.x)

## Examples

``` r
fit <- meta_multilevel(school_calendar, yi = yi, vi = vi,
  cluster = district, within = school)
fit
#> # Multilevel meta-analysis <meta_fit>
#> # Model: REML with 2 random effect levels
#> # Measure: generic effect size; k = 56
#> # sigma^2 (district) = 0.0651
#> # sigma^2 (school) = 0.0327
#> # Q(55) = 578.86, p < 0.0001
#> # 95% prediction interval: [-0.4502, 0.8197]
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
#> 1 overall    0.185    0.0846      2.18  0.0289   0.0190     0.350
glance(fit)
#> # A tibble: 1 × 25
#>   model_type  nobs method test   tau2 tau2.low tau2.high   tau    I2    H2    R2
#>   <chr>      <int> <chr>  <chr> <dbl>    <dbl>     <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 multilevel    56 REML   z        NA       NA        NA    NA  95.2    NA    NA
#> # ℹ 14 more variables: QE <dbl>, df.residual <int>, p.QE <dbl>, QM <dbl>,
#> #   p.QM <dbl>, pred.low <dbl>, pred.high <dbl>, logLik <dbl>, AIC <dbl>,
#> #   BIC <dbl>, sigma2_district <dbl>, I2_district <dbl>, sigma2_school <dbl>,
#> #   I2_school <dbl>
```
