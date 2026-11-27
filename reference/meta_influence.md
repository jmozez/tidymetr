# Outlier and influence diagnostics

`meta_influence()` computes the case deletion diagnostics of Viechtbauer
and Cheung (2010) for each study: externally studentised residuals,
DFFITS, Cook's distance, covariance ratios, the leave-one-out \\\tau^2\\
and Q, hat values, weights and DFBETAS. A study is flagged as
influential when \\\|DFFITS\| \> 3\sqrt{p/(k-p)}\\, Cook's distance
exceeds the median of a \\\chi^2_p\\ distribution, the hat value exceeds
\\3p/k\\, or any \\\|DFBETAS\| \> 1\\.

## Usage

``` r
meta_influence(.data)
```

## Arguments

- .data:

  A
  [`<meta_fit>`](https://tidymetr.in4metrix.dev/reference/new_meta_fit.md)
  from
  [`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md)
  or
  [`meta_regress()`](https://tidymetr.in4metrix.dev/reference/meta_regress.md).

## Value

A tibble with one row per study and the columns `study`, `rstudent`,
`dffits`, `cooks_distance`, `cov_ratio`, `tau2_del`, `QE_del`, `hat`,
`weight`, `dfbetas_<term>` and `influential`.

## References

Viechtbauer, W. and Cheung, M. W.-L. (2010). Outlier and influence
diagnostics for meta-analysis. *Research Synthesis Methods*, 1(2),
112-125. [doi:10.1002/jrsm.11](https://doi.org/10.1002/jrsm.11)

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
  study = author
)
meta_pool(bcg) |> meta_influence()
#> # A tibble: 13 × 11
#>    study rstudent  dffits cooks_distance cov_ratio tau2_del QE_del    hat weight
#>    <chr>    <dbl>   <dbl>          <dbl>     <dbl>    <dbl>  <dbl>  <dbl>  <dbl>
#>  1 Aron…   -0.218 -0.0407       0.00172      1.12     0.336  152.  0.0506   5.06
#>  2 Ferg…   -1.29  -0.344        0.113        1.01     0.293  145.  0.0636   6.36
#>  3 Rose…   -0.755 -0.160        0.0260       1.07     0.321  150.  0.0444   4.44
#>  4 Hart…   -1.45  -0.520        0.229        0.965    0.263   96.6 0.0970   9.70
#>  5 Frim…    0.848  0.271        0.0762       1.14     0.328  151.  0.0887   8.87
#>  6 Stei…   -0.118 -0.0190       0.000413     1.24     0.360  128.  0.101   10.1 
#>  7 Vand…   -1.30  -0.336        0.109        1.01     0.293  146.  0.0603   6.03
#>  8 TPT …    1.45   0.477        0.199        1.00     0.273   68.0 0.102   10.2 
#>  9 Coet…    0.408  0.142        0.0220       1.20     0.349  152.  0.0874   8.74
#> 10 Rose…   -1.13  -0.349        0.117        1.05     0.299  140.  0.0837   8.37
#> 11 Coms…    0.669  0.232        0.0581       1.19     0.340  151.  0.0993   9.93
#> 12 Coms…    1.29   0.253        0.0634       1.03     0.308  151.  0.0382   3.82
#> 13 Coms…    1.19   0.355        0.123        1.07     0.304  150.  0.0840   8.40
#> # ℹ 2 more variables: dfbetas_intercept <dbl>, influential <lgl>
```
