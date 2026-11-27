# Plot meta-analytic fits

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
methods that draw the standard displays of a meta-analysis with
`ggplot2`:

## Usage

``` r
# S3 method for class 'meta_fit'
autoplot(object, type = c("forest", "funnel", "baujat", "radial"), ...)
```

## Arguments

- object:

  A
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md).

- type:

  The type of plot.

- ...:

  Not used.

## Value

A `ggplot` object.

## Details

- `"forest"`: study estimates with confidence intervals (squares sized
  by weight) and the pooled estimate as a diamond, with the prediction
  interval as a line through it. Subgroup fits show one diamond per
  subgroup.

- `"funnel"`: effect sizes (or residuals, for models with moderators)
  against standard errors with pseudo confidence limits. Studies imputed
  by
  [`meta_trimfill()`](https://tidymetr.in4metrix.dev/reference/meta_trimfill.md)
  are drawn as open circles.

- `"baujat"`: each study's contribution to the heterogeneity Q statistic
  against its influence on the pooled estimate (Baujat et al., 2002).

- `"radial"`: the Galbraith (radial) plot of standardised effects
  against precision, with the pooled estimate as the slope.

## References

Baujat, B., Mahe, C., Pignon, J.-P. and Hill, C. (2002). A graphical
method for exploring heterogeneity in meta-analyses: application to a
meta-analysis of 65 trials. *Statistics in Medicine*, 21(18), 2641-2652.
[doi:10.1002/sim.1221](https://doi.org/10.1002/sim.1221)

Galbraith, R. F. (1988). A note on graphical presentation of estimated
odds ratios from several clinical trials. *Statistics in Medicine*,
7(8), 889-894.
[doi:10.1002/sim.4780070807](https://doi.org/10.1002/sim.4780070807)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
  study = author
)
fit <- meta_pool(bcg)
autoplot(fit)

autoplot(fit, type = "funnel")

autoplot(meta_trimfill(fit), type = "funnel")

autoplot(fit, type = "baujat")

autoplot(fit, type = "radial")
```
