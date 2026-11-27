# Plot network meta-analyses

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
method for
[`<meta_nma>`](https://tidymetr.in4metrix.dev/reference/new_meta_nma.md)
objects. `type = "netgraph"` draws the network with treatments on a
circle and edge widths proportional to the number of studies making each
direct comparison. `type = "forest"` shows every treatment against the
reference, ordered by P-score.

## Usage

``` r
# S3 method for class 'meta_nma'
autoplot(object, type = c("netgraph", "forest"), ...)
```

## Arguments

- object:

  A `<meta_nma>`.

- type:

  `"netgraph"` or `"forest"`.

- ...:

  Not used.

## Value

A `ggplot` object.

## Examples

``` r
pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
  measure = "OR", event = xi, n = ni)
nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
  reference = "no_contact", small_values = "bad")
autoplot(nma)

autoplot(nma, type = "forest")
```
