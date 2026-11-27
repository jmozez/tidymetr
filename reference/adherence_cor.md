# Conscientiousness and medication adherence

Correlations between conscientiousness (a personality trait) and
adherence to medication in 16 studies.

## Usage

``` r
adherence_cor
```

## Format

A tibble with 16 rows and 10 columns:

- authors:

  Study authors.

- year:

  Publication year.

- ni:

  Sample size.

- ri:

  Observed correlation.

- controls:

  Number of variables controlled for (`"none"` or `"multiple"`).

- design:

  `"cross-sectional"` or `"prospective"`.

- a_measure:

  Adherence measure: `"self-report"` or `"other"`.

- c_measure:

  Conscientiousness measure: `"NEO"` or `"other"`.

- meanage:

  Mean age of the participants (years).

- quality:

  Methodological quality score (1 to 4).

## Source

Molloy, G. J., O'Carroll, R. E. and Ferguson, E. (2014).
Conscientiousness and medication adherence: a meta-analysis. *Annals of
Behavioral Medicine*, 47(1), 92-101.
[doi:10.1007/s12160-013-9524-4](https://doi.org/10.1007/s12160-013-9524-4)

Values cross-checked against `dat.molloy2014` in the 'metadat' package.

## Examples

``` r
meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni) |> meta_pool()
#> # Meta-analysis <meta_fit>
#> # Model: random effects, restricted maximum likelihood
#> # Measure: Fisher's z transformed correlation; k = 16
#> # tau^2 = 0.0081; I^2 = 61.73%; H^2 = 2.61
#> # Q(15) = 38.16, p = 0.0009
#> # 95% prediction interval: [-0.0371, 0.3369]
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic    p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>      <dbl>    <dbl>     <dbl>
#> 1 overall    0.150    0.0316      4.75 0.00000203   0.0881     0.212
```
